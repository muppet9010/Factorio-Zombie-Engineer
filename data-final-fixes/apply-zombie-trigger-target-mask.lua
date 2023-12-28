--------------------------------------
-- Set player turret types to ignore zombies. This is a best guess.
--------------------------------------

if settings.startup["zombie_engineer-turrets_ignore_zombies"].value --[[@as boolean]] then
    ---@param turretPrototype data.TurretPrototype
    local SetTurretToIgnoreZombie = function(turretPrototype)
        if turretPrototype.ignore_target_mask == nil then
            turretPrototype.ignore_target_mask = { "zombie_engineer-zombie_engineer" }
        else
            turretPrototype.ignore_target_mask[#turretPrototype.ignore_target_mask + 1] = "zombie_engineer-zombie_engineer"
        end
    end

    for _, prototype in pairs(data.raw["ammo-turret"] --[[@as data.AmmoTurretPrototype[] ]]) do
        if prototype.subgroup ~= "enemies" then
            SetTurretToIgnoreZombie(prototype)
        end
    end
    for _, prototype in pairs(data.raw["electric-turret"] --[[@as data.ElectricTurretPrototype[] ]]) do
        if prototype.subgroup ~= "enemies" then
            SetTurretToIgnoreZombie(prototype)
        end
    end
    for _, prototype in pairs(data.raw["fluid-turret"] --[[@as data.FluidTurretPrototype[] ]]) do
        if prototype.subgroup ~= "enemies" then
            SetTurretToIgnoreZombie(prototype)
        end
    end
end

--------------------------------------
-- Add every non-zombie entity to have the non-zombie trigger target mask and make slowdown capsules affect just them.
--------------------------------------

-- Update the base game slowdown capsule sticker creation effect.
(data.raw["projectile"]["slowdown-capsule"] --[[@as data.ProjectilePrototype]]).action[2].trigger_target_mask = { "zombie_engineer-not_zombie_engineer" }

-- Add flag to units.
---@param entityPrototype data.EntityPrototype
---@param isGroundUnit boolean
local AddNonZombieTriggerMaskToPrototype = function(entityPrototype, isGroundUnit)
    if entityPrototype.trigger_target_mask == nil then
        entityPrototype.trigger_target_mask = { "common" }
        if isGroundUnit then
            entityPrototype.trigger_target_mask[#entityPrototype.trigger_target_mask + 1] = "ground-unit"
        end
    end
    entityPrototype.trigger_target_mask[#entityPrototype.trigger_target_mask + 1] = "zombie_engineer-not_zombie_engineer"
end

for _, prototype in pairs(data.raw["unit"] --[[@as data.UnitPrototype[] ]]) do
    if prototype.name ~= "zombie_engineer-zombie_engineer" then
        AddNonZombieTriggerMaskToPrototype(prototype, true)
    end
end
for _, prototype in pairs(data.raw["car"] --[[@as data.CarPrototype[] ]]) do
    AddNonZombieTriggerMaskToPrototype(prototype, true)
end
for _, prototype in pairs(data.raw["character"] --[[@as data.CharacterPrototype[] ]]) do
    AddNonZombieTriggerMaskToPrototype(prototype, true)
end
-- Spider vehicles and trains aren't affected by slowdown affects.
