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
            order = "1002"
        }
    }
)
