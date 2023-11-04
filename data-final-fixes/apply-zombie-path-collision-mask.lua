local CollisionMaskUtil = require("__core__/lualib/collision-mask-util")
local PrototypeLikeLists = require("utility.helper-utils.prototype-like-lists-data-stage")

local zombieEngineerPathCollisionLayer = data.raw["simple-entity"]["zombie_engineer-zombie_engineer_path_collision_layer"].collision_mask[1]

local function AddZombiePathLayerToPrototype(prototype)
    local newMask = CollisionMaskUtil.get_mask(prototype)
    CollisionMaskUtil.add_layer(newMask, zombieEngineerPathCollisionLayer)
    prototype.collision_mask = newMask
end

-- Biters / Enemies
for _, prototype in pairs(PrototypeLikeLists.GetWormTurretLikePrototypes()) do
    AddZombiePathLayerToPrototype(prototype)
end
for _, prototype in pairs(PrototypeLikeLists.GetEnemySpawnerLikePrototypes()) do
    AddZombiePathLayerToPrototype(prototype)
end


-- Natural Environment.
for _, prototype in pairs(PrototypeLikeLists.GetMinableRockLikePrototypes()) do
    AddZombiePathLayerToPrototype(prototype)
end
for _, prototype in pairs(data.raw["tree"] --[[@as data.TreePrototype[] ]]) do
    AddZombiePathLayerToPrototype(prototype)
end

-- Tiles
for _, prototype in pairs(PrototypeLikeLists.GetBlockingWaterTileLikePrototypes()) do
    AddZombiePathLayerToPrototype(prototype)
end
for _, prototype in pairs(PrototypeLikeLists.GetVoidTileLikePrototypes()) do
    AddZombiePathLayerToPrototype(prototype)
end

--------------------------------------
--           Other Muppet Mods
--------------------------------------

-- Egg nests. This catches them all currently and avoids hard coding which is nice. Isn't terribly inter mod compatible mind.
for _, prototype in pairs(data.raw["simple-entity-with-force"] --[[@as data.SimpleEntityWithForcePrototype[] ]]) do
    if prototype.subgroup == "enemies" then
        AddZombiePathLayerToPrototype(prototype)
    end
end
