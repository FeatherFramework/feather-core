-- Setup Global User API
UserAPI = {}


-- User caching funtions
function UserAPI.GetUserBySrc(src)
    return CacheAPI.GetCacheBySrc("user", src)
end

function UserAPI.GetUserByID(ID)
    return CacheAPI.GetCacheByID("user", ID)
end

function GetIdentifiers(src)
    local identifiers = GetPlayerIdentifiers(src)

    local license

    for _, v in pairs(identifiers) do
        if string.find(v, 'license') then
            license = v
        end

        if license then
            break
        end
    end

    return {
        license = license
    }
end

-- User Events
function SetupPlayerEvents()
    AddEventHandler('playerJoining', function()
        local src = source
        local identifiers = GetIdentifiers(src)

        local timestamp = os.date("%Y-%m-%d %H:%M:%S");
        CacheAPI.AddToCache("user", src, GetPlayerName(src), identifiers.license, timestamp)
        DebugLog("Added source", src)
    end)
    
    AddEventHandler('playerDropped', function()
        local src = source
        CacheAPI.ReloadDBFromCacheRecord("user", src)
        CacheAPI.RemoveFromCache("user", src)
        DebugLog("Dropped User Source", src)
    end)
    
    AddEventHandler('playerConnecting', function(name, kickreason, deferrals)
        local src = source
        local username = string.gsub(name, "%s+", "")

        deferrals.defer()
        Wait(0)

        deferrals.update("Checking Credentials")
        local identifiers = GetIdentifiers(src)
        Wait(0)

        if not identifiers.license then
            deferrals.done("Invalid License")
            return
        elseif not username then
            deferrals.done("Invalid Username")
            return
        else
            deferrals.update("Connecting to server...")
            deferrals.done()
            return
        end
    end)
end