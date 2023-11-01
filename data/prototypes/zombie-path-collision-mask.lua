--[[
    We use this collision mask to find a path to our target around the things we don't want to ever attack. If something is missed then it will be excluded in the attack order done by the zombie, so at worst it will wonder around things unexpectedly. e.g. just ignore biter units entirely and we will wonder around them if they block us.

    The custom entity is just to enable easy access from the control runtime.

    I am only adding to prototypes that already have the "player-layer". This way I'm not adding new incompatibilities between things.
]]

local CollisionMaskUtil = require("__core__/lualib/collision-mask-util")

local zombieEngineerPathCollisionLayer = CollisionMaskUtil.get_first_unused_layer() --[[@as data.CollisionMaskLayer]]

---@type data.SimpleEntityPrototype
local zombieEngineerPathCollisionLayerPrototype = {
    name = "zombie_engineer-zombie_engineer_path_collision_layer",
    type = "simple-entity",
    collision_mask = { zombieEngineerPathCollisionLayer }
}

data:extend({ zombieEngineerPathCollisionLayerPrototype })
