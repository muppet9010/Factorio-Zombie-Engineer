local ZombieEngineerManager = require("scripts.zombie-engineer-manager")
local ZombieEngineerCreation = require("scripts.zombie-engineer-creation")
local ZombieEngineerDeath = require("scripts.zombie-engineer-death")
local ZombieEngineerPlayerLines = require("scripts.zombie-engineer-player-lines")
local EventScheduler = require("utility.manager-libraries.event-scheduler")
local CommandsUtils = require("utility.helper-utils.commands-utils")
local PlayerLines = require("utility.manager-libraries.player-lines")

local Control = {} ---@class Class_Control

local function CreateGlobals()
    ZombieEngineerManager.CreateGlobals()
    ZombieEngineerCreation.CreateGlobals()
    ZombieEngineerDeath.CreateGlobals()
    ZombieEngineerPlayerLines.CreateGlobals()
end

local function OnLoad()
    --Any Remote Interface registration calls can go in here or in root of control.lua
    if global.debugSettings == nil or global.debugSettings.testing == nil or global.debugSettings.testing then
        CommandsUtils.Register("zombie-engineer-call-on-startup", "Only intended for development and testing, likely will break things in a real game.", Control.CallOnStartupCommand, true)
    end

    ZombieEngineerManager.OnLoad()
    ZombieEngineerCreation.OnLoad()
    ZombieEngineerDeath.OnLoad()
    ZombieEngineerPlayerLines.OnLoad()
end

---@param event EventData.on_runtime_mod_setting_changed|nil # nil value when called from OnStartup (on_init & on_configuration_changed)
local function OnSettingChanged(event)
    ZombieEngineerManager.OnSettingChanged(event)
    ZombieEngineerCreation.OnSettingChanged(event)
    ZombieEngineerDeath.OnSettingChanged(event)
    ZombieEngineerPlayerLines.OnSettingChanged(event)
end

local function OnStartup()
    global.debugSettings = global.debugSettings or {}
    global.debugSettings.testing = false -- TODO

    CreateGlobals()
    OnLoad()
    OnSettingChanged(nil)

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

--- A debug command to reload all the startup globals and actions on an existing save. Only intended for development and testing, likely will break things in a real game.
Control.CallOnStartupCommand = function()
    OnStartup()
end
