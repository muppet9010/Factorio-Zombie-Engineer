local playerForce, zombieEngineerForce = game.forces["player"], game.forces["zombie_engineer-zombie_engineer"]
if playerForce ~= nil and zombieEngineerForce ~= nil then
    playerForce.set_cease_fire(zombieEngineerForce, false)
end
