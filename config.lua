Config = {}

Config.DevMode = true

Config.IdleAnimation = true
Config.DisableRandomLootPrompts = true

Config.PositionSync = 20000

Config.PVP = true
Config.UseDeadEye = true
Config.UseEagleEye = true

Config.UseFogOfWar = false

--Scale is 0.0-1.0
Config.DensityMultipliers = {
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

Config.UI = {
    hotkey = "PGUP",
    command = "menu",
    suggestion = "Toggles the core ui"
}

Config.XP = {
    perLevel = 1900
}

-- All commands that the core has access to on startup (not including API registered commands)
Config.Commands = {
    {
        command = "suicide",
        suggestion = "Kill yourself",
        callback = function()
            if not IsOnServer() then
                SetEntityHealth(PlayerPedId(), 0, 0)
            end
        end
    }
}
