-- Setup Global User API
UserAPI = {
    GetUserBySrc = GetUserBySrc,
    GetUserByID = GetUserByID
}

-- User Events
function SetupPlayerEvents()
    AddEventHandler('playerJoining', function()
        local src = source
    end)
    
    AddEventHandler('playerDropped', function()
        local src = source
        RemoveFromUserCache(src)
    end)
    
    -- TODO: Whitelist check (either our own, or we check txadmin whitelist somehow)
    AddEventHandler('playerConnecting', function(name, kickreason, deferrals)
        local src = source
        local license, steam
        local username = string.gsub(name, "%s+", "")
        local identifiers = GetPlayerIdentifiers(src)
        local timestamp = os.date("%Y-%m-%d %H:%M:%S");
    
        deferrals.defer()
        Wait(0)
    
        deferrals.update("Checking Credentials")
        for _, v in pairs(identifiers) do
            if string.find(v, 'license') then
                license = v
            end
    
            if string.find(v, "steam") then
                steam = v
            end
    
            if steam and license then
                break
            end
        end
    
        Wait(0)
    
        if not license then
            deferrals.done("Invalid License")
        elseif not username then
            deferrals.done("Invalid Username")
            return
        elseif not steam then
            deferrals.done("Invalid SteamID")
            return
        else
            deferrals.update("Loading Player")
            AddToUserCache(src, license, steam, timestamp)

            deferrals.done()
        end
    end)
end