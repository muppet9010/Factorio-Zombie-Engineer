local TableUtils = require('utility.helper-utils.table-utils')

local characterPrototypeReference = data.raw["character"]["character"]

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
        cooldown = 40,
        cooldown_deviation = 0.15,
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
        animation = TableUtils.DeepCopy(characterPrototypeReference.animations[1].mining_with_tool), -- Copy the no armor animations.
        range_mode = "bounding-box-to-bounding-box"
    },
    vision_distance = 30, -- TODO: think this should be 0.
    movement_speed = 0.05,
    distance_per_frame = characterPrototypeReference.distance_per_frame,
    pollution_to_join_attack = 0,
    distraction_cooldown = 0,
    run_animation = TableUtils.DeepCopy(characterPrototypeReference.animations[1].running), -- Copy the no armor animations.
    has_belt_immunity = true,
    affected_by_tiles = true,
}

data:extend({ zombieEngineer })
