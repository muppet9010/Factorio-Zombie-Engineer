-- Make variations of the zombie engineer prototype or each armor type in the game.
-- Armors below heavy armor are nerfed significantly by this, but tbh heavy armor and after is the majority of the game and so getting these balanced is what matters most.
-- This implements the details as per spreadsheet (scaling damage); https://docs.google.com/spreadsheets/d/1yIMR8AXHv2wZXUDJXdqdJD0vWZkzh4r-hTw64ydeHQ0/edit#gid=1004830454

local TableUtils = require('utility.helper-utils.table-utils')
local PrototypeUtils = require("utility.helper-utils.prototype-utils-data-stage")

local characterPrototypeReference = data.raw["character"]["character"]


---@param armorPrototype data.ArmorPrototype
---@return double
local GetZombieDifficultyForArmor = function(armorPrototype)
    local armorResistances = armorPrototype.resistances
    local zombieDifficulty = 1

    if armorResistances ~= nil then
        local totalReductionPercent = 0
        for _, resistance in pairs(armorResistances) do
            if resistance.percent ~= nil then
                totalReductionPercent = totalReductionPercent + (resistance.percent / 100)
            end
        end

        local explosionResistance = TableUtils.GetTableValueWithInnerKeyValue(armorResistances, "type", "explosion", false) --[[@as data.Resistance?]]
        local explosionReductionFlat = (explosionResistance ~= nil and explosionResistance.decrease ~= nil) and explosionResistance.decrease or 0
        local physicalResistance = TableUtils.GetTableValueWithInnerKeyValue(armorResistances, "type", "physical", false) --[[@as data.Resistance?]]
        local physicalReductionFlat = (physicalResistance ~= nil and physicalResistance.decrease ~= nil) and physicalResistance.decrease or 0
        local totalReductionFlat = (explosionReductionFlat * 0.1) + physicalReductionFlat

        zombieDifficulty = (totalReductionPercent + totalReductionFlat) - 8
    end

    return math.max(zombieDifficulty, 1)
end

---@param armorPrototype data.ArmorPrototype
---@return data.Resistance[]? zombieResistances
local GetZombieResistancesForArmor = function(armorPrototype)
    local armorResistances = TableUtils.DeepCopy(armorPrototype.resistances) --[[@as data.Resistance[]? ]]
    if armorResistances == nil then return nil end
    local zombieResistances = {} ---@type data.Resistance[]
    for _, resistance in pairs(armorResistances) do
        if resistance.type == "physical" then
            -- Just reduce the physical resistance to make the yellow ammo vs heavy armor era balanced.
            resistance.decrease = math.max(resistance.decrease - 4, 0)
        end
        zombieResistances[#zombieResistances + 1] = resistance
    end
    return zombieResistances
end

---@param zombieDifficulty double
---@param baseHealingRate float
---@return float
local GetZombieHealingForDifficulty = function(zombieDifficulty, baseHealingRate)
    local healingRate = zombieDifficulty * baseHealingRate
    return healingRate
end

---@param zombieDifficulty double
---@param baseHealth float
---@return float
local GetZombieHealthForDifficulty = function(zombieDifficulty, baseHealth)
    local health = baseHealth * zombieDifficulty
    return health
end

local noArmorZombieEngineer = data.raw["unit"]["zombie_engineer-zombie_engineer"]
for _, armorPrototype in pairs(data.raw["armor"]) do
    local armoredZombieEngineer = TableUtils.DeepCopy(noArmorZombieEngineer) --[[@as data.UnitPrototype]]
    local armorName = armorPrototype.name
    armoredZombieEngineer.name = armoredZombieEngineer.name .. "-" .. armorName
    armoredZombieEngineer.localised_name = { "", { "entity-name.zombie_engineer-zombie_engineer" }, " ", { "entity-name.zombie_engineer-zombie_engineer-wearing_armor", armorName } }
    armoredZombieEngineer.localised_description = { "", { "entity-description.zombie_engineer-zombie_engineer" }, " ", { "entity-description.zombie_engineer-zombie_engineer-wearing_armor", armorName } }
    local zombieDifficulty = GetZombieDifficultyForArmor(armorPrototype)
    armoredZombieEngineer.resistances = GetZombieResistancesForArmor(armorPrototype)
    armoredZombieEngineer.healing_per_tick = GetZombieHealingForDifficulty(zombieDifficulty, noArmorZombieEngineer.healing_per_tick)
    armoredZombieEngineer.max_health = GetZombieHealthForDifficulty(zombieDifficulty, noArmorZombieEngineer.max_health)
    armoredZombieEngineer.run_animation = TableUtils.DeepCopy(PrototypeUtils.GetArmorSpecificAnimationFromCharacterPrototype(characterPrototypeReference, armorName).running) -- Copy of the appropriate armor's run animation. Use a copy so that any changes to values don't cross contaminate.

    data:extend({ armoredZombieEngineer })
end
