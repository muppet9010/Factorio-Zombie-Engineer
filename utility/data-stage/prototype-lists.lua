--[[
    Functions to get a list of all the prototypes that are like a general concept.
    A centralised location for base game criteria expanded for modded extras as found.
    For use in the data stage.
]]
--

local TableUtils = require("utility.helper-utils.table-utils")

local PrototypeLikeLists = {} ---@class Utility_PrototypeLikeLists

---@return data.TurretPrototype[]
PrototypeLikeLists.GetWormTurretLikePrototypes = function()
    local results = {} ---@type data.TurretPrototype[]
    for _, prototype in pairs(data.raw["turret"] --[[@as data.TurretPrototype[] ]]) do
        if prototype.subgroup == "enemies" then
            results[#results + 1] = prototype
        end
    end
    return results
end

---@return data.EnemySpawnerPrototype[]
PrototypeLikeLists.GetEnemySpawnerLikePrototypes = function()
    local results = {} ---@type data.EnemySpawnerPrototype[]
    for _, prototype in pairs(data.raw["unit-spawner"] --[[@as data.EnemySpawnerPrototype[] ]]) do
        if prototype.subgroup == "enemies" then
            results[#results + 1] = prototype
        end
    end
    return results
end

---@return data.SimpleEntityPrototype[]
PrototypeLikeLists.GetMinableRockLikePrototypes = function()
    local results = {} ---@type data.SimpleEntityPrototype[]
    for _, prototype in pairs(data.raw["simple-entity"] --[[@as data.SimpleEntityPrototype[] ]]) do
        if prototype.count_as_rock_for_filtered_deconstruction == true then
            results[#results + 1] = prototype
        end
    end
    return results
end

--[[
    Water tiles can be detected in a number of ways. I used to use the collision_mask of 'water-tile', but other tiles can have this also. So using the `draw_in_water_layer == true` seems more intentional.
]]
---@return data.TilePrototype[]
PrototypeLikeLists.GetAllWaterTileLikePrototypes = function()
    local results = {} ---@type data.TilePrototype[]
    for _, prototype in pairs(data.raw["simple-entity"] --[[@as data.TilePrototype[] ]]) do
        if prototype.draw_in_water_layer == true then
            results[#results + 1] = prototype
        end
    end
    return results
end

---@return data.TilePrototype[]
PrototypeLikeLists.GetBlockingWaterTileLikePrototypes = function()
    local results = {} ---@type data.TilePrototype[]
    for _, prototype in pairs(data.raw["simple-entity"] --[[@as data.TilePrototype[] ]]) do
        -- If it blocks the player its blocking water.
        if prototype.draw_in_water_layer == true and TableUtils.GetTableKeyWithValue(prototype.collision_mask, "player-layer", false) ~= nil then
            results[#results + 1] = prototype
        end
    end
    return results
end

---@return data.TilePrototype[]
PrototypeLikeLists.GetCrossableWaterTileLikePrototypes = function()
    local results = {} ---@type data.TilePrototype[]
    for _, prototype in pairs(data.raw["simple-entity"] --[[@as data.TilePrototype[] ]]) do
        -- If it doesn't blocks the player its crossable water.
        if prototype.draw_in_water_layer == true and TableUtils.GetTableKeyWithValue(prototype.collision_mask, "player-layer", false) == nil then
            results[#results + 1] = prototype
        end
    end
    return results
end

---@return data.TilePrototype[]
PrototypeLikeLists.GetVoidTileLikePrototypes = function()
    local results = {} ---@type data.TilePrototype[]
    for _, prototype in pairs(data.raw["simple-entity"] --[[@as data.TilePrototype[] ]]) do
        if prototype.layer_group == "zero" then
            results[#results + 1] = prototype
        end
    end
    return results
end

return PrototypeLikeLists
