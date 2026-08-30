Config = {}

-- Enables additional development diagnostics. Keep false on production servers.
Config.DevMode = false

-- Locale used when a player's saved language is unavailable or invalid.
Config.DefaultLang = 'en_us'

Config.Logging = {
    -- Minimum log severity: debug, info, warn, or error.
    level = 'warn'
}

-- WARNING: The values below are framework safety and capacity limits.
-- Most server owners should leave them unchanged. Lower values may cause valid
-- resource requests to fail; higher values may increase abuse and stability risks.
-- Adjust them only when a resource developer identifies a specific requirement.
Config.EventBroker = {
    maxPayloadBytes = 32768, -- Largest encoded event payload accepted, in bytes.
    maxDepth = 12,           -- Maximum nesting depth allowed in event payloads.
    maxNodes = 2048,         -- Maximum total values allowed in one event payload.
    maxSubscribers = 128     -- Maximum listeners allowed for a declared event.
}

Config.ProviderRegistry = {
    maxPerKind = 16 -- Maximum registered providers for each provider type.
}

Config.GuardRegistry = {
    maxPerAction = 64 -- Maximum guards that may evaluate one protected action.
}

Config.NotificationRegistry = {
    maxMessageLength = 512, -- Maximum notification message length in characters.
    maxDurationMs = 15000   -- Longest notification display duration, in milliseconds.
}

-- Framework-wide limits applied to each player's RPC traffic.
Config.RPCRateLimit = {
    windowMs = 1000,        -- Length of each rate-limit window, in milliseconds.
    maxCalls = 30,          -- Maximum RPC calls allowed per player per window.
    timeoutMs = 10000,      -- Time before an unanswered RPC call fails, in milliseconds.
    maxPayloadBytes = 65536 -- Largest encoded RPC request accepted, in bytes.
}
