local ZombieEngineerGlobal = require("scripts.zombie-engineer-global")
local ZombieEngineerManager = require("scripts.zombie-engineer-manager")
local ZombieEngineerCreation = require("scripts.zombie-engineer-creation")
local ZombieEngineerDeath = require("scripts.zombie-engineer-death")
local ZombieEngineerPlayerLines = require("scripts.zombie-engineer-player-lines")
local EventScheduler = require("utility.manager-libraries.event-scheduler")
local CommandsUtils = require("utility.helper-utils.commands-utils")
local PlayerLines = require("utility.manager-libraries.player-lines")

local Control = {} ---@class Class_Control

local function CreateGlobals()
    Control.CreateDebugGlobals()

    ZombieEngineerGlobal.CreateGlobals()
    ZombieEngineerManager.CreateGlobals()
    ZombieEngineerCreation.CreateGlobals()
    ZombieEngineerDeath.CreateGlobals()
    ZombieEngineerPlayerLines.CreateGlobals()
end

local function OnLoad()
    -- Any Remote Interface or Command registration calls go in here.
    Control.RegisterDebugCommands()

    ZombieEngineerGlobal.OnLoad()
    ZombieEngineerManager.OnLoad()
    ZombieEngineerCreation.OnLoad()
    ZombieEngineerDeath.OnLoad()
    ZombieEngineerPlayerLines.OnLoad()
end

---@param event EventData.on_runtime_mod_setting_changed|nil # nil value when called from OnStartup (on_init & on_configuration_changed)
local function OnSettingChanged(event)
    ZombieEngineerGlobal.OnSettingChanged(event)
    ZombieEngineerManager.OnSettingChanged(event)
    ZombieEngineerCreation.OnSettingChanged(event)
    ZombieEngineerDeath.OnSettingChanged(event)
    ZombieEngineerPlayerLines.OnSettingChanged(event)
end

local function OnStartup()
    CreateGlobals()
    OnLoad()
    OnSettingChanged(nil)

    ZombieEngineerGlobal.OnStartup()
    ZombieEngineerManager.OnStartup()
    ZombieEngineerCreation.OnStartup()
    ZombieEngineerDeath.OnStartup()
    ZombieEngineerPlayerLines.OnStartup()
end

script.on_init(OnStartup)
script.on_configuration_changed(OnStartup)
script.on_event(defines.events.on_runtime_mod_setting_changed, OnSettingChanged)
script.on_load(OnLoad)

script.on_nth_tick(10, ZombieEngineerManager.ManageAllZombieEngineers)
EventScheduler.RegisterScheduler()
PlayerLines.RegisterPlayerAlerts()

-- Mod wide function interface table creation. Means EmmyLua can support it.
MOD = MOD or {} ---@class MOD
MOD.Interfaces = MOD.Interfaces or {} ---@class MOD_InternalInterfaces



Control.CreateDebugGlobals = function()
    global.debugSettings = global.debugSettings or {} ---@class Global_DebugSettings
    global.debugSettings.testing = global.debugSettings.testing or false
end

--- Called to register the generic mod testing commands. These are safe to be called repeatedly as they overwrite any old instance when required.
Control.RegisterDebugCommands = function()
    CommandsUtils.Register("zombie-engineer-toggle-testing", "Only intended for development and testing, likely will break things in a real game.", Control.ToggleTestingMode, true)
    -- Have to be careful in checking around these global's as in mod update situation the OnStartup() won't have been run yet.
    if global.debugSettings ~= nil and global.debugSettings.testing == true then
        CommandsUtils.Register("zombie-engineer-call-on-startup", "Only intended for development and testing, likely will break things in a real game.", Control.CallOnStartupCommand, true)
    else
        commands.remove_command("zombie-engineer-call-on-startup")
    end
end

--- A debug command to toggle Testing mode on and off in the current save in a safe manner. Only intended for development and testing, likely will break things in a real game.
Control.ToggleTestingMode = function()
    if global.debugSettings.testing then
        global.debugSettings.testing = false
    else
        global.debugSettings.testing = true
    end
    -- Need to make sure we update the registered commands and the settings carefully. As they can otherwise go out of sync between client and server on mod upgrade and change of values (default value change). Commit: 93abedfd2b8d98a5d0133b74baa96055429548cd
    Control.RegisterDebugCommands()
end

--- A debug command to reload all the startup globals and actions on an existing save. Only intended for development and testing, likely will break things in a real game.
Control.CallOnStartupCommand = function()
    OnStartup()
end
