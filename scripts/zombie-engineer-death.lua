local Events = require("utility.manager-libraries.events")
local LoggingUtils = require("utility.helper-utils.logging-utils")
local DirectionUtils = require("utility.helper-utils.direction-utils")
local EntityUtils = require("utility.helper-utils.entity-utils")
local InventoryUtils = require("utility.helper-utils.inventory-utils")

local ZombieEngineerDeath = {} ---@class Class_ZombieEngineerDeath

ZombieEngineerDeath.CreateGlobals = function()
    global.ZombieEngineerDeath = global.ZombieEngineerDeath or {} ---@class Global_ZombieEngineerDeath
end

ZombieEngineerDeath.OnLoad = function()
    local onEntityDiedFilters = {} ---@type LuaEntityDiedEventFilter[]
    for zombieEngineerEntityName in pairs(global.ZombieEngineerGlobal.zombieEngineerEntityNames) do
        ---@diagnostic disable-next-line: missing-fields # Temporary work around until Factorio docs and FMTK updated to allow per type field specification.
        onEntityDiedFilters[#onEntityDiedFilters + 1] = { filter = "name", name = zombieEngineerEntityName }
    end
    Events.RegisterHandlerEvent(defines.events.on_entity_died, "ZombieEngineerDeath.OnEntityDiedZombieEngineer", ZombieEngineerDeath.OnEntityDiedZombieEngineer, onEntityDiedFilters)
end

ZombieEngineerDeath.OnStartup = function()
end

---@param event EventData.on_runtime_mod_setting_changed|nil # nil value when called from OnStartup (on_init & on_configuration_changed)
ZombieEngineerDeath.OnSettingChanged = function(event)
end

---@param eventData EventData.on_entity_died
ZombieEngineerDeath.OnEntityDiedZombieEngineer = function(eventData)
    local entity = eventData.entity
    if global.ZombieEngineerGlobal.zombieEngineerEntityNames[entity.name] == nil then return end

    local entity_unitNumber = entity.unit_number ---@cast entity_unitNumber -nil # This is always populated for units.
    local zombieEngineer = global.ZombieEngineerManager.zombieEngineerUnitNumberLookup[entity_unitNumber]
    if zombieEngineer == nil then
        LoggingUtils.PrintError("Zombie entity died, but it was unmanaged. Here: " .. LoggingUtils.MakeGpsRichText_Entity(entity))
        if global.debugSettings.testing then error("Zombie died that was unmanaged") end
        return
    end

    local corpseForce, playerIndex, sourcePlayer ---@type ForceIdentification, uint?, LuaPlayer?
    local corpseColor = zombieEngineer.entityColor
    if zombieEngineer.sourcePlayer ~= nil then
        sourcePlayer = zombieEngineer.sourcePlayer ---@cast sourcePlayer -nil
        corpseForce = sourcePlayer.force
        playerIndex = sourcePlayer.index
    else
        sourcePlayer = nil
        corpseForce = global.ZombieEngineerGlobal.zombieForce
        playerIndex = nil
    end
    local inventorySize = zombieEngineer.inventory and #zombieEngineer.inventory or 0
    local corpseDirection = DirectionUtils.OrientationToNearestDirection(entity.orientation)

    ---@diagnostic disable-next-line: missing-fields # Temporary work around until Factorio docs and FMTK updated to allow per type field specification.
    local zombieCorpse = zombieEngineer.surface.create_entity({ name = "character-corpse", position = entity.position, force = corpseForce, direction = corpseDirection, inventory_size = inventorySize, player_index = playerIndex, player = sourcePlayer })

    if zombieCorpse == nil then
        LoggingUtils.PrintError("Zombie corpse failed to create. Here: " .. LoggingUtils.MakeGpsRichText_Entity(entity))
        if global.debugSettings.testing then error("Zombie corpse creation failed") end
        return
    end

    if inventorySize > 0 then
        local corpseInventory = zombieCorpse.get_inventory(defines.inventory.character_corpse) ---@cast corpseInventory -nil
        InventoryUtils.TryMoveInventoriesLuaItemStacks(zombieEngineer.inventory, corpseInventory, true, 100)
    end
    zombieCorpse.color = corpseColor

    ZombieEngineerDeath.ZombieEntityRemoved(zombieEngineer)

    local zombieKiller = eventData.cause
    local zombieKillerPlayer ---@type LuaPlayer?
    if zombieKiller ~= nil then
        zombieKillerPlayer = EntityUtils.GetPlayerControllingEntity(zombieKiller, zombieKiller.type)
    end
    if zombieKillerPlayer and zombieEngineer.sourcePlayer ~= nil then
        game.print({ "message.zombie_engineer-player_killed_zombie", zombieKillerPlayer.name, zombieEngineer.sourceName })
    end

    if zombieEngineer.sourcePlayer ~= nil then
        MOD.Interfaces.ZombieEngineerPlayerLines.RecordPlayerEntityLine(zombieCorpse, zombieEngineer.sourcePlayer, "zombieEngineerCorpse_" .. zombieEngineer.zombieName)
    end
end

---@param zombieEngineer ZombieEngineer
ZombieEngineerDeath.ZombieEntityRemoved = function(zombieEngineer)
    zombieEngineer.state = MOD.Interfaces.ZombieEngineerManager.Enums.ZOMBIE_ENGINEER_STATE.dead
    zombieEngineer.entity = nil
    zombieEngineer.unitNumber = nil
end

return ZombieEngineerDeath
