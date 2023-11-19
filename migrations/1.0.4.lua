-- Migrate from 1.0.3 to 1.0.4 - Just for JD-Plays streams.

-- Move any old data across.
if global.ZombieEngineerManager ~= nil and global.ZombieEngineerGlobal == nil then
    global.ZombieEngineerGlobal = {}

    if global.ZombieEngineerManager.zombiePathingCollisionMask ~= nil then
        global.ZombieEngineerGlobal.zombiePathingCollisionMask = global.ZombieEngineerManager.zombiePathingCollisionMask
        global.ZombieEngineerManager.zombiePathingCollisionMask = nil ---@type nil
    end
    if global.ZombieEngineerManager.zombieEntityCollisionMask ~= nil then
        global.ZombieEngineerGlobal.zombieEntityCollisionMask = global.ZombieEngineerManager.zombieEntityCollisionMask
        global.ZombieEngineerManager.zombieEntityCollisionMask = nil ---@type nil
    end

    if global.ZombieEngineerManager.zombieForce ~= nil then
        global.ZombieEngineerGlobal.zombieForce = global.ZombieEngineerManager.zombieForce
        global.ZombieEngineerManager.zombieForce = nil ---@type nil
    end
    if global.ZombieEngineerManager.playerForces ~= nil then
        global.ZombieEngineerGlobal.playerForces = global.ZombieEngineerManager.playerForces
        global.ZombieEngineerManager.playerForces = nil ---@type nil
    end

    -- Just remove these as they are hard coded.
    if global.ZombieEngineerManager.Settings ~= nil then
        global.ZombieEngineerManager.Settings.zombieEntityColor = nil ---@type nil
        global.ZombieEngineerManager.Settings.zombieTextColor = nil ---@type nil
    end
end

if global.ZombieEngineerManager ~= nil and global.ZombieEngineerCreation == nil then
    global.ZombieEngineerCreation = {}

    if global.ZombieEngineerManager.playerDeathCounts ~= nil then
        global.ZombieEngineerCreation.playerDeathCounts = global.ZombieEngineerManager.playerDeathCounts
        global.ZombieEngineerManager.playerDeathCounts = nil ---@type nil
    end

    global.ZombieEngineerCreation.Settings = {}

    if global.ZombieEngineerManager.Settings.zombieNames ~= nil then
        global.ZombieEngineerCreation.Settings.zombieNames = global.ZombieEngineerManager.Settings.zombieNames
        global.ZombieEngineerManager.Settings.zombieNames = nil ---@type nil
    end
end
