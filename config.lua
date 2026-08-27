Config = {}

Config.DevMode = false

Config.Logging = {
    level = "info" -- debug, info, warn, or error
}

Config.EventBroker = {
    maxPayloadBytes = 32768,
    maxDepth = 12,
    maxNodes = 2048,
    maxSubscribers = 128
}

Config.ProviderRegistry = {
    maxPerKind = 16
}

Config.GuardRegistry = {
    maxPerAction = 64
}

Config.NotificationRegistry = {
    maxMessageLength = 512,
    maxDurationMs = 15000
}

Config.DefaultLang = "en_us" -- Default Language that will be used when we can not get the individual players preferred language.

Config.DisableRandomLootPrompts = true
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

Config.XP = {
    perLevel = 1900
}

Config.PlayerSettings = {
    hotkey = "PGUP"
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
