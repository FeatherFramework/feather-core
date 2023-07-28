Config = {}

Config.DevMode = true


--Scale is 0.0-1.0
Config.densityMultipliers = {
    ambientPeds     = 1.0,
    scenarioPeds    = 1.0,
    vehicles        = 1.0,
    parkedVehicles  = 1.0,
    randomVehicles  = 1.0,
    ambientAnimals  = 1.0,
    ambientHumans   = 1.0,
    scenarioAnimals = 1.0,
    scenarioHumans  = 1.0
}

-- All commands that the core has access to on startup (not including API registered commands)
Config.Commands = {
    ["hello"] = {
        suggestion = "This is an awesome command",
        callback = function()
            print("WORLD!")
        end
    }
}