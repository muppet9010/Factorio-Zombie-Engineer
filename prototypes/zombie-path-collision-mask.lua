--[[
    We use this collision mask to find a path to our target around the things we don't want to ever attack. If something is missed then it will be excluded in the attack order done by the zombie, so at worst it will wonder around things unexpectedly. e.g. just ignore biter units entirely and we will wonder around them if they block us.

    The custom entity is just to enable easy access from the control runtime.

    I am only adding to prototypes that already have the "player-layer". This way I'm not adding new incompatibilities between things.
]]

local CollisionMaskUtil = require("__core__/lualib/collision-mask-util")
local TableUtils = require("utility.helper-utils.table-utils")

local zombieEngineerPathCollisionLayer = CollisionMaskUtil.get_first_unused_layer() --[[@as data.CollisionMaskLayer]]

data:extend({ {
    name = "zombie_engineer-zombie_engineer_path_collision_layer",
    type = "simple-entity",
    collision_mask = { zombieEngineerPathCollisionLayer }
} --[[@as data.SimpleEntityPrototype]] })

local function AddZombiePathLayerToPrototype(prototype)
    local newMask = CollisionMaskUtil.get_mask(prototype)
    CollisionMaskUtil.add_layer(newMask, zombieEngineerPathCollisionLayer)
    prototype.collision_mask = newMask
end

--------------------------------------
--           Biters
--------------------------------------

-- Add to Biter Worms. This is a best guess.
for _, prototype in pairs(data.raw["turret"] --[[@as data.TurretPrototype[] ]]) do
    if prototype.subgroup == "enemies" then
        AddZombiePathLayerToPrototype(prototype)
    end
end

-- Add to Biter Spawners. This is a best guess.
for _, prototype in pairs(data.raw["unit-spawner"] --[[@as data.EnemySpawnerPrototype[] ]]) do
    if prototype.subgroup == "enemies" then
        AddZombiePathLayerToPrototype(prototype)
    end
end

--------------------------------------
--           Natural Environment.
--------------------------------------

-- Add to rocks and similar things.
for _, prototype in pairs(data.raw["simple-entity"] --[[@as data.SimpleEntityPrototype[] ]]) do
    if prototype.count_as_rock_for_filtered_deconstruction == true then
        AddZombiePathLayerToPrototype(prototype)
    end
end

-- Add to all trees rocks. Best guess.
for _, prototype in pairs(data.raw["tree"] --[[@as data.TreePrototype[] ]]) do
    AddZombiePathLayerToPrototype(prototype)
end

--------------------------------------
--           Tiles
--------------------------------------

-- Water types. Best guess. Need to exclude the shallow waters, hence check of collision masks.
for _, prototype in pairs(data.raw["tile"] --[[@as data.TilePrototype[] ]]) do
    if prototype.draw_in_water_layer == true and TableUtils.GetTableKeyWithValue(prototype.collision_mask, "player-layer", false) ~= nil then
        local x = TableUtils.GetTableKeyWithValue(prototype.collision_mask, "player-layer", false)
        AddZombiePathLayerToPrototype(prototype)
    end
end

-- Void types.
for _, prototype in pairs(data.raw["tile"] --[[@as data.TilePrototype[] ]]) do
    if prototype.layer_group == "zero" then
        AddZombiePathLayerToPrototype(prototype)
    end
end

--------------------------------------
--           Other Muppet Mods
--------------------------------------

-- Egg nests. This catches them all currently and avoids hard coding which is nice.
for _, prototype in pairs(data.raw["simple-entity-with-force"] --[[@as data.SimpleEntityWithForcePrototype[] ]]) do
    if prototype.subgroup == "enemies" then
        AddZombiePathLayerToPrototype(prototype)
    end
end

return zombieEngineerPathCollisionLayer
