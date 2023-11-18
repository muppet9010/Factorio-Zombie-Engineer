--[[
    Library to support drawing lines from a player to targets.
    This handles the player dying, as when they respawn the line will need drawing again. The player getting in and out of vehicles is handled by Factorio automatically.
    This library is used by calling the RegisterPlayerLines() function once in root of control.lua. With the public functions then being called as required to add and remove lines. Lines to target entities that become invalid (die) will be automatically removed. Lines will only be drawn if the source and target are on the same surface; they will be tracked while the player is on a different surface and XXX when the player returns to that surface.
    If a player loses/gains a character without dying & re-spawning the lines won't be recreated. The module does handle surfaces correctly for the player, i.e. a player and target on different surfaces won't draw a line, but won't error or remove the line object either. The module does handle players entering and exiting Editor Mode. If both the source and target are teleported to another surface then the line details will update to this new situation.
--]]
--

local Events = require("utility.manager-libraries.events")
local LoggingUtils = require("utility.helper-utils.logging-utils")

local PlayerLines = {} ---@class Utility_PlayerLines

---@class UtilityPlayerLines_PlayerLine # The details of a players line.
---@field id UtilityPlayerLines_LineId # Id of the line object.
---@field lineRenderId int64?
---@field surface LuaSurface
---@field playerSource LuaPlayer
---@field playerIndex uint
---@field target LuaEntity|MapPosition
---@field color Color
---@field width float

---@alias UtilityPlayerLines_LineId uint|string

--------------------------------------------------------------------------------------------
--                                    Setup Functions
--------------------------------------------------------------------------------------------

--- Called from the root of Control.lua
---
--- Only needs to be called once by the mod.
PlayerLines.RegisterPlayerAlerts = function()
    Events.RegisterHandlerEvent(defines.events.on_player_respawned, "PlayerLines._OnPlayerRespawned", PlayerLines._OnPlayerRespawned)
    Events.RegisterHandlerEvent(defines.events.on_player_changed_surface, "PlayerLines._OnPlayerChangedSurface", PlayerLines._OnPlayerChangedSurface)
    Events.RegisterHandlerEvent(defines.events.on_player_toggled_map_editor, "PlayerLines._OnPlayerToggledMapEditor", PlayerLines._OnPlayerToggledMapEditor)
end

--------------------------------------------------------------------------------------------
--                                    Public Functions
--------------------------------------------------------------------------------------------

--- Called to add a line for a player.
---@param lineId? UtilityPlayerLines_LineId # Will auto generate if not provided.
---@param surface LuaSurface
---@param playerSource LuaPlayer
---@param target LuaEntity|MapPosition
---@param color Color
---@param width float
---@return UtilityPlayerLines_LineId lineId
PlayerLines.AddLineForPlayer = function(lineId, surface, playerSource, target, color, width)
    PlayerLines._CreateGlobals()
    if lineId == nil then
        global.UTILITYPLAYERLINES.autoLineIdNumberCurrent = global.UTILITYPLAYERLINES.autoLineIdNumberCurrent + 1
        lineId = "Utility_PlayerLines_Auto-" .. global.UTILITYPLAYERLINES.autoLineIdNumberCurrent
    end

    local player_index = playerSource.index
    local sourceEntity = playerSource.character

    local lineRenderId; ---@type uint64?
    if sourceEntity ~= nil then
        lineRenderId = PlayerLines._DrawLine(color, sourceEntity, surface, target, width, { playerSource })
    end

    ---@type UtilityPlayerLines_PlayerLine
    local playerLine = {
        id = lineId,
        lineRenderId = lineRenderId,
        surface = surface,
        playerSource = playerSource,
        playerIndex = player_index,
        target = target,
        color = color,
        width = width
    }

    local playerLines = global.UTILITYPLAYERLINES.playersLines[player_index]
    if playerLines == nil then
        playerLines = {}
        global.UTILITYPLAYERLINES.playersLines[player_index] = playerLines
    end
    playerLines[lineId] = playerLine

    global.UTILITYPLAYERLINES.lineIds[lineId] = playerLine

    return lineId
end

--- Remove a line with the supplied lineId if it exists.
---@param lineId UtilityPlayerLines_LineId
PlayerLines.RemoveLine = function(lineId)
    if global.UTILITYPLAYERLINES == nil then return end
    local playerLine = global.UTILITYPLAYERLINES.lineIds[lineId]
    if playerLine == nil then return end

    if playerLine.lineRenderId ~= nil and rendering.is_valid(playerLine.lineRenderId) then
        rendering.destroy(playerLine.lineRenderId)
    end
    global.UTILITYPLAYERLINES.lineIds[lineId] = nil
    global.UTILITYPLAYERLINES.playersLines[playerLine.playerIndex][lineId] = nil
end

--- Get all of the line objects for a specific player index.
---@param playerIndex uint
---@return table<UtilityPlayerLines_LineId, UtilityPlayerLines_PlayerLine>? PlayerLines # Dictionary of the player'safe lineId to line objects.
PlayerLines.GetLinesForPlayerIndex = function(playerIndex)
    if global.UTILITYPLAYERLINES == nil then return end
    return global.UTILITYPLAYERLINES.playersLines[playerIndex]
end

--- Redraws the rendered line for the given lineId object with the current details. For calling after updating some of the line object'support values without having to remove the old line object and creating a new one.
---@param lineId UtilityPlayerLines_LineId
PlayerLines.RefreshPlayerLine = function(lineId)
    if global.UTILITYPLAYERLINES == nil then return end
    local playerLine = global.UTILITYPLAYERLINES.lineIds[lineId]
    if playerLine == nil then return end
    local sourceEntity = playerLine.playerSource.character
    if sourceEntity == nil then return end

    PlayerLines._RedrawPlayerLine(playerLine, sourceEntity)
end

--------------------------------------------------------------------------------------------
--                                    Internal Functions
--------------------------------------------------------------------------------------------

PlayerLines._CreateGlobals = function()
    if global.UTILITYPLAYERLINES == nil then
        global.UTILITYPLAYERLINES = {} ---@class Global_PlayerLines
    end
    if global.UTILITYPLAYERLINES.playersLines == nil then
        global.UTILITYPLAYERLINES.playersLines = {} ---@type table<uint, table<UtilityPlayerLines_LineId, UtilityPlayerLines_PlayerLine>> # Player Index to a dictionary of their lineId to line object.
    end
    if global.UTILITYPLAYERLINES.lineIds == nil then
        global.UTILITYPLAYERLINES.lineIds = {} ---@type table<UtilityPlayerLines_LineId, UtilityPlayerLines_PlayerLine> # Line Id to the line object.
    end
    if global.UTILITYPLAYERLINES.autoLineIdNumberCurrent == nil then
        global.UTILITYPLAYERLINES.autoLineIdNumberCurrent = 0 ---@type uint
    end
end

---@param eventData EventData.on_player_respawned
PlayerLines._OnPlayerRespawned = function(eventData)
    local RealCode = function(eventData)
        if global.UTILITYPLAYERLINES == nil then return end
        PlayerLines._RedrawPlayerLines(eventData.player_index)
    end

    -- FUTURE: run it all in a safety bubble.
    local errorMessage, fullErrorDetails = LoggingUtils.RunFunctionAndCatchErrors(RealCode, eventData)
    if errorMessage ~= nil then
        LoggingUtils.LogPrintError(errorMessage, true)
    end
    if fullErrorDetails ~= nil then
        LoggingUtils.ModLog(fullErrorDetails, false)
    end
end

---@param color Color
---@param sourceEntity LuaEntity
---@param surface LuaSurface
---@param target LuaEntity|MapPosition
---@param width float
---@param visibleToPlayers LuaPlayer[]
---@return uint64? lineRenderId
PlayerLines._DrawLine = function(color, sourceEntity, surface, target, width, visibleToPlayers)
    if width == 0 then return nil end

    local sourceEntity_surface = sourceEntity.surface
    local targetIsEntity ---@type boolean?
    local targetEntity_surface ---@type LuaSurface?

    if sourceEntity_surface ~= surface then
        -- Player's current surface isn't the one the line was created on.

        -- Check for a weird valid edge case where the source and target (entity) have both been moved to a new surface.
        targetIsEntity = (target["object_name"] ~= nil)
        if targetIsEntity then targetEntity_surface = target.surface end
        if not (targetIsEntity and sourceEntity_surface == targetEntity_surface) then
            -- Just ignore drawing it for now as both the player and target entity haven't moved to a new surface.
            -- No way to validate if a target map position is relevant on the new surface or not, so assume not.
            return nil
        end
    end

    -- Checks to handle surface mismatch with nice error message, rather than hard crash.
    if targetIsEntity == nil then targetIsEntity = (target["object_name"] ~= nil) end
    if targetIsEntity and targetEntity_surface == nil then targetEntity_surface = target.surface end
    if targetIsEntity and targetEntity_surface ~= surface then
        -- Is a target entity and not map position.
        ---@cast target LuaEntity
        -- Don't log this mismatch as we now handle intentional surface changes for player and target.
        --LoggingUtils.PrintError("Utility Player-Lines: tried to add a line on a surface different to the target entity. Surface Name: `" .. surface.name .. "`. Target Entity: " .. LoggingUtils.MakeGpsRichText_Entity(target))
        --LoggingUtils.PrintError("Utility Player-Lines: drawing line aborted between " .. LoggingUtils.MakeGpsRichText_Entity(sourceEntity) " and " .. LoggingUtils.MakeGpsRichText_Entity(target))
        return nil
    end ---@cast target LuaEntity|MapPosition

    return rendering.draw_line({
        color = color,
        from = sourceEntity,
        surface = surface,
        to = target,
        width = width,
        players = visibleToPlayers
    })
end

--- Draw all of the lines for a given player.
--- If the target is invalid then remove the line object as it's old now. This is a lazy tidy-up.
---@param playerIndex uint
PlayerLines._RedrawPlayerLines = function(playerIndex)
    local player = game.get_player(playerIndex) ---@cast player -nil
    local sourceEntity = player.character
    if sourceEntity == nil then return end

    local playerLines = global.UTILITYPLAYERLINES.playersLines[playerIndex]
    if playerLines == nil then return end
    for _, playerLine in pairs(playerLines) do
        PlayerLines._RedrawPlayerLine(playerLine, sourceEntity)
    end
end

--- Draw the specific line.
--- If the target is invalid then remove the line object as it's old now. This is a lazy tidy-up.
---@param playerLine UtilityPlayerLines_PlayerLine
---@param sourceEntity LuaEntity
PlayerLines._RedrawPlayerLine = function(playerLine, sourceEntity)
    if playerLine.target == nil or (not playerLine.target.valid) then
        -- The target has entirely gone, so remove the line object entirely.
        PlayerLines.RemoveLine(playerLine.id)
    else
        if playerLine.lineRenderId ~= nil and rendering.is_valid(playerLine.lineRenderId) then
            rendering.destroy(playerLine.lineRenderId)
        end
        playerLine.lineRenderId = PlayerLines._DrawLine(playerLine.color, sourceEntity, playerLine.surface, playerLine.target, playerLine.width, { playerLine.playerSource })
    end
end

---@param eventData EventData.on_player_changed_surface
PlayerLines._OnPlayerChangedSurface = function(eventData)
    local RealCode = function(eventData)
        if global.UTILITYPLAYERLINES == nil then return end
        PlayerLines._RedrawPlayerLines(eventData.player_index)
    end

    -- FUTURE: run it all in a safety bubble.
    local errorMessage, fullErrorDetails = LoggingUtils.RunFunctionAndCatchErrors(RealCode, eventData)
    if errorMessage ~= nil then
        LoggingUtils.LogPrintError(errorMessage, true)
    end
    if fullErrorDetails ~= nil then
        LoggingUtils.ModLog(fullErrorDetails, false)
    end
end

---@param eventData EventData.on_player_toggled_map_editor
PlayerLines._OnPlayerToggledMapEditor = function(eventData)
    local RealCode = function(eventData)
        if global.UTILITYPLAYERLINES == nil then return end
        PlayerLines._RedrawPlayerLines(eventData.player_index)
    end

    -- FUTURE: run it all in a safety bubble.
    local errorMessage, fullErrorDetails = LoggingUtils.RunFunctionAndCatchErrors(RealCode, eventData)
    if errorMessage ~= nil then
        LoggingUtils.LogPrintError(errorMessage, true)
    end
    if fullErrorDetails ~= nil then
        LoggingUtils.ModLog(fullErrorDetails, false)
    end
end

return PlayerLines
