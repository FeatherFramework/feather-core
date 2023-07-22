RoleCache = {}
UserCache = {}


function SetupCache()
    Citizen.CreateThread(function()
        while true do
            ReloadRoleCache()
            ReloadUserCache()

            Wait(30000) --Refresh Cache Every X miliseconds (Currently 30 seconds)
        end
    end)
end

function ReloadRoleCache()
        local temproles = RoleController.GetAllRoles()
        for _, value in ipairs(temproles) do
            RoleCache[value.ID] = value
        end
end

-- Reload active users data from the DB
function  ReloadUserCache()
    for key, value in pairs(UserCache) do
        local TempUser = UserController.GetUser(UserCache[key].ID)

        if TempUser[1] then
            UserCache[key] = TempUser[1]
        else
            UserCache[key] = nil
        end
    end
end

function AddToUserCache(src, license, steam, timestamp)
    UserCache[src] = UserController.LoadUser(license, steam, timestamp)
end

function RemoveFromUserCache(src)
    UserCache[src] = nil
end

function GetUserBySrc(src)
    return UserCache[src]
end

function GetUserByID(ID)
    local tempuser
    for _, value in pairs(UserCache) do
        if value.ID == ID then
            tempuser = value
            break
        end
    end

    return tempuser
end