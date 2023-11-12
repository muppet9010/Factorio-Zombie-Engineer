local Events = require("utility.manager-libraries.events")
local InventoryUtils = require("utility.helper-utils.inventory-utils")
local LoggingUtils = require("utility.helper-utils.logging-utils")
local EventScheduler = require("utility.manager-libraries.event-scheduler")
local PositionUtils = require("utility.helper-utils.position-utils")
local Colors = require("utility.lists.colors")
local DirectionUtils = require("utility.helper-utils.direction-utils")
local EntityUtils = require("utility.helper-utils.entity-utils")
local EntityTypeGroups = require("utility.lists.entity-type-groups")
local StringUtils = require("utility.helper-utils.string-utils")

---@class ZombieEngineer_TestingSettings
local TestingSettings = {
    giveZombieDefaultItems = false
}

---@class ZombieEngineer
---@field id uint
---@field state ZombieEngineer_State
---@field entity? LuaEntity
---@field entityColor Color # Currently we can't color zombie entities, so this is just used for their corpse. In the future tasks list.
---@field unitNumber uint
---@field surface LuaSurface
---@field sourceName string # Either source player's name, "gravestone" or the text passed in on the interface call.
---@field sourcePlayer? LuaPlayer
---@field zombieName? string
---@field textColor Color
---@field nameRenderId? uint64
---@field inventory? LuaInventory
---@field objective ZombieEngineer_Objective
---@field action ZombieEngineer_Action
---@field distractionTarget? LuaEntity
---@field pathBlockingTarget? LuaEntity
---@field path? PathfinderWaypoint[]
---@field attackingNodeInPath uint
---@field debug_pathWaypointRenderIds? uint64[]
---@field debug_attackCommandRenderId? uint64

---@class ZombieEngineer_PathRequestDetails
---@field pathRequestId uint
---@field zombieEngineer ZombieEngineer
---@field sourcePosition MapPosition
---@field targetEntity? LuaEntity
---@field targetPosition MapPosition
---@field pathPurpose ZombieEngineer_PathfinderPurpose

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

---@enum ZombieEngineer_PathfinderPurpose
local ZOMBIE_ENGINEER_PATHFINDER_PURPOSE = {
    distraction = "distraction",
    pathBlocking = "pathBlocking",
    pathToSpawn = "pathToSpawn"
}

local ZombieEngineerManager = {} ---@class Class_ZombieEngineerManager

ZombieEngineerManager.CreateGlobals = function()
    global.ZombieEngineerManager = global.ZombieEngineerManager or {} ---@class Global_ZombieEngineerManager

    global.ZombieEngineerManager.currentId = global.ZombieEngineerManager.currentId or 0 ---@type uint
    global.ZombieEngineerManager.zombieEngineers = global.ZombieEngineerManager.zombieEngineers or {} ---@type table<uint, ZombieEngineer> # Key'd by id of Zombie.
    global.ZombieEngineerManager.zombieEngineerUnitNumberLookup = global.ZombieEngineerManager.zombieEngineerUnitNumberLookup or {} ---@type table<uint, ZombieEngineer> # Key'd by the zombies unit number.

    global.ZombieEngineerManager.zombieForce = global.ZombieEngineerManager.zombieForce ---@type LuaForce # Created as part of OnStartup if required.
    global.ZombieEngineerManager.zombiePathingCollisionMask = global.ZombieEngineerManager.zombiePathingCollisionMask ---@type data.CollisionMask # Obtained as part of OnStartup if required.
    global.ZombieEngineerManager.zombieEntityCollisionMask = global.ZombieEngineerManager.zombieEntityCollisionMask ---@type data.CollisionMask # Obtained as part of OnStartup if required.
    global.ZombieEngineerManager.playerForces = global.ZombieEngineerManager.playerForces ---@type LuaForce[]
    global.ZombieEngineerManager.requestedPaths = global.ZombieEngineerManager.requestedPaths or {} ---@type table<uint, ZombieEngineer_PathRequestDetails> # Key'd by the path request ID.
    global.ZombieEngineerManager.playerDeathCounts = global.ZombieEngineerManager.playerDeathCounts or {} ---@type table<uint, uint> # Player Index to death count.

    global.ZombieEngineerManager.Settings = {
        distractionRange = 50, -- Longer than a rocket launcher.
        zombieNames = {}, ---@type string[] # Populated as part of OnStartup or when the relevant mod setting changes.
        zombieEntityColor = { r = 0.100, g = 0.040, b = 0.0, a = 0.7 }, ---@type Color
        zombieTextColor = { r = 0.5, g = 0.5, b = 0.5, a = 0.7 } ---@type Color # Dark color isn't very readable.
    }
end

ZombieEngineerManager.OnLoad = function()
    Events.RegisterHandlerEvent(defines.events.on_player_died, "ZombieEngineerManager.OnPlayerDied", ZombieEngineerManager.OnPlayerDied)
    Events.RegisterHandlerEvent(defines.events.on_entity_died, "ZombieEngineerManager.OnEntityDiedGravestone", ZombieEngineerManager.OnEntityDiedGravestone, { { filter = "name", name = "zombie_engineer-grave_with_headstone" } })
    Events.RegisterHandlerEvent(defines.events.on_script_path_request_finished, "ZombieEngineerManager.OnScriptPathRequestFinished", ZombieEngineerManager.OnScriptPathRequestFinished)
    Events.RegisterHandlerEvent(defines.events.on_entity_died, "ZombieEngineerManager.OnEntityDiedZombieEngineer", ZombieEngineerManager.OnEntityDiedZombieEngineer, { { filter = "name", name = "zombie_engineer-zombie_engineer" } })
end

ZombieEngineerManager.OnStartup = function()
    if global.ZombieEngineerManager.zombiePathingCollisionMask == nil then
        global.ZombieEngineerManager.zombiePathingCollisionMask = game.entity_prototypes["zombie_engineer-zombie_engineer_path_collision_layer"].collision_mask
    end
    if global.ZombieEngineerManager.zombieEntityCollisionMask == nil then
        global.ZombieEngineerManager.zombieEntityCollisionMask = game.entity_prototypes["zombie_engineer-zombie_engineer"].collision_mask
    end
    global.ZombieEngineerManager.playerForces = { game.forces["player"] } -- We might want to add support for more in future, so why not variable it now.

    if global.ZombieEngineerManager.zombieForce == nil then
        global.ZombieEngineerManager.zombieForce = ZombieEngineerManager.CreateZombieForce()
    end
end

---@param event EventData.on_runtime_mod_setting_changed|nil # nil value when called from OnStartup (on_init & on_configuration_changed)
ZombieEngineerManager.OnSettingChanged = function(event)
    if event == nil or event.setting == "zombie_engineer-zombie_names" then
        local rawSettingString = settings.global["zombie_engineer-zombie_names"].value --[[@as string]]
        rawSettingString = StringUtils.StringTrim(rawSettingString)
        if rawSettingString == "" then
            global.ZombieEngineerManager.Settings.zombieNames = {}
        else
            global.ZombieEngineerManager.Settings.zombieNames = StringUtils.SplitStringOnCharactersToList(rawSettingString, ",")
        end
    end
end

---@param eventData EventData.on_player_died
ZombieEngineerManager.OnPlayerDied = function(eventData)
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

    global.ZombieEngineerManager.playerDeathCounts[eventData.player_index] = (global.ZombieEngineerManager.playerDeathCounts[eventData.player_index] ~= nil and global.ZombieEngineerManager.playerDeathCounts[eventData.player_index] or 0) + 1

    local zombieName = player_name .. " (" .. global.ZombieEngineerManager.playerDeathCounts[eventData.player_index] .. ")"

    -- Players position has been returned to their corpse by the point this event fires (if they were in map view at time of death).
    ZombieEngineerManager.CreateZombie(player, eventData.player_index, player_name, player_color, zombieName, player_color, player_surface, player_position, player_position)
end

---@param eventData EventData.on_entity_died
ZombieEngineerManager.OnEntityDiedGravestone = function(eventData)
    local diedEntity = eventData.entity
    if diedEntity.name ~= "zombie_engineer-grave_with_headstone" then return end
    ZombieEngineerManager.CreateZombie(nil, nil, "gravestone", nil, nil, nil, diedEntity.surface, nil, diedEntity.position)
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
ZombieEngineerManager.CreateZombie = function(player, player_index, sourceName, entityColor, zombieName, textColor, surface, corpsePosition, zombieTargetPosition)
    local currentTick = game.tick

    local zombieEngineer = {} ---@class ZombieEngineer
    zombieEngineer.sourcePlayer = player
    zombieEngineer.sourceName = sourceName
    zombieEngineer.surface = surface
    zombieEngineer.state = ZOMBIE_ENGINEER_STATE.alive
    zombieEngineer.objective = ZOMBIE_ENGINEER_OBJECTIVE.movingToSpawn
    zombieEngineer.action = ZOMBIE_ENGINEER_ACTION.idle
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
    zombieEngineerEntity = surface.create_entity({ name = "zombie_engineer-zombie_engineer", position = zombieCreatePosition, direction = math.random(0, 7), force = global.ZombieEngineerManager.zombieForce })
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

    if zombieName == nil and #global.ZombieEngineerManager.Settings.zombieNames > 0 then
        zombieName = global.ZombieEngineerManager.Settings.zombieNames[math.random(#global.ZombieEngineerManager.Settings.zombieNames)]
    end
    if zombieName ~= nil then
        zombieEngineer.zombieName = zombieName
        zombieEngineer.nameRenderId = rendering.draw_text({ text = zombieName, surface = zombieEngineer.surface, target = zombieEngineer.entity, color = zombieEngineer.textColor, target_offset = { 0.0, -2.0 }, scale_with_zoom = true, alignment = "center", vertical_alignment = "middle" })
    end

    return zombieEngineer
end

---@return LuaForce
ZombieEngineerManager.CreateZombieForce = function()
    local zombieForce = game.create_force("zombie_engineer-zombie_engineer")

    -- Make the zombie and biters be friends.
    local biterForce = game.forces["enemy"]
    zombieForce.set_friend(biterForce, true)
    biterForce.set_friend(zombieForce, true)

    -- Set the zombie color as a dark brown.
    zombieForce.custom_color = global.ZombieEngineerManager.Settings.zombieEntityColor -- Used by the zombie engineer unit as its runtime tint color.

    return zombieForce
end

---@param eventData NthTickEventData
ZombieEngineerManager.ManageAllZombieEngineers = function(eventData)
    if 1 == 1 then return end -- FUTURE ZOMBIE PATHING: make it use biter pathing.

    local currentTick = eventData.tick

    for _, zombieEngineer in pairs(global.ZombieEngineerManager.zombieEngineers) do
        if zombieEngineer.state == ZOMBIE_ENGINEER_STATE.alive then
            if not global.debugSettings.testing then
                -- Run the main zombie log in a "safe" way to avoid server crashes. A broken zombie that is killed via console command is better than a server crash for this mod.
                local errorMessage, fullErrorDetails = LoggingUtils.RunFunctionAndCatchErrors(ZombieEngineerManager.ManageZombieEngineer, zombieEngineer, currentTick)
                if errorMessage ~= nil then
                    LoggingUtils.LogPrintError(errorMessage, true)
                end
                if fullErrorDetails ~= nil then
                    LoggingUtils.ModLog(fullErrorDetails, false)
                end
            else
                -- Testing so hard errors are fine.
                ZombieEngineerManager.ManageZombieEngineer(zombieEngineer, currentTick)
            end
        end
    end
end

---@param zombieEngineer ZombieEngineer
---@param currentTick uint
ZombieEngineerManager.ManageZombieEngineer = function(zombieEngineer, currentTick)
    if not ZombieEngineerManager.ValidateZombie(zombieEngineer) then return end


    local zombieCurrentPosition = zombieEngineer.entity.position

    -- FUTURE ZOMBIE PATHING: if we have a path to something and its moved, then we need to get a new path. As We might need to attack something new in the way. Check the targets position and our distance from it. So just update path if its moved significantly. Keep on moving on the old path until the new path request returns.
    if zombieEngineer.distractionTarget ~= nil then
        ZombieEngineerManager.ValidateDistractionTarget(zombieEngineer, zombieCurrentPosition)
    end
    if zombieEngineer.distractionTarget == nil then
        ZombieEngineerManager.FindDistractionTarget(zombieEngineer, zombieCurrentPosition)
    end
    if zombieEngineer.distractionTarget ~= nil then
        ZombieEngineerManager.AttackTowardsDistractionTarget(zombieEngineer, zombieCurrentPosition)
        return
    end

    -- FUTURE ZOMBIE PATHING: clear targets when others are set.
    -- FUTURE ZOMBIE PATHING: this logic isn't completely fleshed out.
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
        --FUTURE ZOMBIE PATHING
    else
        LoggingUtils.PrintError("Zombie is in un-recognised state '" .. zombieEngineer.state .. "' here: " .. LoggingUtils.MakeGpsRichText_Entity(zombieEngineer.entity))
        if global.debugSettings.testing then error("Zombie is in un-recognised state") end
        return
    end
end


---@param zombieEngineer ZombieEngineer
---@return boolean
ZombieEngineerManager.ValidateZombie = function(zombieEngineer)
    local zombieValidated = true
    if zombieEngineer.entity == nil or (not zombieEngineer.entity.valid) then
        zombieValidated = false
    end

    if zombieValidated then return true end

    -- Invalid Zombie.
    LoggingUtils.PrintError("Zombie number '" .. zombieEngineer.id .. "' raised from '" .. zombieEngineer.sourceName .. "' failed validation and so has been cancelled")
    if global.debugSettings.testing then error("Zombie failed validation") end
    ZombieEngineerManager.ZombieEntityRemoved(zombieEngineer)
    return false
end

-- We have a distraction target already, is it still valid?
---@param zombieEngineer ZombieEngineer
---@param zombieCurrentPosition MapPosition
ZombieEngineerManager.ValidateDistractionTarget = function(zombieEngineer, zombieCurrentPosition)
    -- zombieEngineer.distractionTarget is not nil if this function run.

    --FUTURE ZOMBIE PATHING: we only need to check this every second or two.

    if not zombieEngineer.distractionTarget.valid then
        zombieEngineer.distractionTarget = nil
        zombieEngineer.action = ZOMBIE_ENGINEER_ACTION.idle
        return
    end

    if PositionUtils.GetDistance(zombieCurrentPosition, zombieEngineer.distractionTarget.position) > global.ZombieEngineerManager.Settings.distractionRange then
        zombieEngineer.distractionTarget = nil
        zombieEngineer.action = ZOMBIE_ENGINEER_ACTION.idle
        zombieEngineer.path = nil
        return
    end
end

-- We don't have a distraction target so see if we can find one.
---@param zombieEngineer ZombieEngineer
---@param zombieCurrentPosition MapPosition
ZombieEngineerManager.FindDistractionTarget = function(zombieEngineer, zombieCurrentPosition)
    -- FUTURE ZOMBIE PATHING: we only need to check this every second or two, or when we have just lost our current distraction target.

    local nearestTargetEntity, nearestTargetDistance ---@type LuaEntity, double
    local thisDistance ---@type double

    local nearbyCharacter = zombieEngineer.surface.find_entities_filtered({ type = "character", position = zombieCurrentPosition, radius = global.ZombieEngineerManager.Settings.distractionRange, force = global.ZombieEngineerManager.playerForces })
    for _, characterEntity in pairs(nearbyCharacter) do
        thisDistance = PositionUtils.GetDistance(zombieCurrentPosition, characterEntity.position)
        if nearestTargetDistance == nil or thisDistance < nearestTargetDistance then
            nearestTargetEntity = characterEntity
            nearestTargetDistance = thisDistance
        end
    end

    local nearbyVehicles = zombieEngineer.surface.find_entities_filtered({ type = EntityTypeGroups.NonRailVehicles_List, position = zombieCurrentPosition, radius = global.ZombieEngineerManager.Settings.distractionRange, force = global.ZombieEngineerManager.playerForces })
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
        zombieEngineer.action = ZOMBIE_ENGINEER_ACTION.idle
        zombieEngineer.pathBlockingTarget = nil
    end
end

---@param zombieEngineer ZombieEngineer
---@param zombieCurrentPosition MapPosition
ZombieEngineerManager.AttackTowardsDistractionTarget = function(zombieEngineer, zombieCurrentPosition)
    -- zombieEngineer.distractionTarget is not nil if this function was reached.

    if zombieEngineer.action == ZOMBIE_ENGINEER_ACTION.idle then
        ZombieEngineerManager.RequestPath(zombieEngineer, zombieEngineer.distractionTarget, zombieEngineer.distractionTarget.position, zombieCurrentPosition, ZOMBIE_ENGINEER_PATHFINDER_PURPOSE.distraction)
        return
    end

    if zombieEngineer.action == ZOMBIE_ENGINEER_ACTION.findingPath then
        return
    end

    if zombieEngineer.action == ZOMBIE_ENGINEER_ACTION.chasingDistraction then
        -- We have a path here and are doing commands to follow it.
        if zombieEngineer.entity.command.type == defines.command.wander then
            local reachedEndOfPath = ZombieEngineerManager.AttackCommandToNextTargetInPath(zombieEngineer)
            if not reachedEndOfPath then return end

            if PositionUtils.GetDistance(zombieCurrentPosition, zombieEngineer.distractionTarget.position) < 3 then
                ZombieEngineerManager.SetAttackCommandOnTarget(zombieEngineer, zombieEngineer.distractionTarget)
            else
                error("not handled the target moving yet")
            end
        end
        return
    end

    LoggingUtils.PrintError("Zombie is in un-recognised action '" .. zombieEngineer.action .. "' while attacking towards spawn, here: " .. LoggingUtils.MakeGpsRichText_Entity(zombieEngineer.entity))
    if global.debugSettings.testing then error("Zombie is in un-recognised action") end
end

---@param zombieEngineer ZombieEngineer
ZombieEngineerManager.ValidatePathBlockingTarget = function(zombieEngineer)
end

---@param zombieEngineer ZombieEngineer
ZombieEngineerManager.FindRampageTarget = function(zombieEngineer)
end

---@param zombieEngineer ZombieEngineer
ZombieEngineerManager.AttackPathBlockingTarget = function(zombieEngineer)
end

--- Get a path that ignores all player entities using a custom collision mask on everything with player-layer other than player buildable entities. Will also avoid water.
--- We'd then have to check for all entities collision boxes on this path and target the first one.
---@param zombieEngineer ZombieEngineer
---@param targetEntity? LuaEntity
---@param targetPosition MapPosition
---@param zombieCurrentPosition MapPosition
---@param pathPurpose ZombieEngineer_PathfinderPurpose
ZombieEngineerManager.RequestPath = function(zombieEngineer, targetEntity, targetPosition, zombieCurrentPosition, pathPurpose)
    local pathRequestId = zombieEngineer.surface.request_path({ bounding_box = { { -0.5, -0.5 }, { 0.5, 0.5 } }, collision_mask = global.ZombieEngineerManager.zombiePathingCollisionMask, start = zombieCurrentPosition, goal = targetPosition, force = global.ZombieEngineerManager.zombieForce, radius = 1, pathfind_flags = { cache = false, no_break = true }, can_open_gates = false, path_resolution_modifier = 0, entity_to_ignore = targetEntity })
    global.ZombieEngineerManager.requestedPaths[pathRequestId] = { pathRequestId = pathRequestId, zombieEngineer = zombieEngineer, sourcePosition = zombieCurrentPosition, targetEntity = targetEntity, targetPosition = targetPosition, pathPurpose = pathPurpose }
    zombieEngineer.action = ZOMBIE_ENGINEER_ACTION.findingPath
end

---@param eventData EventData.on_script_path_request_finished
ZombieEngineerManager.OnScriptPathRequestFinished = function(eventData)
    local pathRequestId = eventData.id
    local pathRequestDetails = global.ZombieEngineerManager.requestedPaths[pathRequestId]
    if pathRequestDetails == nil then return end
    local zombieEngineer = pathRequestDetails.zombieEngineer
    global.ZombieEngineerManager.requestedPaths[pathRequestId] = nil

    if zombieEngineer.state == ZOMBIE_ENGINEER_STATE.dead then return end

    if eventData.try_again_later then
        -- Pathfinder was busy.
        ZombieEngineerManager.RequestPathFailed(zombieEngineer, pathRequestDetails)
        return
    end
    local path = eventData.path
    if path == nil then
        -- No path was found between the 2 points.
        ZombieEngineerManager.RequestPathFailed(zombieEngineer, pathRequestDetails)
        return
    end

    if global.debugSettings.testing then
        if zombieEngineer.debug_pathWaypointRenderIds ~= nil then
            for _, renderId in pairs(zombieEngineer.debug_pathWaypointRenderIds) do
                rendering.destroy(renderId)
            end
        end
        zombieEngineer.debug_pathWaypointRenderIds = LoggingUtils.DrawPath(path, game.surfaces[1], nil, nil, "start", "end")
    end

    -- Record the result if the purpose of the path is for the current most critical target the zombie has. If the path takes a few moments to get then target could have been replaced by something else since, or worst a higher priority target.
    if pathRequestDetails.pathPurpose == ZOMBIE_ENGINEER_PATHFINDER_PURPOSE.distraction then
        if pathRequestDetails.targetEntity == zombieEngineer.distractionTarget then
            zombieEngineer.path = path
            zombieEngineer.attackingNodeInPath = 1
            zombieEngineer.action = ZOMBIE_ENGINEER_ACTION.chasingDistraction
        else
            -- Is a path to an old target so just ignore.
        end
        return
    else
        error("unhandled so far")
    end
end

--- Handle the pathing request failing and update the zombie object's action so that the main state loop can retry/handle the next action from fresh.
---@param zombieEngineer ZombieEngineer
---@param pathRequestDetails ZombieEngineer_PathRequestDetails
ZombieEngineerManager.RequestPathFailed = function(zombieEngineer, pathRequestDetails)
    LoggingUtils.PrintError("Zombie failed to find a path from here: " .. LoggingUtils.MakeGpsRichText(pathRequestDetails.sourcePosition.x, pathRequestDetails.sourcePosition.y, zombieEngineer.surface.name) .. "   to the target that was here: " .. LoggingUtils.MakeGpsRichText(pathRequestDetails.targetPosition.x, pathRequestDetails.targetPosition.y, zombieEngineer.surface.name))
    zombieEngineer.action = ZOMBIE_ENGINEER_ACTION.idle
end

---@param zombieEngineer ZombieEngineer
---@return boolean reachedEndOfPath
ZombieEngineerManager.AttackCommandToNextTargetInPath = function(zombieEngineer)
    -- Look over waypoints to find next blocking target.
    local pathWaypoint ---@type PathfinderWaypoint
    for pathWaypoint_index = zombieEngineer.attackingNodeInPath, #zombieEngineer.path do
        pathWaypoint = zombieEngineer.path[pathWaypoint_index]
        local targets = zombieEngineer.surface.find_entities_filtered({ position = pathWaypoint.position, collision_mask = global.ZombieEngineerManager.zombieEntityCollisionMask, force = global.ZombieEngineerManager.playerForces, limit = 1 })
        local target = targets[1]
        if target ~= nil then
            ZombieEngineerManager.SetAttackCommandOnTarget(zombieEngineer, target)
            zombieEngineer.attackingNodeInPath = pathWaypoint_index
            return false
        end
    end

    -- Reached end of path
    return true
end

---@param zombieEngineer ZombieEngineer
---@param target LuaEntity|MapPosition
---@param color Color
---@return uint64 renderId
ZombieEngineerManager.DebugDrawLineFromZombie = function(zombieEngineer, target, color)
    return rendering.draw_line({ color = color, width = 4, from = zombieEngineer.entity, to = target, surface = zombieEngineer.surface })
end

---@param zombieEngineer ZombieEngineer
---@param target LuaEntity
ZombieEngineerManager.SetAttackCommandOnTarget = function(zombieEngineer, target)
    if global.debugSettings.testing and zombieEngineer.debug_attackCommandRenderId ~= nil then
        rendering.destroy(zombieEngineer.debug_attackCommandRenderId)
    end
    ---@diagnostic disable-next-line: missing-fields # Temporary work around until Factorio docs and FMTK updated to allow per type field specification.
    zombieEngineer.entity.set_command({ type = defines.command.attack, target = target, distraction = defines.distraction.none })
    if global.debugSettings.testing then
        zombieEngineer.debug_attackCommandRenderId = ZombieEngineerManager.DebugDrawLineFromZombie(zombieEngineer, target, Colors.red)
    end
end

---@param eventData EventData.on_entity_died
ZombieEngineerManager.OnEntityDiedZombieEngineer = function(eventData)
    local entity = eventData.entity
    if entity.name ~= "zombie_engineer-zombie_engineer" then return end

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
        corpseForce = global.ZombieEngineerManager.zombieForce
        playerIndex = nil
    end
    local inventorySize = zombieEngineer.inventory and #zombieEngineer.inventory or 0
    local corpseDirection = DirectionUtils.OrientationToNearestDirection(entity.orientation)

    ---@diagnostic disable-next-line: missing-fields # Temporary work around until Factorio docs and FMTK updated to allow per type field specification.
    local zombieCorpse = zombieEngineer.surface.create_entity({ name = "character-corpse", position = entity.position, force = corpseForce, direction = corpseDirection, inventory_size = inventorySize, player_index = playerIndex, player = sourcePlayer })

    if zombieCorpse ~= nil then
        if inventorySize > 0 then
            local corpseInventory = zombieCorpse.get_inventory(defines.inventory.character_corpse) ---@cast corpseInventory -nil
            InventoryUtils.TryMoveInventoriesLuaItemStacks(zombieEngineer.inventory, corpseInventory, true, 100)
        end
        zombieCorpse.color = corpseColor
    end

    ZombieEngineerManager.ZombieEntityRemoved(zombieEngineer)

    local zombieKiller = eventData.cause
    local zombieKillerPlayer ---@type LuaPlayer?
    if zombieKiller ~= nil then
        zombieKillerPlayer = EntityUtils.GetPlayerControllingEntity(zombieKiller, zombieKiller.type)
    end
    if zombieKillerPlayer and zombieEngineer.sourcePlayer ~= nil then
        game.print({ "message.zombie_engineer-player_killed_zombie", zombieKillerPlayer.name, zombieEngineer.sourceName })
    end
end

---@param zombieEngineer ZombieEngineer
ZombieEngineerManager.ZombieEntityRemoved = function(zombieEngineer)
    zombieEngineer.state = ZOMBIE_ENGINEER_STATE.dead
    zombieEngineer.entity = nil
    zombieEngineer.unitNumber = nil
end

return ZombieEngineerManager
