UserCache = {}
CharacterCache = {}

--TODO: Make cache optional via config.

CacheAPI = {}

if Config.DevMode then
    RegisterCommand('PrintCache', function(source, args)
        PrettyPrint(UserCache)
        PrettyPrint(CharacterCache)
    end)
end

function SetupCache()
    Citizen.CreateThread(function()
        while true do
            CacheAPI.ReloadCache('user')
            CacheAPI.ReloadCache('character')
            Wait(30000) --Refresh Cache Every X miliseconds (Currently 30 seconds)
        end
    end)
end

function CacheAPI.ReloadCacheRecord(type, src)
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

function CacheAPI.ReloadCache(type)
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

function CacheAPI.GetCacheByID(type, ID)
    local targetCache

    local tempCache

    if type == 'user' then
        tempCache = UserCache
    elseif type == 'character' then
        tempCache = CharacterCache
    end

    for _, value in pairs(tempCache) do
        if value.ID == ID then
            targetCache = value
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

-- User caching funtions
function CacheAPI.GetUserBySrc(src)
    return CacheAPI.GetCacheBySrc("user", src)
end

function CacheAPI.GetUserByID(ID)
    return CacheAPI.GetCacheByID("user", ID)
end

-- Character- caching funtions
function CacheAPI.GetCharacterBySrc(src)
    return CacheAPI.GetCacheBySrc("character", src)
end

function CacheAPI.GetCharacterByID(ID)
    return CacheAPI.GetCacheByID("character", ID)
end
