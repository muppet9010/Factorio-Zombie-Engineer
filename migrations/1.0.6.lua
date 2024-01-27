-- Remove any persisting testing setting from older 1.0.4 era saves that were set to `true` by mistake from an overlooked default at release time.
-- Future code has a better system for this and so such testing values can't pollute production releases of the mod.

global.debugSettings = global.debugSettings or {} ---@class Global_DebugSettings
global.debugSettings.testing = false -- Turn it off



-- Remove a now unused global.
if global.ZombieEngineerCreation ~= nil then
    global.ZombieEngineerCreation.playerWornArmorOnDeath = nil ---@type nil # Just to stop it alerting for missing type.
end
