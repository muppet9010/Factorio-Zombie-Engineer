local ZombieEngineerManager = require("scripts.zombie-engineer-manager")
local EventScheduler = require("utility.manager-libraries.event-scheduler")
local CommandsUtils = require("utility.helper-utils.commands-utils")

local Control = {} ---@class Class_Control

local function CreateGlobals()
    ZombieEngineerManager.CreateGlobals()
end

local function OnLoad()
    --Any Remote Interface registration calls can go in here or in root of control.lua
    if global.debugSettings == nil or global.debugSettings.testing == nil or global.debugSettings.testing then
        CommandsUtils.Register("ZombieEngineer_CallOnStartup", "Only intended for development and testing, likely will break things in a real game.", Control.CallOnStartupCommand, true)
    end

    ZombieEngineerManager.OnLoad()
end

---@param event EventData.on_runtime_mod_setting_changed|nil # nil value when called from OnStartup (on_init & on_configuration_changed)
local function OnSettingChanged(event)
    --if event == nil or event.setting == "xxxxx" then
    --	local x = tonumber(settings.global["xxxxx"].value)
    --end
end

local function OnStartup()
    global.debugSettings = global.debugSettings or {}
    global.debugSettings.testing = false -- TODO

    CreateGlobals()
    OnLoad()
    OnSettingChanged(nil)

    ZombieEngineerManager.OnStartup()
end

script.on_init(OnStartup)
script.on_configuration_changed(OnStartup)
script.on_event(defines.events.on_runtime_mod_setting_changed, OnSettingChanged)
script.on_load(OnLoad)

script.on_nth_tick(10, ZombieEngineerManager.ManageAllZombieEngineers)
EventScheduler.RegisterScheduler()

-- Mod wide function interface table creation. Means EmmyLua can support it.
MOD = MOD or {} ---@class MOD
MOD.Interfaces = MOD.Interfaces or {} ---@class MOD_InternalInterfaces
--[[
    Populate and use from within module's OnLoad() functions with simple table reference structures, i.e:
        MOD.Interfaces.Tunnel = MOD.Interfaces.Tunnel or {} ---@class InternalInterfaces_XXXXXX
        MOD.Interfaces.Tunnel.CompleteTunnel = Tunnel.CompleteTunnel
--]]
--

--- A debug command to reload all the startup globals and actions on an existing save. Only intended for development and testing, likely will break things in a real game.
Control.CallOnStartupCommand = function()
    OnStartup()
end
