local LineToBodySettingsValues = require("common.line-to-body-settings-values")

data:extend(
    {
        {
            name = "zombie_engineer-gravestone_quantity",
            type = "double-setting",
            default_value = 2,
            minimum_value = 0,
            maximum_value = 100,
            setting_type = "startup",
            order = "1000"
        },
        {
            name = "zombie_engineer-zombie_unarmored_health",
            type = "int-setting",
            default_value = 800,
            minimum_value = 1,
            setting_type = "startup",
            order = "1001"
        },
        {
            name = "zombie_engineer-zombie_movement_speed",
            type = "double-setting",
            default_value = 0.05,
            minimum_value = 0.001,
            setting_type = "startup",
            order = "1002"
        },
        {
            name = "zombie_engineer-zombie_melee_attack_damage",
            type = "int-setting",
            default_value = 100,
            minimum_value = 1,
            setting_type = "startup",
            order = "1003"
        },
        {
            name = "zombie_engineer-turrets_ignore_zombies",
            type = "bool-setting",
            default_value = true,
            setting_type = "startup",
            order = "1004"
        }
    }
)

data:extend(
    {
        {
            name = "zombie_engineer-zombie_names",
            type = "string-setting",
            default_value = "",
            allow_blank = true,
            setting_type = "runtime-global",
            order = "1000"
        }
    }
)

data:extend(
    {
        {
            name = "zombie_engineer-line_to_body_thickness",
            type = "double-setting",
            default_value = 2,
            minimum_value = 0,
            setting_type = "runtime-per-user",
            order = "1000"
        },
        {
            name = "zombie_engineer-line_to_body_color_selection_type",
            type = "string-setting",
            default_value = LineToBodySettingsValues.ZOMBIE_ENGINEER_LINE_COLOR_SELECTION_TYPE.player,
            allowed_values = LineToBodySettingsValues.ZOMBIE_ENGINEER_LINE_COLOR_SELECTION_TYPE,
            allow_blank = false,
            setting_type = "runtime-per-user",
            order = "1001"
        },
        {
            name = "zombie_engineer-line_to_body_color_selector_value",
            type = "color-setting",
            default_value = { r = 0, g = 0, b = 0, a = 1 },
            setting_type = "runtime-per-user",
            order = "1002",
            localised_description = { "mod-setting-description.zombie_engineer-line_to_body_color_selector_value", { "mod-setting-name.zombie_engineer-line_to_body_color_selection_type" }, { "string-mod-setting.zombie_engineer-line_to_body_color_selection_type-custom" } }
        }
    }
)
