local Constants = require('constants')

---@type data.SimpleEntityPrototype
local graveWithHeadstone = {
    type = 'simple-entity',
    name = "zombie_engineer-grave_with_headstone",
    pictures = {},
    collision_box = { { -0.4, -0.5 }, { 0.4, 0 } },
    map_generator_bounding_box = { { -0.7, -0.7 }, { 0.7, 1.7 } },
    selection_box = { { -0.7, -0.9 }, { 0.5, 1.5 } },
    flags = { "placeable-off-grid" }
}

for _, imageName in pairs({ "Bilbo", "BTG", "Fox", "Huff", "JD", "Muppet", "Sorahn" }) do
    table.insert(graveWithHeadstone.pictures,
        {
            filename = Constants.AssetModName .. "/graphics/grave_with_headstone/" .. imageName .. ".png",
            width = 140,
            height = 180,
            scale = 0.5,
            shift = { 0.1, 0.3 }
        } --[[@as data.SpriteVariations ]]
    )
end

data:extend({ graveWithHeadstone })
