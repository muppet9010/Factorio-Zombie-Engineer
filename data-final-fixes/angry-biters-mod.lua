-- If the mod `AngryBiters` created any angry zombie prototypes then remove them. This stops that mod from replacing our zombie entity to the angry one when it gets injured.
for unitPrototypeName in pairs(data.raw["unit"] --[[@as table<string, data.UnitPrototype>]]) do
    if string.find(unitPrototypeName, "ab-enraged-zombie_engineer-", 1, true) ~= nil then
        data.raw["unit"][unitPrototypeName] = nil ---@type data.UnitPrototype
    end
end
