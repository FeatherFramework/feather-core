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
function CacheAPI.ReloadDBFromCache(type)
    local record = nil
    if type == 'user' then
        for key, currentUser in pairs(UserCache) do
            record = UserController.UpdateUser(currentUser)
            if record == nil then
                print("Failed to update User from cache")
                return
            end
        end
    elseif type == 'character' then
        for key, currentChar in pairs(CharacterCache) do
            CharacterController.UpdateCharacter(currentChar)
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

function CacheAPI.UpdateCacheBySrc(type, src, key, update)
    if type == 'user' then
        if not UserCache[src] then
            print("User cache not found")
            return
        end

        UserCache[src][key] = update;
    elseif type == 'character' then
        if not CharacterCache[src] then
            print("Character cache not found")
            PrettyPrint(CharacterCache)
            return
        end

        CharacterCache[src][key] = update;
    end
end
