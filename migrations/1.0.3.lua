-- Account or new Zombie Engineer properties.
for _, zombieEngineer in pairs(global.ZombieEngineerManager.zombieEngineers) do
    zombieEngineer.entityColor = zombieEngineer.sourcePlayer and zombieEngineer.sourcePlayer.color or { r = 0.100, g = 0.040, b = 0.0, a = 0.7 }
    zombieEngineer.textColor = zombieEngineer.sourcePlayer and zombieEngineer.sourcePlayer.color or { r = 0.5, g = 0.5, b = 0.5, a = 0.7 }
end
