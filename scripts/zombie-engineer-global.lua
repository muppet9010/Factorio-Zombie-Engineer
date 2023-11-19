local ZombieEngineerGlobal = {} ---@class Class_ZombieEngineerGlobal

ZombieEngineerGlobal.CreateGlobals = function()
    global.ZombieEngineerGlobal = global.ZombieEngineerGlobal or {} ---@class Global_ZombieEngineerGlobal

    global.ZombieEngineerGlobal.zombiePathingCollisionMask = global.ZombieEngineerGlobal.zombiePathingCollisionMask ---@type data.CollisionMask # Obtained as part of OnStartup.
    global.ZombieEngineerGlobal.zombieEntityCollisionMask = global.ZombieEngineerGlobal.zombieEntityCollisionMask ---@type data.CollisionMask # Obtained as part of OnStartup.

    global.ZombieEngineerGlobal.zombieForce = global.ZombieEngineerGlobal.zombieForce ---@type LuaForce # Created as part of OnStartup if required.
    global.ZombieEngineerGlobal.playerForces = global.ZombieEngineerGlobal.playerForces ---@type LuaForce[]

    global.ZombieEngineerGlobal.Settings = {
        zombieEntityColor = { r = 0.100, g = 0.040, b = 0.0, a = 0.7 }, ---@type Color
        zombieTextColor = { r = 0.5, g = 0.5, b = 0.5, a = 0.7 } ---@type Color # Dark color isn't very readable.
    }
end

ZombieEngineerGlobal.OnLoad = function()
end

ZombieEngineerGlobal.OnStartup = function()
    -- Can't hardcode these, so just always obtain them from the game state.
    global.ZombieEngineerGlobal.zombiePathingCollisionMask = game.entity_prototypes["zombie_engineer-zombie_engineer_path_collision_layer"].collision_mask
    global.ZombieEngineerGlobal.zombieEntityCollisionMask = game.entity_prototypes["zombie_engineer-zombie_engineer"].collision_mask

    global.ZombieEngineerGlobal.playerForces = { game.forces["player"] }
    if global.ZombieEngineerGlobal.zombieForce == nil then
        global.ZombieEngineerGlobal.zombieForce = ZombieEngineerGlobal.CreateZombieForce()
    end
end

---@param event EventData.on_runtime_mod_setting_changed|nil # nil value when called from OnStartup (on_init & on_configuration_changed)
ZombieEngineerGlobal.OnSettingChanged = function(event)
end

---@return LuaForce
ZombieEngineerGlobal.CreateZombieForce = function()
    local zombieForce = game.create_force("zombie_engineer-zombie_engineer")

    -- Make the zombie and biters be friends.
    local biterForce = game.forces["enemy"]
    zombieForce.set_friend(biterForce, true)
    biterForce.set_friend(zombieForce, true)

    -- Set the zombie color as a dark brown.
    zombieForce.custom_color = global.ZombieEngineerGlobal.Settings.zombieEntityColor -- Used by the zombie engineer unit as its runtime tint color.

    return zombieForce
end

return ZombieEngineerGlobal
