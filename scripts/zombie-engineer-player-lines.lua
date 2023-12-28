local LoggingUtils = require("utility.helper-utils.logging-utils")
local LineToBodySettingsValues = require("common.line-to-body-settings-values")
local PlayerLines = require("utility.manager-libraries.player-lines")

local ZombieEngineerPlayerLines = {} ---@class Class_ZombieEngineerPlayerLines

ZombieEngineerPlayerLines.CreateGlobals = function()
    global.ZombieEngineerPlayerLines = global.ZombieEngineerPlayerLines or {} ---@class Global_ZombieEngineerPlayerLines
end

ZombieEngineerPlayerLines.OnLoad = function()
    MOD.Interfaces.ZombieEngineerPlayerLines = MOD.Interfaces.ZombieEngineerPlayerLines or {} ---@class InternalInterfaces_ZombieEngineerPlayerLines
    MOD.Interfaces.ZombieEngineerPlayerLines.RecordPlayerEntityLine = ZombieEngineerPlayerLines.RecordPlayerEntityLine
    MOD.Interfaces.ZombieEngineerPlayerLines.ReloadPlayerEntityLines = ZombieEngineerPlayerLines.ReloadPlayerEntityLines
end

ZombieEngineerPlayerLines.OnStartup = function()
end

---@param event EventData.on_runtime_mod_setting_changed|nil # nil value when called from OnStartup (on_init & on_configuration_changed)
ZombieEngineerPlayerLines.OnSettingChanged = function(event)
    -- Per player mod settings for `line to body` changed only.
    if event ~= nil and event.setting_type == "runtime-per-user" and (event.setting == "zombie_engineer-line_to_body_thickness" or event.setting == "zombie_engineer-line_to_body_color_selection_type" or event.setting == "zombie_engineer-line_to_body_color_selector_value") then
        ZombieEngineerPlayerLines.ReloadPlayerEntityLines(event.player_index)
    end
end

---@param targetEntity LuaEntity
---@param player LuaPlayer
---@param lineIdName string
ZombieEngineerPlayerLines.RecordPlayerEntityLine = function(targetEntity, player, lineIdName)
    local RealCode = function(targetEntity, player, lineIdName)
        local playerLineSettings = ZombieEngineerPlayerLines.GetPlayersLineModSettings(player, player.index)
        PlayerLines.AddLineForPlayer(lineIdName, player.surface, player, targetEntity, playerLineSettings.lineColor, playerLineSettings.lineWidth)
    end

    -- FUTURE: run it all in a safety bubble.
    local errorMessage, fullErrorDetails = LoggingUtils.RunFunctionAndCatchErrors(RealCode, targetEntity, player, lineIdName)
    if errorMessage ~= nil then
        LoggingUtils.LogPrintError(errorMessage, true)
    end
    if fullErrorDetails ~= nil then
        LoggingUtils.ModLog(fullErrorDetails, false)
    end
end

---@param playerIndex uint
ZombieEngineerPlayerLines.ReloadPlayerEntityLines = function(playerIndex)
    local RealCode = function(playerIndex)
        local player = game.get_player(playerIndex) ---@cast player -nil
        local currentPlayerLines = PlayerLines.GetLinesForPlayerIndex(playerIndex)
        if currentPlayerLines == nil then return end

        for _, currentPlayerLine in pairs(currentPlayerLines) do
            local playerLineSettings = ZombieEngineerPlayerLines.GetPlayersLineModSettings(player, player.index)
            currentPlayerLine.color = playerLineSettings.lineColor
            currentPlayerLine.width = playerLineSettings.lineWidth
            PlayerLines.RefreshPlayerLine(currentPlayerLine.id)
        end
    end

    -- FUTURE: run it all in a safety bubble.
    local errorMessage, fullErrorDetails = LoggingUtils.RunFunctionAndCatchErrors(RealCode, playerIndex)
    if errorMessage ~= nil then
        LoggingUtils.LogPrintError(errorMessage, true)
    end
    if fullErrorDetails ~= nil then
        LoggingUtils.ModLog(fullErrorDetails, false)
    end
end

---@class ZombieEngineer_GetPlayersLineModSettings_Return
---@field lineWidth float
---@field lineColor Color

---@param player LuaPlayer
---@param playerIndex uint
---@return ZombieEngineer_GetPlayersLineModSettings_Return
ZombieEngineerPlayerLines.GetPlayersLineModSettings = function(player, playerIndex)
    local playerSettings = settings.get_player_settings(playerIndex)

    local lineColor ---@type Color
    if playerSettings["zombie_engineer-line_to_body_color_selection_type"].value --[[@as LineToBodySettingsValues_LineColorSelectionType]] == LineToBodySettingsValues.ZOMBIE_ENGINEER_LINE_COLOR_SELECTION_TYPE.player then
        lineColor = player.color
    else
        lineColor = playerSettings["zombie_engineer-line_to_body_color_selector_value"].value --[[@as Color]]
    end

    local lineWidth = playerSettings["zombie_engineer-line_to_body_thickness"].value --[[@as float]]

    ---@type ZombieEngineer_GetPlayersLineModSettings_Return
    local playerLineModSettings = {
        lineWidth = lineWidth,
        lineColor = lineColor
    }
    return playerLineModSettings
end

return ZombieEngineerPlayerLines
