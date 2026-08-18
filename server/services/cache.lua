-- In-memory mirror of the `users`/`characters` DB rows for every currently
-- connected player, keyed by server `src`. Every resource in the framework
-- reads/writes through here instead of hitting the DB directly on every
-- call; SetupCache() below flushes dirty rows back to the DB on a timer,
-- and playerDropped flushes+evicts a single player's entry immediately
-- (see users.lua/character.lua). This is why identity should always be
-- looked up by `src` server-side -- it's the same cache every RPC handler
-- in the framework reads.
UserCache = {}
CharacterCache = {}

CacheAPI = {}

if Config.DevMode then
    RegisterCommand('PrintCache', function(source, args)
        PrettyPrint(UserCache)
        PrettyPrint(CharacterCache)
    end)
end

-- Periodic flush loop: writes every cached user/character row back to the
-- DB every 30s so an ungraceful disconnect (crash, network drop) only ever
-- loses at most 30s of state. Started once from RunCore() in server/main.lua.
function SetupCache()
    CreateThread(function()
        while true do
            CacheAPI.ReloadDBFromCache('user')
            CacheAPI.ReloadDBFromCache('character')
            Wait(30000) --Refresh Cache Every X miliseconds (Currently 30 seconds)
        end
    end)
end

-- Flushes a single src's cached row to the DB (used on playerDropped/logout,
-- as opposed to ReloadDBFromCache below which sweeps every cached entry).
function CacheAPI.ReloadDBFromCacheRecord(type, src)
    if type == 'user' then
        local currentUser = UserCache[src]
        local record = UserController.UpdateUser(currentUser)
        if record == nil then
            print("Failed to update User record from cache")
            return
        end
    elseif type == 'character' then
        local currentChar = CharacterCache[src]
        CharacterController.UpdateCharacter(currentChar)
    end
end

-- Sweeps every cached user/character and writes it back to the DB. Called
-- by the SetupCache() timer loop above.
--
-- (CORE-32) Neither branch used to guard against a single row's write
-- throwing (e.g. a DB constraint violation) -- an uncaught error here
-- unwinds straight out of the CreateThread in SetupCache, which has no
-- pcall of its own, permanently killing the flush loop for every player
-- until a restart. Each row is now isolated with pcall so one bad row logs
-- and gets skipped instead of taking the rest of the server's persistence
-- down with it. (The user branch's old `return` on a failed update had the
-- same effect one level down -- it aborted the rest of that sweep's users
-- instead of just skipping the failed one; pcall fixes both at once.)
-- (CORE-31) Only rows CacheAPI.UpdateCacheBySrc actually touched since the
-- last flush get written -- a player who's connected but idle (or whose
-- resource never mutates their cache, e.g. UserCache today) no longer costs
-- a DB write every single cycle. `__dirty` is cleared after a *successful*
-- write so a failed/pcall'd row stays flagged and gets retried next cycle
-- instead of silently being treated as flushed.
function CacheAPI.ReloadDBFromCache(type)
    if type == 'user' then
        for key, currentUser in pairs(UserCache) do
            if currentUser.__dirty then
                local ok, record = pcall(UserController.UpdateUser, currentUser)
                if not ok then
                    print(("[feather-core] Failed to flush user cache for src %s: %s"):format(tostring(key), tostring(record)))
                elseif record == nil then
                    print(("[feather-core] Failed to update User from cache for src %s"):format(tostring(key)))
                else
                    currentUser.__dirty = nil
                end
            end
        end
    elseif type == 'character' then
        for key, currentChar in pairs(CharacterCache) do
            if currentChar.__dirty then
                local ok, err = pcall(CharacterController.UpdateCharacter, currentChar)
                if not ok then
                    print(("[feather-core] Failed to flush character cache for src %s: %s"):format(tostring(key), tostring(err)))
                else
                    currentChar.__dirty = nil
                end
            end
        end
    end
end

-- Loads a row from the DB (via UserController/CharacterController, whose
-- extra args are forwarded through `...`) and seeds the cache with it. This
-- is the entry point for a player's session: called once from
-- playerJoining (user) and once from CharacterAPI.InitiateCharacter
-- (character) -- see users.lua/character.lua.
function CacheAPI.AddToCache(type, src, ...)
    if type == 'user' then
        UserCache[src] = UserController.LoadUser(...)
        return UserCache[src]
    elseif type == 'character' then
        CharacterCache[src] = CharacterController.GetCharacter(...)

        print("Character Added to cache")

        return CharacterCache[src]
    end
end

function CacheAPI.RemoveFromCache(type, src)
    if type == 'user' then
        UserCache[src] = nil
    elseif type == 'character' then
        CharacterCache[src] = nil
    end
end

function CacheAPI.GetCacheBySrc(type, src)
    if type == 'user' then
        return UserCache[src]
    elseif type == 'character' then
        return CharacterCache[src]
    end
end

-- Unlike GetCacheBySrc, this scans every currently-cached (i.e. currently
-- connected) entry looking for a matching DB id -- it does NOT query the
-- DB, so it can only ever find someone who is online right now.
function CacheAPI.GetCacheByID(type, ID)
    local targetCache

    local tempCache

    if type == 'user' then
        tempCache = UserCache
    elseif type == 'character' then
        tempCache = CharacterCache
    end

    for src, value in pairs(tempCache) do
        if value.id == ID then
            targetCache = value
            targetCache.src = src
            break
        end
    end

    return targetCache
end

-- (CORE-31) This is the single choke point every character/user field
-- mutation goes through (position, lang, economy Add/Subtract, ...), so
-- marking `__dirty` here is enough to catch every write path -- see
-- ReloadDBFromCache below, which now only flushes rows this touched instead
-- of rewriting every connected player every 30s regardless of whether
-- anything changed.
function CacheAPI.UpdateCacheBySrc(type, src, key, update)
    if type == 'user' then
        if not UserCache[src] then
            print("User cache not found")
            return
        end

        UserCache[src][key] = update;
        UserCache[src].__dirty = true
    elseif type == 'character' then
        if not CharacterCache[src] then
            print("Character cache not found")
            PrettyPrint(CharacterCache)
            return
        end

        CharacterCache[src][key] = update;
        CharacterCache[src].__dirty = true
    end
end
