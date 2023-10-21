local ZombieEngineerManager = require('scripts.zombie-engineer-manager')
local EventScheduler = require("utility.manager-libraries.event-scheduler")

local function CreateGlobals()
    ZombieEngineerManager.CreateGlobals()
end

local function OnLoad()
    --Any Remote Interface registration calls can go in here or in root of control.lua
    ZombieEngineerManager.OnLoad()
end

---@param event EventData.on_runtime_mod_setting_changed|nil # nil value when called from OnStartup (on_init & on_configuration_changed)
local function OnSettingChanged(event)
    --if event == nil or event.setting == "xxxxx" then
    --	local x = tonumber(settings.global["xxxxx"].value)
    --end
end

local function OnStartup()
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
