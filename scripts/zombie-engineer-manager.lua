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
end

ZombieEngineerManager.OnLoad = function()
    Events.RegisterHandlerEvent(defines.events.on_player_died, "ZombieEngineerManager.OnPlayerDied", ZombieEngineerManager.OnPlayerDied)
end

---@param eventData EventData.on_player_died
ZombieEngineerManager.OnPlayerDied = function(eventData)
    local zombieEngineer = {} ---@class ZombieEngineer
    zombieEngineer.id = global.ZombieEngineerManager.currentId + 1
    global.ZombieEngineerManager.currentId = global.ZombieEngineerManager.currentId + 1

    local player = game.get_player(eventData.player_index) ---@cast player -nil # This event only fires if player is valid.
    zombieEngineer.sourcePlayer = player
    local character = player.character ---@cast character -nil # Player had to have a character to die.
    local character_position = character.position
    local surface = character.surface
    zombieEngineer.surface = surface

    -- Find this player's current corpse as that has all the items in it.
    local characterCorpsesNearBy = surface.find_entities_filtered({ position = character_position, radius = 5, type = "character-corpse" })
    local characterCorpse ---@type LuaEntity
    for _, corpse in pairs(characterCorpsesNearBy) do
        if corpse.character_corpse_tick_of_death == eventData.tick and corpse.character_corpse_player_index == eventData.player_index then
            characterCorpse = corpse
            break
        end
    end
    if characterCorpse == nil then
        LoggingUtils.PrintError("Failed to find character corpse for '" .. player.name .. "' at: " .. LoggingUtils.MakeGpsRichText(character_position.x, character_position.y, surface.name))
        return
    end
    zombieEngineer.inventory = InventoryUtils.TransferInventoryContentsToScriptInventory(characterCorpse.get_inventory(defines.inventory.character_corpse) --[[@as LuaInventory]], nil)

    -- Create the zombie entity.
    ---@diagnostic disable-next-line: missing-fields # Temporary work around until Factorio docs and FMTK updated to allow per type field specification.
    zombieEngineerEntity = surface.create_entity({ name = "Zombie_Engineer-zombie_engineer", position = character_position, direction = math.random(1, 8) })
    if zombieEngineerEntity == nil then
        LoggingUtils.PrintError("Failed to create zombie engineer for '" .. player.name .. "' at: " .. LoggingUtils.MakeGpsRichText(character_position.x, character_position.y, surface.name))
        return
    end
    zombieEngineerEntity.color = player.color
    zombieEngineer.entity = zombieEngineerEntity
end

return ZombieEngineerManager
