local Events = require("utility.manager-libraries.events")
local InventoryUtils = require("utility.helper-utils.inventory-utils")
local LoggingUtils = require("utility.helper-utils.logging-utils")

---@class ZombieEngineer
---@field id uint
---@field entity LuaEntity
---@field surface LuaSurface
---@field sourcePlayer LuaPlayer
---@field inventory LuaInventory

local ZombieEngineerManager = {} ---@class Class_ZombieEngineerManager

ZombieEngineerManager.CreateGlobals = function()
    global.ZombieEngineerManager = global.ZombieEngineerManager or {} ---@class Global_ZombieEngineerManager
    global.ZombieEngineerManager.currentId = global.ZombieEngineerManager.currentId or 0 ---@type uint
    global.ZombieEngineerManager.zombieEngineers = global.ZombieEngineerManager.zombieEngineers or {} ---@type table<uint, ZombieEngineer>

    global.ZombieEngineerManager.zombieForce = global.ZombieEngineerManager.zombieForce or ZombieEngineerManager.CreateZombieForce() ---@type LuaForce
end

ZombieEngineerManager.OnLoad = function()
    Events.RegisterHandlerEvent(defines.events.on_player_died, "ZombieEngineerManager.OnPlayerDied", ZombieEngineerManager.OnPlayerDied)
end

---@param eventData EventData.on_player_died
ZombieEngineerManager.OnPlayerDied = function(eventData)
    local player = game.get_player(eventData.player_index)
    if player == nil then
        LoggingUtils.PrintError("On_Player_Died event occurred for non-player player_index: " .. eventData.player_index)
        return
    end

    local character = player.character
    if character == nil then
        LoggingUtils.PrintError("Player died without a character, player name: '" .. player.name .. "'")
        return
    end

    ZombieEngineerManager.CreateZombie(player, eventData.player_index, character.surface, character.position, character.position)
end

---@param player LuaPlayer
---@param player_index uint
---@param surface LuaSurface
---@param corpsePosition MapPosition
---@param zombiePosition MapPosition
---@return ZombieEngineer?
ZombieEngineerManager.CreateZombie = function(player, player_index, surface, corpsePosition, zombiePosition)
    local currentTick = game.tick

    local zombieEngineer = {} ---@class ZombieEngineer
    zombieEngineer.id = global.ZombieEngineerManager.currentId + 1
    global.ZombieEngineerManager.currentId = global.ZombieEngineerManager.currentId + 1

    zombieEngineer.sourcePlayer = player
    zombieEngineer.surface = surface

    -- Find this player's current corpse if one specified and exists, then take the items from it.
    if corpsePosition ~= nil then
        local characterCorpsesNearBy = surface.find_entities_filtered({ position = corpsePosition, radius = 5, type = "character-corpse" })
        local characterCorpse ---@type LuaEntity
        for _, corpse in pairs(characterCorpsesNearBy) do
            if corpse.character_corpse_tick_of_death == currentTick and corpse.character_corpse_player_index == player_index then
                characterCorpse = corpse
                break
            end
        end
        if characterCorpse == nil then
            LoggingUtils.PrintError("Failed to find character corpse for '" .. player.name .. "' at: " .. LoggingUtils.MakeGpsRichText(corpsePosition.x, corpsePosition.y, surface.name))
        else
            zombieEngineer.inventory = InventoryUtils.TransferInventoryContentsToScriptInventory(characterCorpse.get_inventory(defines.inventory.character_corpse) --[[@as LuaInventory]], nil)
        end
    end

    -- Create the zombie entity.
    local zombieCreatePosition = surface.find_non_colliding_position("Zombie_Engineer-zombie_engineer", zombiePosition, 10, 0.1, false)
    if zombieCreatePosition == nil then
        LoggingUtils.PrintError("Failed to find somewhere to create zombie engineer for '" .. player.name .. "' near: " .. LoggingUtils.MakeGpsRichText(zombiePosition.x, zombiePosition.y, surface.name))
        return nil
    end
    ---@diagnostic disable-next-line: missing-fields # Temporary work around until Factorio docs and FMTK updated to allow per type field specification.
    zombieEngineerEntity = surface.create_entity({ name = "Zombie_Engineer-zombie_engineer", position = zombieCreatePosition, direction = math.random(1, 8), force = global.ZombieEngineerManager.zombieForce })
    if zombieEngineerEntity == nil then
        LoggingUtils.PrintError("Failed to create zombie engineer for '" .. player.name .. "' at: " .. LoggingUtils.MakeGpsRichText(zombieCreatePosition.x, zombieCreatePosition.y, surface.name))
        return nil
    end
    zombieEngineerEntity.color = player.color
    zombieEngineer.entity = zombieEngineerEntity

    return zombieEngineer
end

---@return LuaForce
ZombieEngineerManager.CreateZombieForce = function()
    local zombieForce = game.create_force("Zombie_Engineer-zombie_engineer")

    -- Make the zombie and biters be friends.
    local biterForce = game.forces["enemy"]
    zombieForce.set_friend(biterForce, true)
    biterForce.set_friend(zombieForce, true)

    -- Make the Player be cease fire with the zombie.
    local playerForce = game.forces["player"]
    playerForce.set_cease_fire(zombieForce, true)

    return zombieForce
end

return ZombieEngineerManager
