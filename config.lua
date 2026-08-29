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

