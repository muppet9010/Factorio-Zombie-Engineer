local EntityTypeGroups = {} ---@class Utility_EntityTypeGroupsList

EntityTypeGroups.AllCarriageTypes_Dictionary = { locomotive = "locomotive", ["cargo-wagon"] = "cargo-wagon", ["fluid-wagon"] = "fluid-wagon", ["artillery-wagon"] = "artillery-wagon" }
EntityTypeGroups.AllCarriageTypes_List = { "locomotive", "cargo-wagon", "fluid-wagon", "artillery-wagon" }

EntityTypeGroups.TeleportableTypes_Dictionary = { unit = "unit", character = "character", car = "car", ["spider-vehicle"] = "spider-vehicle" }

EntityTypeGroups.NonRailVehicles_Dictionary = { car = "car", ["spider-vehicle"] = "spider-vehicle" }
EntityTypeGroups.NonRailVehicles_List = { "car", "spider-vehicle" }

return EntityTypeGroups
