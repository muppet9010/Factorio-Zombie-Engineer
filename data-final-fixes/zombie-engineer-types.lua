-- Make variations of the zombie engineer prototype or each armor type in the game.

local TableUtils = require('utility.helper-utils.table-utils')
local PrototypeUtils = require("utility.helper-utils.prototype-utils-data-stage")

local characterPrototypeReference = data.raw["character"]["character"]

local noArmorZombieEngineer = data.raw["unit"]["zombie_engineer-zombie_engineer"]
for _, armorPrototype in pairs(data.raw["armor"]) do
    local armoredZombieEngineer = TableUtils.DeepCopy(noArmorZombieEngineer) ---@type data.UnitPrototype
    local armorName = armorPrototype.name
    armoredZombieEngineer.name = armoredZombieEngineer.name .. "_" .. armorName
    armoredZombieEngineer.resistances = TableUtils.DeepCopy(armorPrototype.resistances)
    armoredZombieEngineer.run_animation = TableUtils.DeepCopy(PrototypeUtils.GetArmorSpecificAnimationFromCharacterPrototype(characterPrototypeReference, armorName).running) -- Copy of the appropriate armor's run animation. Use a copy so that any changes to values don't cross contaminate.

    data:extend({ armoredZombieEngineer })
end
