-- Temporary cache for the legacy User API. Character state is owned by
-- feather-character and must never enter this cache.
UserCache = {}
CacheAPI = {}

if Config.DevMode then
    RegisterCommand('PrintCache', function()
        PrettyPrint(UserCache)
    end)
end

function SetupCache()
    CreateThread(function()
        while true do
            CacheAPI.ReloadDBFromCache('user')
            Wait(30000)
        end
    end)
end

function CacheAPI.ReloadDBFromCacheRecord(cacheType, src)
    if cacheType ~= 'user' then return nil end
    local currentUser = UserCache[src]
    if not currentUser then return nil end
    local record = UserController.UpdateUser(currentUser)
    if record == nil then
        print('Failed to update User record from cache')
        return nil
    end
    return record
end

function CacheAPI.ReloadDBFromCache(cacheType)
    if cacheType ~= 'user' then return end
    for key, currentUser in pairs(UserCache) do
        if currentUser.__dirty then
            local ok, record = pcall(UserController.UpdateUser, currentUser)
            if not ok then
                print(('[feather-core] Failed to flush user cache for src %s: %s')
                    :format(tostring(key), tostring(record)))
            elseif record == nil then
                print(('[feather-core] Failed to update User from cache for src %s'):format(tostring(key)))
            else
                currentUser.__dirty = nil
            end
        end
    end
end

function CacheAPI.AddToCache(cacheType, src, ...)
    if cacheType ~= 'user' then return nil end
    UserCache[src] = UserController.LoadUser(...)
    return UserCache[src]
end

function CacheAPI.RemoveFromCache(cacheType, src)
    if cacheType == 'user' then UserCache[src] = nil end
end

function CacheAPI.GetCacheBySrc(cacheType, src)
    if cacheType == 'user' then return UserCache[src] end
    return nil
end

function CacheAPI.GetCacheByID(cacheType, id)
    if cacheType ~= 'user' then return nil end
    for src, value in pairs(UserCache) do
        if value.id == id then
            local target = {}
            for key, child in pairs(value) do target[key] = child end
            target.src = src
            return target
        end
    end
    return nil
end

function CacheAPI.UpdateCacheBySrc(cacheType, src, key, update)
    if cacheType ~= 'user' then return false end
    if not UserCache[src] then
        print('User cache not found')
        return false
    end
    UserCache[src][key] = update
    UserCache[src].__dirty = true
    return true
end
