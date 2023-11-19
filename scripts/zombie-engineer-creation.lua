local Events = require("utility.manager-libraries.events")
local LoggingUtils = require("utility.helper-utils.logging-utils")
local InventoryUtils = require("utility.helper-utils.inventory-utils")
local StringUtils = require("utility.helper-utils.string-utils")

---@class ZombieEngineer_TestingSettings
local TestingSettings = {
    giveZombieDefaultItems = false
}

local ZombieEngineerCreation = {} ---@class Class_ZombieEngineerCreation

ZombieEngineerCreation.CreateGlobals = function()
    global.ZombieEngineerCreation = global.ZombieEngineerCreation or {} ---@class Global_ZombieEngineerCreation

    global.ZombieEngineerCreation.playerDeathCounts = global.ZombieEngineerCreation.playerDeathCounts or {} ---@type table<uint, uint> # Player Index to death count.

    global.ZombieEngineerCreation.Settings = {
        zombieNames = {}, ---@type string[] # Populated as part of OnStartup or when the relevant mod setting changes.
    }
end

ZombieEngineerCreation.OnLoad = function()
    Events.RegisterHandlerEvent(defines.events.on_player_died, "ZombieEngineerCreation.OnPlayerDied", ZombieEngineerCreation.OnPlayerDied)
    Events.RegisterHandlerEvent(defines.events.on_entity_died, "ZombieEngineerCreation.OnEntityDiedGravestone", ZombieEngineerCreation.OnEntityDiedGravestone, { { filter = "name", name = "zombie_engineer-grave_with_headstone" } })
end

ZombieEngineerCreation.OnStartup = function()
end

---@param event EventData.on_runtime_mod_setting_changed|nil # nil value when called from OnStartup (on_init & on_configuration_changed)
ZombieEngineerCreation.OnSettingChanged = function(event)
    -- Global zombie names setting updated or map load.
    if event == nil or (event.setting_type == "runtime-global" and event.setting == "zombie_engineer-zombie_names") then
        local rawSettingString = settings.global["zombie_engineer-zombie_names"].value --[[@as string]]
        rawSettingString = StringUtils.StringTrim(rawSettingString)
        if rawSettingString == "" then
            global.ZombieEngineerCreation.Settings.zombieNames = {}
        else
            global.ZombieEngineerCreation.Settings.zombieNames = StringUtils.SplitStringOnCharactersToList(rawSettingString, ",")
        end
    end
end

---@param eventData EventData.on_player_died
ZombieEngineerCreation.OnPlayerDied = function(eventData)
    local player = game.get_player(eventData.player_index)
    if player == nil then
        LoggingUtils.PrintError("On_Player_Died event occurred for non-player player_index: " .. eventData.player_index)
        return
    end
    local player_name = player.name
    local player_surface = player.surface
    local player_position = player.position
    local player_color = player.color

    if eventData.cause ~= nil then
        local killerZombie = global.ZombieEngineerManager.zombieEngineerUnitNumberLookup[eventData.cause.unit_number] ---@type ZombieEngineer?
        if killerZombie ~= nil and killerZombie.sourcePlayer ~= nil then
            game.print({ "message.zombie_engineer-player_died_to", player_name, killerZombie.sourceName })
        end
    end

    global.ZombieEngineerCreation.playerDeathCounts[eventData.player_index] = (global.ZombieEngineerCreation.playerDeathCounts[eventData.player_index] ~= nil and global.ZombieEngineerCreation.playerDeathCounts[eventData.player_index] or 0) + 1

    local zombieName = player_name .. " (" .. global.ZombieEngineerCreation.playerDeathCounts[eventData.player_index] .. ")"

    -- Players position has been returned to their corpse by the point this event fires (if they were in map view at time of death).
    ZombieEngineerCreation.CreateZombie(player, eventData.player_index, player_name, player_color, zombieName, player_color, player_surface, player_position, player_position)
end

---@param eventData EventData.on_entity_died
ZombieEngineerCreation.OnEntityDiedGravestone = function(eventData)
    local diedEntity = eventData.entity
    if diedEntity.name ~= "zombie_engineer-grave_with_headstone" then return end
    ZombieEngineerCreation.CreateZombie(nil, nil, "gravestone", nil, nil, nil, diedEntity.surface, nil, diedEntity.position)
end

---@param player? LuaPlayer
---@param player_index? uint
---@param sourceName string
---@param entityColor? Color
---@param zombieName? string
---@param textColor? Color
---@param surface LuaSurface
---@param corpsePosition? MapPosition
---@param zombieTargetPosition MapPosition
---@return ZombieEngineer?
ZombieEngineerCreation.CreateZombie = function(player, player_index, sourceName, entityColor, zombieName, textColor, surface, corpsePosition, zombieTargetPosition)
    local currentTick = game.tick

    local zombieEngineer = {} ---@class ZombieEngineer
    zombieEngineer.sourcePlayer = player
    zombieEngineer.sourceName = sourceName
    zombieEngineer.surface = surface
    zombieEngineer.state = MOD.Interfaces.ZombieEngineerManager.Enums.ZOMBIE_ENGINEER_STATE.alive
    zombieEngineer.objective = MOD.Interfaces.ZombieEngineerManager.Enums.ZOMBIE_ENGINEER_OBJECTIVE.movingToSpawn
    zombieEngineer.action = MOD.Interfaces.ZombieEngineerManager.Enums.ZOMBIE_ENGINEER_ACTION.idle
    zombieEngineer.entityColor = entityColor or global.ZombieEngineerManager.Settings.zombieEntityColor
    zombieEngineer.textColor = textColor or global.ZombieEngineerManager.Settings.zombieTextColor

    -- If there's a corpse position then look for this player's current corpse there, then take the items from it.
    if player ~= nil and corpsePosition ~= nil then
        local playersCorpse ---@type LuaEntity?
        local characterCorpsesNearBy = surface.find_entities_filtered({ position = corpsePosition, radius = 5, type = "character-corpse" })
        for _, corpse in pairs(characterCorpsesNearBy) do
            if corpse.character_corpse_tick_of_death == currentTick and corpse.character_corpse_player_index == player_index then
                playersCorpse = corpse
                local targetInventory = playersCorpse.get_inventory(defines.inventory.character_corpse)
                if targetInventory ~= nil then
                    zombieEngineer.inventory = InventoryUtils.TransferInventoryContentsToScriptInventory(targetInventory, nil)
                else
                    LoggingUtils.PrintError("Failed to find inventory for character corpse for '" .. sourceName .. "' at: " .. LoggingUtils.MakeGpsRichText(playersCorpse.position.x, playersCorpse.position.y, surface.name))
                end
                break
            end
        end
        if playersCorpse == nil then
            LoggingUtils.PrintError("Failed to find character corpse for '" .. sourceName .. "' at: " .. LoggingUtils.MakeGpsRichText(corpsePosition.x, corpsePosition.y, surface.name))
        end
    elseif TestingSettings.giveZombieDefaultItems then
        zombieEngineer.inventory = game.create_inventory(1)
        zombieEngineer.inventory.insert({ name = "iron-plate", count = 1 })
    end

    -- Create the zombie entity.
    local zombieCreatePosition = surface.find_non_colliding_position("zombie_engineer-zombie_engineer", zombieTargetPosition, 10, 0.1, false)
    if zombieCreatePosition == nil then
        LoggingUtils.PrintError("Failed to find somewhere to create zombie engineer for '" .. sourceName .. "' near: " .. LoggingUtils.MakeGpsRichText(zombieTargetPosition.x, zombieTargetPosition.y, surface.name))
        return nil
    end
    ---@diagnostic disable-next-line: missing-fields # Temporary work around until Factorio docs and FMTK updated to allow per type field specification.
    zombieEngineerEntity = surface.create_entity({ name = "zombie_engineer-zombie_engineer", position = zombieCreatePosition, direction = math.random(0, 7), force = global.ZombieEngineerGlobal.zombieForce })
    if zombieEngineerEntity == nil then
        LoggingUtils.PrintError("Failed to create zombie engineer for '" .. sourceName .. "' at: " .. LoggingUtils.MakeGpsRichText(zombieCreatePosition.x, zombieCreatePosition.y, surface.name))
        return nil
    end
    zombieEngineer.entity = zombieEngineerEntity
    zombieEngineer.unitNumber = zombieEngineerEntity.unit_number

    -- Only increment the zombie count and record the zombie object if successful.
    zombieEngineer.id = global.ZombieEngineerManager.currentId + 1
    global.ZombieEngineerManager.currentId = global.ZombieEngineerManager.currentId + 1
    global.ZombieEngineerManager.zombieEngineers[zombieEngineer.id] = zombieEngineer
    global.ZombieEngineerManager.zombieEngineerUnitNumberLookup[zombieEngineer.unitNumber] = zombieEngineer

    if zombieName == nil and #global.ZombieEngineerCreation.Settings.zombieNames > 0 then
        zombieName = global.ZombieEngineerCreation.Settings.zombieNames[math.random(#global.ZombieEngineerCreation.Settings.zombieNames)]
    end
    if zombieName ~= nil then
        zombieEngineer.zombieName = zombieName
        zombieEngineer.nameRenderId = rendering.draw_text({ text = zombieName, surface = zombieEngineer.surface, target = zombieEngineer.entity, color = zombieEngineer.textColor, target_offset = { 0.0, -2.0 }, scale_with_zoom = true, alignment = "center", vertical_alignment = "middle" })
    end

    if player ~= nil then
        MOD.Interfaces.ZombieEngineerPlayerLines.RecordPlayerEntityLine(zombieEngineer.entity, player, "zombieEngineerEntity_" .. zombieName)
    end

    return zombieEngineer
end

return ZombieEngineerCreation
