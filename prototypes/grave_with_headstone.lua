local Constants = require('constants')

-- Frequency is all copied from Biter Eggs mod blindly.

---@param multiplier double
---@param order_suffix any
---@return data.AutoplaceSpecification
local function MakeAutoplaceSettings(multiplier, order_suffix)
    local name = "enemy-zombie_engineer-grave_with_headstone"
    multiplier = multiplier * tonumber(settings.startup["zombie_engineer-gravestone_quantity"].value)
    ---@type data.AutoplacePeak
    local peak = {
        noise_layer = name,
        noise_octaves_difference = -2,
        noise_persistence = 0.9
    }

    return {
        order = "a[doodad]-a[rock]-" .. order_suffix,
        coverage = multiplier * 0.01,
        sharpness = 0.7,
        max_probability = multiplier * 0.7,
        peaks = { peak },
        force = "enemy"
    } --[[@as data.AutoplaceSpecification]]
end

---@type data.SimpleEntityWithForcePrototype
local graveWithHeadstonePrototype = {
    type = 'simple-entity-with-force',
    name = "zombie_engineer-grave_with_headstone",
    enemy_map_color = { r = 0.54, g = 0.0, b = 0.0 },
    flags = { "placeable-player", "placeable-enemy", "not-flammable", "not-repairable", "placeable-off-grid" },
    icon = Constants.AssetModName .. "/graphics/grave_with_headstone/grave_with_headstone-icon.png",
    icon_size = 155,
    max_health = 100,
    subgroup = "enemies",
    order = "b-b-k",
    collision_box = { { -0.4, -0.5 }, { 0.4, 0 } },
    selection_box = { { -0.5, -0.9 }, { 0.5, 1.5 } },
    map_generator_bounding_box = { { -0.7, -0.7 }, { 0.7, 1.7 } },
    vehicle_impact_sound = { filename = "__base__/sound/car-stone-impact.ogg", volume = 1.0 },
    render_layer = "object",
    pictures = {},
    autoplace = MakeAutoplaceSettings(0.0075, "b[zombie_engineer-grave_with_headstone]") -- This is one tenth the frequency of biter eggs.
}

---@diagnostic disable-next-line: missing-fields # Temporary work around until Factorio docs fix this API doc. Logged here: https://forums.factorio.com/viewtopic.php?f=233&t=109364
graveWithHeadstonePrototype.resistances = {
    {
        type = "fire",
        decrease = 100,
        percent = 100
    }
}

-- Make 8 graphic variations for future graphics.
-- This isn't the best way, but I don't know how to set random variations on an existing single picture prototype. TODO: find a better way in the future.
for i = 1, 10 do
    table.insert(graveWithHeadstonePrototype.pictures,
        {
            filename = Constants.AssetModName .. "/graphics/grave_with_headstone/The_man_with_no_name.png",
            width = 140,
            height = 181,
            scale = 0.5,
            shift = { 0.1, 0.3 }
        } --[[@as data.Sprite ]]
    )
end

---@type data.NoiseLayer
local graveWithHeadstoneNoiseLayerPrototype =
{
    type = "noise-layer",
    name = "enemy-zombie_engineer-grave_with_headstone"
}


data:extend({ graveWithHeadstonePrototype, graveWithHeadstoneNoiseLayerPrototype })
