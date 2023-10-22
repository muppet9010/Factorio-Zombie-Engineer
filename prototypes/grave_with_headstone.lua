--[[
    This is all temporary.
    If possible have the graves placed by map generator. Then we can have the map_generator_bounding_box for the whole image, but just the headstone as the collision box.
]]

local TableUtils = require('utility.helper-utils.table-utils')
local Constants = require('constants')

local gravestone1 = {
    type = 'simple-entity',
    name = "Zombie_Engineer-grave_with_headstone_1",
    pictures = {
        {
            layers = {
                {
                    filename = Constants.AssetModName .. "/graphics/grave_with_headstone/Test1a.png",
                    width = 140,
                    height = 181,
                    scale = 0.5,
                    shift = { 0, -0.5 }
                },
                {
                    filename = Constants.AssetModName .. "/graphics/grave_with_headstone/Test1b.png",
                    width = 140,
                    height = 181,
                    scale = 0.5,
                    shift = { 0, -0.5 }
                }
            }
        }
    },
    count_as_rock_for_filtered_deconstruction = true,
    collision_box = { { -0.5, -1 }, { 0.5, 1 } },
    flags = { "placeable-off-grid" }
}

local gravestone2 = TableUtils.DeepCopy(gravestone1)
gravestone2.name = "Zombie_Engineer-grave_with_headstone_2"
gravestone2.picture = {
    filename = Constants.AssetModName .. "/graphics/grave_with_headstone/Test2.png",
    width = 140,
    height = 181,
    scale = 0.5
}

local gravestone3 = TableUtils.DeepCopy(gravestone1)
gravestone3.name = "Zombie_Engineer-grave_with_headstone_3"
gravestone3.pictures = {
    {
        layers = {
            {
                filename = Constants.AssetModName .. "/graphics/grave_with_headstone/Test1a.png",
                width = 140,
                height = 181,
                scale = 0.5
            } --[[,
                {
                    filename = Constants.AssetModName .. "/graphics/grave_with_headstone/Test1b.png",
                    width = 140,
                    height = 181,
                    scale = 0.5
                }]]
        }
    }
}

local gravestone4 = TableUtils.DeepCopy(gravestone1)
gravestone4.name = "Zombie_Engineer-grave_with_headstone_4"
gravestone4.pictures = {
    {
        layers = {
            --[[{
                    filename = Constants.AssetModName .. "/graphics/grave_with_headstone/Test1a.png",
                    width = 140,
                    height = 181,
                    scale = 0.5
                },]]
            {
                filename = Constants.AssetModName .. "/graphics/grave_with_headstone/Test1b.png",
                width = 140,
                height = 181,
                scale = 0.5
            }
        }
    }
}

-- These values are an experiment that wasn't tested.
local gravestone1longer = {
    type = 'simple-entity',
    name = "Zombie_Engineer-grave_with_headstone_1_longer",
    picture = {
        filename = Constants.AssetModName .. "/graphics/grave_with_headstone/LongerTest1.png",
        width = 72,
        height = 158,
        scale = 0.5,
        shift = { 0, 1 }
    },
    count_as_rock_for_filtered_deconstruction = true,
    collision_box = { { -0.5, -0.5 }, { 0.5, 0 } },
    map_generator_bounding_box = { { -0.5, -0.5 }, { 0.5, 1.8 } },
    flags = { "placeable-off-grid" }
}

data:extend({ gravestone1, gravestone2, gravestone3, gravestone4, gravestone1longer })
