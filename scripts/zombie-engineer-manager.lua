local Events = require("utility.manager-libraries.events")
local InventoryUtils = require("utility.helper-utils.inventory-utils")
local LoggingUtils = require("utility.helper-utils.logging-utils")
local EventScheduler = require("utility.manager-libraries.event-scheduler")
local PositionUtils = require("utility.helper-utils.position-utils")

---@class ZombieEngineer
---@field id uint
---@field state ZombieEngineer_State
---@field entity? LuaEntity
---@field surface LuaSurface
---@field sourceName string
---@field sourcePlayer? LuaPlayer
---@field inventory LuaInventory
---@field objective ZombieEngineer_Objective
---@field action ZombieEngineer_Action
---@field distractionTarget? LuaEntity
---@field pathBlockingTarget? LuaEntity

---@enum ZombieEngineer_State
local ZOMBIE_ENGINEER_STATE = {
    alive = "alive",
    dead = "dead"
}

---@enum ZombieEngineer_Objective
local ZOMBIE_ENGINEER_OBJECTIVE = {
    movingToSpawn = "movingToSpawn",
    rampagingSpawn = "rampagingSpawn"
}

---@enum ZombieEngineer_Action
local ZOMBIE_ENGINEER_ACTION = {
    idle = "idle",
    findingPath = "findingPath",
    movingToPathBlockingTarget = "movingToPathBlockingTarget",
    chasingDistraction = "chasingDistraction"
}

local ZombieEngineerManager = {} ---@class Class_ZombieEngineerManager

ZombieEngineerManager.CreateGlobals = function()
    global.ZombieEngineerManager = global.ZombieEngineerManager or {} ---@class Global_ZombieEngineerManager
    global.ZombieEngineerManager.currentId = global.ZombieEngineerManager.currentId or 0 ---@type uint
    global.ZombieEngineerManager.zombieEngineers = global.ZombieEngineerManager.zombieEngineers or {} ---@type table<uint, ZombieEngineer>

    global.ZombieEngineerManager.zombieForce = global.ZombieEngineerManager.zombieForce ---@type LuaForce # Created as part of OnStartup if required.
    global.ZombieEngineerManager.zombiePathingCollisionMask = global.ZombieEngineerManager.zombiePathingCollisionMask ---@type data.CollisionMask # Obtained as part of OnStartup if required.
    global.ZombieEngineerManager.playerForces = global.ZombieEngineerManager.playerForces ---@type LuaForce[]
    global.ZombieEngineerManager.requestedPaths = global.ZombieEngineerManager.requestedPaths or {} ---@type table<uint, ZombieEngineer> # Key'd by the path request ID.

    global.ZombieEngineerManager.Settings = {
        distractionRange = 50, -- Longer than a rocket launcher.
    }
end

ZombieEngineerManager.OnLoad = function()
    Events.RegisterHandlerEvent(defines.events.on_player_died, "ZombieEngineerManager.OnPlayerDied", ZombieEngineerManager.OnPlayerDied)
    Events.RegisterHandlerEvent(defines.events.on_entity_died, "ZombieEngineerManager.OnEntityDiedGravestone", ZombieEngineerManager.OnEntityDiedGravestone, { { filter = "name", name = "zombie_engineer-grave_with_headstone" } })
    Events.RegisterHandlerEvent(defines.events.on_script_path_request_finished, "ZombieEngineerManager.OnScriptPathRequestFinished", ZombieEngineerManager.OnScriptPathRequestFinished)
end

ZombieEngineerManager.OnStartup = function()
    if global.ZombieEngineerManager.zombieForce == nil then
        global.ZombieEngineerManager.zombieForce = ZombieEngineerManager.CreateZombieForce()
    end
    if global.ZombieEngineerManager.zombiePathingCollisionMask == nil then
        global.ZombieEngineerManager.zombiePathingCollisionMask = game.entity_prototypes["zombie_engineer-zombie_engineer_path_collision_layer"].collision_mask
    end
    global.ZombieEngineerManager.playerForces = { game.forces["player"] } -- We might want to add support for more in future, so why not variable it now.
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

    ZombieEngineerManager.CreateZombie(player, eventData.player_index, player.name, character.surface, character.position, character.position)
end

---@param eventData EventData.on_entity_died
ZombieEngineerManager.OnEntityDiedGravestone = function(eventData)
    local diedEntity = eventData.entity
    ZombieEngineerManager.CreateZombie(nil, nil, "gravestone", diedEntity.surface, diedEntity.position, diedEntity.position)
end

---@param player? LuaPlayer
---@param player_index? uint
---@param sourceName string
---@param surface LuaSurface
---@param corpsePosition MapPosition
---@param zombieTargetPosition MapPosition
---@return ZombieEngineer?
ZombieEngineerManager.CreateZombie = function(player, player_index, sourceName, surface, corpsePosition, zombieTargetPosition)
    local currentTick = game.tick

    local zombieEngineer = {} ---@class ZombieEngineer
    zombieEngineer.sourcePlayer = player
    zombieEngineer.sourceName = sourceName
    zombieEngineer.surface = surface
    zombieEngineer.state = ZOMBIE_ENGINEER_STATE.alive
    zombieEngineer.objective = ZOMBIE_ENGINEER_OBJECTIVE.movingToSpawn
    zombieEngineer.action = ZOMBIE_ENGINEER_ACTION.idle

    -- Find this player's current corpse if one specified and exists, then take the items from it.
    if player ~= nil and corpsePosition ~= nil then
        local characterCorpsesNearBy = surface.find_entities_filtered({ position = corpsePosition, radius = 5, type = "character-corpse" })
        local characterCorpse ---@type LuaEntity
        for _, corpse in pairs(characterCorpsesNearBy) do
            if corpse.character_corpse_tick_of_death == currentTick and corpse.character_corpse_player_index == player_index then
                characterCorpse = corpse
                break
            end
        end
        if characterCorpse == nil then
            LoggingUtils.PrintError("Failed to find character corpse for '" .. sourceName .. "' at: " .. LoggingUtils.MakeGpsRichText(corpsePosition.x, corpsePosition.y, surface.name))
        else
            zombieEngineer.inventory = InventoryUtils.TransferInventoryContentsToScriptInventory(characterCorpse.get_inventory(defines.inventory.character_corpse) --[[@as LuaInventory]], nil)
        end
    end

    -- Create the zombie entity.
    local zombieCreatePosition = surface.find_non_colliding_position("zombie_engineer-zombie_engineer", zombieTargetPosition, 10, 0.1, false)
    if zombieCreatePosition == nil then
        LoggingUtils.PrintError("Failed to find somewhere to create zombie engineer for '" .. sourceName .. "' near: " .. LoggingUtils.MakeGpsRichText(zombieTargetPosition.x, zombieTargetPosition.y, surface.name))
        return nil
    end
    ---@diagnostic disable-next-line: missing-fields # Temporary work around until Factorio docs and FMTK updated to allow per type field specification.
    zombieEngineerEntity = surface.create_entity({ name = "zombie_engineer-zombie_engineer", position = zombieCreatePosition, direction = math.random(0, 7), force = global.ZombieEngineerManager.zombieForce })
    if zombieEngineerEntity == nil then
        LoggingUtils.PrintError("Failed to create zombie engineer for '" .. sourceName .. "' at: " .. LoggingUtils.MakeGpsRichText(zombieCreatePosition.x, zombieCreatePosition.y, surface.name))
        return nil
    end
    zombieEngineer.entity = zombieEngineerEntity

    -- Only increment the zombie count and record the zombie object if successful.
    zombieEngineer.id = global.ZombieEngineerManager.currentId + 1
    global.ZombieEngineerManager.currentId = global.ZombieEngineerManager.currentId + 1
    global.ZombieEngineerManager.zombieEngineers[zombieEngineer.id] = zombieEngineer

    return zombieEngineer
end

---@return LuaForce
ZombieEngineerManager.CreateZombieForce = function()
    local zombieForce = game.create_force("zombie_engineer-zombie_engineer")

    -- Make the zombie and biters be friends.
    local biterForce = game.forces["enemy"]
    zombieForce.set_friend(biterForce, true)
    biterForce.set_friend(zombieForce, true)

    -- Make the Player be cease fire with the zombie.
    local playerForce = game.forces["player"]
    playerForce.set_cease_fire(zombieForce, true)

    -- Set the zombie color as a dark brown.
    zombieForce.custom_color = { r = 0.100, g = 0.040, b = 0.0, a = 0.7 }

    return zombieForce
end

---@param eventData NthTickEventData
ZombieEngineerManager.ManageAllZombieEngineers = function(eventData)
    local currentTick = eventData.tick

    for _, zombieEngineer in pairs(global.ZombieEngineerManager.zombieEngineers) do
        if zombieEngineer.state == ZOMBIE_ENGINEER_STATE.alive then
            ZombieEngineerManager.ManageZombieEngineer(zombieEngineer, currentTick)
        end
    end
end

---@param zombieEngineer ZombieEngineer
---@param currentTick uint
ZombieEngineerManager.ManageZombieEngineer = function(zombieEngineer, currentTick)
    if not ZombieEngineerManager.ValidateZombie(zombieEngineer) then
        return
    end

    -- TODO: clear targets when others are set.
    -- TODO: this logic isn't completely fleshed out.
    local zombieCurrentPosition = zombieEngineer.entity.position

    -- TODO: if we have a path to something and its moved, then we ned to get a new path. As We might need to attack something new on the way.
    if zombieEngineer.distractionTarget ~= nil then
        ZombieEngineerManager.ValidateDistractionTarget(zombieEngineer, zombieCurrentPosition)
    end
    if zombieEngineer.distractionTarget == nil then
        ZombieEngineerManager.FindDistractionTarget(zombieEngineer, zombieCurrentPosition)
    end

    if zombieEngineer.distractionTarget ~= nil then
        ZombieEngineerManager.AttackTowardsDistractionTarget(zombieEngineer)
    else
        if zombieEngineer.objective == ZOMBIE_ENGINEER_OBJECTIVE.rampagingSpawn then
            if zombieEngineer.pathBlockingTarget ~= nil then
                ZombieEngineerManager.ValidatePathBlockingTarget(zombieEngineer)
            end
            if zombieEngineer.pathBlockingTarget == nil then
                ZombieEngineerManager.FindRampageTarget(zombieEngineer)
            end
            if zombieEngineer.pathBlockingTarget ~= nil then
                ZombieEngineerManager.AttackPathBlockingTarget(zombieEngineer)
            end
        elseif zombieEngineer.objective == ZOMBIE_ENGINEER_OBJECTIVE.movingToSpawn then
            --TODO
        else
            LoggingUtils.PrintError("Zombie is in un-recognised state '" .. zombieEngineer.state .. "' here: " .. LoggingUtils.MakeGpsRichText_Entity(zombieEngineer.entity))
            if global.debugSettings.testing then error("Zombie is in un-recognised state") end
            return
        end
    end
end


---@param zombieEngineer ZombieEngineer
---@return boolean
ZombieEngineerManager.ValidateZombie = function(zombieEngineer)
    local zombieValidated = true
    if zombieEngineer.entity == nil or (not zombieEngineer.entity.valid) then
        zombieValidated = false
    end

    if zombieValidated then
        return true
    end

    -- Invalid Zombie.
    LoggingUtils.PrintError("Zombie number '" .. zombieEngineer.id .. "' raised from '" .. zombieEngineer.sourceName "' failed validation and so has been cancelled")
    if global.debugSettings.testing then error("Zombie failed validation") end
    zombieEngineer.state = ZOMBIE_ENGINEER_STATE.dead
    zombieEngineer.entity = nil
    return false
end

---@param zombieEngineer ZombieEngineer
---@param zombieCurrentPosition MapPosition
ZombieEngineerManager.ValidateDistractionTarget = function(zombieEngineer, zombieCurrentPosition)
    --TODO: we only need to check this every second or two.

    if not zombieEngineer.distractionTarget.valid then
        zombieEngineer.distractionTarget = nil
        return
    end

    if PositionUtils.GetDistance(zombieCurrentPosition, zombieEngineer.distractionTarget.position) > global.ZombieEngineerManager.Settings.distractionRange then
        zombieEngineer.distractionTarget = nil
        return
    end
end

---@param zombieEngineer ZombieEngineer
---@param zombieCurrentPosition MapPosition
ZombieEngineerManager.FindDistractionTarget = function(zombieEngineer, zombieCurrentPosition)
    -- TODO: we only need to check this every second or two, or when we have just lost our current distraction target.

    local nearestTargetEntity, nearestTargetDistance ---@type LuaEntity, double
    local thisDistance ---@type double

    local nearbyCharacter = zombieEngineer.surface.find_entities_filtered({ type = "character", position = zombieEngineer.entity.position, radius = global.ZombieEngineerManager.Settings.distractionRange, force = global.ZombieEngineerManager.playerForces })
    for _, characterEntity in pairs(nearbyCharacter) do
        thisDistance = PositionUtils.GetDistance(zombieCurrentPosition, characterEntity.position)
        if nearestTargetDistance == nil or thisDistance < nearestTargetDistance then
            nearestTargetEntity = characterEntity
            nearestTargetDistance = thisDistance
        end
    end

    local nearbyVehicles = zombieEngineer.surface.find_entities_filtered({ type = { "car", "spider-vehicle" }, position = zombieEngineer.entity.position, radius = global.ZombieEngineerManager.Settings.distractionRange, force = global.ZombieEngineerManager.playerForces })
    for _, vehicleEntity in pairs(nearbyVehicles) do
        if vehicleEntity.get_driver() ~= nil or vehicleEntity.get_passenger() ~= nil then
            thisDistance = PositionUtils.GetDistance(zombieCurrentPosition, vehicleEntity.position)
            if nearestTargetDistance == nil or thisDistance < nearestTargetDistance then
                nearestTargetEntity = vehicleEntity
                nearestTargetDistance = thisDistance
            end
        end
    end

    if nearestTargetEntity ~= nil then
        zombieEngineer.distractionTarget = nearestTargetEntity
    end
end

---@param zombieEngineer ZombieEngineer
ZombieEngineerManager.AttackTowardsDistractionTarget = function(zombieEngineer)
    -- zombieEngineer.distractionTarget is not nil if this function was reached.
    if zombieEngineer.action == ZOMBIE_ENGINEER_ACTION.idle then
        ZombieEngineerManager.FindPath(zombieEngineer, zombieEngineer.distractionTarget)
        zombieEngineer.action = ZOMBIE_ENGINEER_ACTION.findingPath
        return
    end

    --TODO: if we have a path.
end

---@param zombieEngineer ZombieEngineer
ZombieEngineerManager.ValidatePathBlockingTarget = function(zombieEngineer)
    --TODO
end

---@param zombieEngineer ZombieEngineer
ZombieEngineerManager.FindRampageTarget = function(zombieEngineer)
    --TODO
end

---@param zombieEngineer ZombieEngineer
ZombieEngineerManager.AttackPathBlockingTarget = function(zombieEngineer)
    --TODO
end

---@param zombieEngineer ZombieEngineer
---@param targetEntity? LuaEntity
---@param targetPosition? MapPosition
ZombieEngineerManager.FindPath = function(zombieEngineer, targetEntity, targetPosition)
    if targetEntity == nil and targetPosition == nil then
        LoggingUtils.PrintError("Zombie needs a target to find a path, zombie here: '" .. LoggingUtils.MakeGpsRichText_Entity(zombieEngineer.entity))
        if global.debugSettings.testing then error("FindPath needs target entity or position") end
        return
    end
    if targetEntity ~= nil then
        targetPosition = targetEntity.position
    end ---@cast targetPosition -nil

    -- TODO: OLD NOTES
    -- Another way is to get a path that ignores all player entities using a custom collision mask on everything with player-layer other than player buildable entities. Will also avoid water. As we are only adding it to some of the things with player-layer we wouldn't be expanding the overlap in collision masks, so this won't break anything.
    -- This concept here just uses the resource-layer, as his ignores entities, but respects water. However, we also want to avoid biter bases and worms, plus probably trees and rocks? So maybe more of an explicitly inclusive thing.
    -- We'd then have to check for all entities collision boxes on this path and target the first one.

    local pathRequestId = zombieEngineer.surface.request_path({ bounding_box = { { -0.5, -0.5 }, { 0.5, 0.5 } }, collision_mask = global.ZombieEngineerManager.zombiePathingCollisionMask, start = zombieEngineer.entity.position, goal = targetPosition, force = zombieEngineer.entity.force, radius = 1, pathfind_flags = { cache = false, no_break = true }, can_open_gates = false, path_resolution_modifier = 0, entity_to_ignore = targetEntity })
    global.ZombieEngineerManager.requestedPaths[pathRequestId] = zombieEngineer
end

---@param eventData EventData.on_script_path_request_finished
ZombieEngineerManager.OnScriptPathRequestFinished = function(eventData)
    -- TODO: handle eventData.try_again_later

    local zombieEngineer = global.ZombieEngineerManager.requestedPaths[eventData.id]
    if zombieEngineer == nil then
        return
    end

    local path = eventData.path
    if path == nil then
        game.print("no path found")
        return
    end
    LoggingUtils.DrawPath(path, game.surfaces[1], nil, nil, "start", "end")

    -- TODO: Do something with the result back to the zombieEngineer
end

return ZombieEngineerManager
