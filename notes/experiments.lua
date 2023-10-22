local LoggingUtils = require("utility.helper-utils.logging-utils")

---@param zombieEngineer ZombieEngineer
function PathingTest_Request(zombieEngineer)
    local turret = zombieEngineer.surface.find_entities_filtered({ name = "gun-turret", limit = 1 })[1]

    -- We want to find a rough path to our target going through some player entities rather than always around them when they are in the way. Basically, we want to find the next major obstacle entity to smash through. The low path accuracy helps with this smashing through stuff.
    -- A larger collision_box than a character seems to help make it go through things.
    -- We can then try and find the first thing that needs destroying by doing an entity search on that location and attack move the zombie at it. With repeated checks that it can path from current location to this target without needing to destroy anything new. With anything found becoming the new target.
    local pathRequestId = zombieEngineer.surface.request_path { bounding_box = { { -0.5, -0.5 }, { 0.5, 0.5 } }, collision_mask = { "player-layer" }, start = zombieEngineer.entity.position, goal = turret.position, force = turret.force, radius = 2, pathfind_flags = { allow_destroy_friendly_entities = true, cache = false, no_break = true }, can_open_gates = false, path_resolution_modifier = -1, entity_to_ignore = turret }
    local x = 1

    -- Another way is to get a path that ignores all player entities using a custom collision mask on everything with player-layer other than player buildable entities. Will also avoid water. As we are only adding it to some of the things with player-layer we wouldn't be expanding the overlap in collision masks, so this won't break anything.
    -- This concept here just uses the resource-layer, as his ignores entities, but respects water. However, we also want to avoid biter bases and worms, plus probably trees and rocks?
    -- We'd then have to check for all entities collision boxes on this path and target the first one.
    local pathRequestId2 = zombieEngineer.surface.request_path { bounding_box = { { -0.5, -0.5 }, { 0.5, 0.5 } }, collision_mask = { "resource-layer" }, start = zombieEngineer.entity.position, goal = turret.position, force = zombieEngineer.entity.force, radius = 1, pathfind_flags = { cache = false, no_break = true }, can_open_gates = false, path_resolution_modifier = 0, entity_to_ignore = turret }
    local x2 = 1
end

---@param eventData EventData.on_script_path_request_finished
PathingTest_Draw = function(eventData)
    local path = eventData.path
    if eventData.path == nil then
        game.print("no path found")
        return
    end
    LoggingUtils.DrawPath(eventData.path, game.surfaces[1], nil, nil, "start", "end")
end
