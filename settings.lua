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
            order = "1001"
        }
    }
)
