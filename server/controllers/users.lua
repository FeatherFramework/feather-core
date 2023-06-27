-- The purpose of this file is to abstract all DB call here for better organization and later optimizations.
UserController = {}

--TODO: Potentially do an innerjoin on the LoadUser to include the Jobs info with the playerdata instead of a seperate role cache. Or not.

--Returns user data. However, will also check if the userdata exists, if it does not, it will create an accounts.
function UserController.LoadUser(license, steam, timestamp)
    -- Check if player exists, if not lets create them a new record.
    local UserRecord = MySQL.query.await("SELECT * FROM users WHERE License = @license", { ['license'] = license })
    if not UserRecord or not UserRecord[1] then
        UserRecord = MySQL.query.await(
        "INSERT INTO users (RoleID, Username, License, SteamID, CreatedAt, UpdatedAt) VALUES (@roleid, @username, @license, @steamid, @timestamp, @timestamp)",
            { ['roleid'] = 1, ['username'] = username, ['license'] = license, ['steamid'] = steam,
                ['timestamp'] = timestamp })
    else
        UserRecord = UserRecord[1]
    end

    return UserRecord
end


function UserController.GetUser(id)
    return MySQL.query.await("SELECT * FROM users WHERE ID = @id", { ['id'] = id })
end