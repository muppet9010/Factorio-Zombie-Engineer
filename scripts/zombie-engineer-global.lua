local ZombieEngineerGlobal = {} ---@class Class_ZombieEngineerGlobal

ZombieEngineerGlobal.CreateGlobals = function()
    global.ZombieEngineerGlobal = global.ZombieEngineerGlobal or {} ---@class Global_ZombieEngineerGlobal

    --  Do first as used by other setting generation.
    global.ZombieEngineerGlobal.Settings = {
        zombieEntityColor = { r = 0.100, g = 0.040, b = 0.0, a = 0.7 }, ---@type Color
        zombieTextColor = { r = 0.5, g = 0.5, b = 0.5, a = 0.7 } ---@type Color # Dark color isn't very readable.
    }

    global.ZombieEngineerGlobal.zombiePathingCollisionMask = game.entity_prototypes["zombie_engineer-zombie_engineer_path_collision_layer"].collision_mask ---@type data.CollisionMask
    global.ZombieEngineerGlobal.zombieEntityCollisionMask = game.entity_prototypes["zombie_engineer-zombie_engineer"].collision_mask ---@type data.CollisionMask
    global.ZombieEngineerGlobal.zombieEngineerEntityNames = ZombieEngineerGlobal.GetZombieEngineerEntityNamesAsDictionary() ---@type table<string, string> # Key and value are both the zombie engineer entity name.

    global.ZombieEngineerGlobal.zombieForce = ZombieEngineerGlobal.CreateZombieForce() ---@type LuaForce
    global.ZombieEngineerGlobal.playerForces = { game.forces["player"] } ---@type LuaForce[]
end

ZombieEngineerGlobal.OnLoad = function()
end

ZombieEngineerGlobal.OnStartup = function()
end

---@param event EventData.on_runtime_mod_setting_changed|nil # nil value when called from OnStartup (on_init & on_configuration_changed)
ZombieEngineerGlobal.OnSettingChanged = function(event)
end

---@return LuaForce zombieForce
ZombieEngineerGlobal.CreateZombieForce = function()
    if global.ZombieEngineerGlobal.zombieForce ~= nil then return global.ZombieEngineerGlobal.zombieForce end

    local zombieForce = game.create_force("zombie_engineer-zombie_engineer")

    -- Make the zombie and biters be friends.
    local biterForce = game.forces["enemy"]
    zombieForce.set_friend(biterForce, true)
    biterForce.set_friend(zombieForce, true)

    -- Set the zombie color as a dark brown.
    zombieForce.custom_color = global.ZombieEngineerGlobal.Settings.zombieEntityColor -- Used by the zombie engineer unit as its runtime tint color.

    return zombieForce
end

---@return table<string, string> zombieEntityNameDictionary
ZombieEngineerGlobal.GetZombieEngineerEntityNamesAsDictionary = function()
    local zombieEngineerEntityNames = {} ---@type table<string, string>
    ---@diagnostic disable-next-line: missing-fields # Temporary work around until Factorio docs and FMTK updated to allow per type field specification.
    local unitPrototypes = game.get_filtered_entity_prototypes({ { filter = "type", type = "unit" } })
    for unitName in pairs(unitPrototypes) do
        if string.find(unitName, "zombie_engineer-zombie_engineer", 1, true) then
            zombieEngineerEntityNames[unitName] = unitName
        end
    end
    return zombieEngineerEntityNames
end

return ZombieEngineerGlobal
