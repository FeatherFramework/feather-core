-- Setup Global User API
UserAPI = {}


-- User caching funtions
function UserAPI.GetUserBySrc(src)
    return CacheAPI.GetCacheBySrc("user", src)
end

function UserAPI.GetUserByID(ID)
    return CacheAPI.GetCacheByID("user", ID)
end

-- Returns the license identifier used by Feather's users table.
function UserAPI.GetLicense(src)
    return GetIdentifiers(src).license
end

-- Authority is character-scoped, but protection for account-wide actions
-- must include the highest role held by any character on the account.
function UserAPI.GetHighestRoleLevel(opts)
    opts = type(opts) == "table" and opts or {}

    local license = opts.license
    if license == nil and opts.src ~= nil then
        license = UserAPI.GetLicense(opts.src)
    end
    if type(license) ~= "string" or license == "" then return nil end

    local row = MySQL.single.await([[
        SELECT COUNT(u.id) AS account_count, MAX(r.level) AS level
        FROM users u
        LEFT JOIN characters c ON c.user_id = u.id
        LEFT JOIN roles r ON r.id = c.role_id
        WHERE u.license = ?
    ]], { license })

    if row == nil or tonumber(row.account_count) == 0 then return nil end
    return tonumber(row.level) or 0
end

-- Pulls the RedM/Rockstar license identifier out of a player's identifier
-- list -- this is what `users.license` is keyed on (see migration.sql),
-- so it's the actual "who is this person" anchor everything else hangs off.
function GetIdentifiers(src)
    for _, identifier in ipairs(GetPlayerIdentifiers(src)) do
        if identifier:sub(1, 8) == 'license:' then
            return { license = identifier }
        end
    end
    return { license = nil }
end

ConnectionAPI.RegisterGate('feather-core:credentials', function(src, playerName)
    local username = type(playerName) == 'string' and playerName:gsub('%s+', '') or ''
    local identifiers = GetIdentifiers(src)
    if not identifiers.license then return 'Invalid License' end
    if username == '' then return 'Invalid Username' end
    return nil
end, {
    priority = 0,
    timeoutMs = 5000,
    failClosed = true,
    label = 'credentials',
    failureMessage = 'Credential validation could not be completed. Please try again.'
})

-- Wires up the three CFX connection lifecycle events. Called once from
-- RunCore() in server/main.lua. This is the only place user rows enter/
-- leave the cache -- character selection (feather-character) only ever
-- runs after playerJoining has already populated UserCache[src].
function SetupPlayerEvents()
    -- Fires once a connecting player has actually joined the session.
    -- Loads (or creates, see UserController.LoadUser) their user row and
    -- seeds UserCache[src] with it.
    AddEventHandler('playerJoining', function()
        local src = source
        local identifiers = GetIdentifiers(src)

        CacheAPI.AddToCache("user", src, GetPlayerName(src), identifiers.license)
        DebugLog("Added source", src)
    end)

    -- Fires on disconnect. Flushes the user's cached row to the DB one
    -- last time, then evicts it -- `src` is about to be reused by a
    -- different future connection, so nothing may still key off it after
    -- this point.
    AddEventHandler('playerDropped', function()
        local src = source
        CacheAPI.ReloadDBFromCacheRecord("user", src)
        CacheAPI.RemoveFromCache("user", src)
        DebugLog("Dropped User Source", src)
    end)

    -- Runs during the connection handshake, before playerJoining. Uses
    -- CFX's deferrals API to hold the client in the "connecting" screen
    -- while checking they have a usable license identifier and a non-empty
    -- username, rejecting the connection outright if not.
    AddEventHandler('playerConnecting', function(name, kickreason, deferrals)
        local src = source
        deferrals.defer()
        Wait(0)

        local rejection = ConnectionAPI.RunGates(src, name, deferrals)
        if rejection then
            deferrals.done(rejection)
            return
        end

        deferrals.update('Connecting to server...')
        deferrals.done()
    end)
end
