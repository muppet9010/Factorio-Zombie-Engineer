local TableUtils = require('utility.helper-utils.table-utils')

local characterPrototypeReference = data.raw["character"]["character"]

local meleeAttackRawDuration = 40
local meleeAttackAnimation = TableUtils.DeepCopy(characterPrototypeReference.animations[1].mining_with_tool) ---@type data.RotatedAnimation # Copy the no armor animations. Is a table of layers of data.RotatedAnimation.
-- When multiple sequential attacks are made we need to have the attack animations run smoothly into each other. As otherwise the zombie returns to the running animation, as units don't have an idle animation like characters do.
for _, layer in pairs(meleeAttackAnimation.layers) do
    -- This is how many frames are played per tick, so higher is faster.
    layer.animation_speed = (layer.frame_count / meleeAttackRawDuration)
    layer.hr_version.animation_speed = (layer.hr_version.frame_count / meleeAttackRawDuration)
end

---@type data.UnitPrototype
local zombieEngineer = {
    type = "unit",
    name = "Zombie_Engineer-zombie_engineer",
    icon = "__core__/graphics/icons/entity/character.png",
    icon_size = 64,
    icon_mipmaps = 4,
    flags = { "placeable-player", "placeable-enemy", "placeable-off-grid", "not-repairable", "breaths-air" },
    max_health = 1000,
    order = "z-a-a",
    subgroup = "enemies",
    resistances = nil,
    healing_per_tick = 0.1,
    collision_box = { { -0.2, -0.2 }, { 0.2, 0.2 } },
    selection_box = { { -0.4, -0.7 }, { 0.4, 0.4 } },
    damaged_trigger_effect = {
        type = "create-entity",
        entity_name = "enemy-damaged-explosion",
        offset_deviation = { { -0.5, -0.5 }, { 0.5, 0.5 } },
        offsets = { { 0, 0 } },
        damage_type_filters = "fire"
    },
    attack_parameters = {
        type = "projectile",
        range = 0.5,
        cooldown = meleeAttackRawDuration,
        cooldown_deviation = 0,
        ammo_type = {
            category = "melee",
            target_type = "entity",
            action =
            {
                type = "direct",
                action_delivery =
                {
                    type = "instant",
                    target_effects =
                    {
                        type = "damage",
                        damage = { amount = 100, type = "physical" }
                    }
                }
            }
        },
        animation = meleeAttackAnimation,
        range_mode = "bounding-box-to-bounding-box"
    },
    vision_distance = 0, -- Zombies won't ever auto target anything.
    movement_speed = 0.05,
    distance_per_frame = characterPrototypeReference.distance_per_frame,
    pollution_to_join_attack = 0,
    distraction_cooldown = 0,
    run_animation = TableUtils.DeepCopy(characterPrototypeReference.animations[1].running), -- Copy the no armor animations.
    has_belt_immunity = true,
    affected_by_tiles = true,
}

data:extend({ zombieEngineer })
