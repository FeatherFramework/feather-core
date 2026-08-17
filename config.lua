Config = {}

Config.DevMode = false

Config.DefaultLang = "en_us" -- Default Language that will be used when we can not get the individual players preferred language.

Config.IdleAnimation = true
Config.DisableRandomLootPrompts = true

Config.PositionSync = 20000 --ms

Config.PVP = true
Config.UseDeadEye = true
Config.UseEagleEye = true
Config.UseFogOfWar = false

Config.Character = {
    death = {
        timer = 60, --seconds
        cameraRotation = true
    }
}

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

-- Per-source throttle applied to every RPC dispatched over the Feather:Call
-- bus (see shared/services/arpc.lua). Framework-wide, not per-procedure --
-- protects every resource's registered RPCs from spam without each one
-- needing its own rate limiter. (CORE-06)
Config.RPCRateLimit = {
    windowMs = 1000, -- size of the rolling window
    maxCalls = 30,   -- max Feather:Call invocations per source per window
    timeoutMs = 10000, -- default client/server callback timeout
    maxPayloadBytes = 65536 -- maximum encoded params size per call
}

-- Minimum roles.level required for CharacterAPI.IsAdmin(src) to
-- return true. Matches the framework's seeded roles (see migration.sql/
-- seed.sql): 'general' = 0 (default for every new character), 'admin' = 99.
Config.AdminLevel = 99

-- (CORE-03 / CHAR-05) CreateInstance's `params.id` used to be honored
-- verbatim from any client -- since a routing bucket's only access control
-- IS its id, any client could request any existing bucket id and force
-- themselves into an instance meant to isolate someone else (housing,
-- admin staging, minigames, etc). Only ids listed here may be requested by
-- number; any other requested id is ignored in favor of a fresh private
-- bucket (see server/services/instances.lua). 123 is feather-character's
-- shared character-select room (client/services/character/selector.lua) --
-- everyone in character select is meant to share visibility, so it's safe
-- to leave joinable by id.
Config.PublicInstanceIds = {
    [123] = true
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

Config.RespawnLocations = {
    {
        name = "Valentine Medical",
        coords = vector3(-288.882172, 811.387634, 119.385941),
        heading = 236.87
    },
    {
        name = "St. Denis Medical",
        coords = vector3(2732.895752, -1231.804321, 50.370411),
        heading = 69.18
    },
    {
        name = "Strawberry Medical",
        coords = vector3(-1803.796997, -430.861938, 158.830292),
        heading = 72.78
    }
}
