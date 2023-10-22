MODDATA = MODDATA or {} ---@type table

MODDATA.zombieEngineerPathCollisionLayer = require('prototypes.zombie-path-collision-mask') --TODO: we will need to pass this into our gravestones.

require('prototypes.zombie-engineer')

require('prototypes.grave_with_headstone')
