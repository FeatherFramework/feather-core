-- The purpose of this file is to abstract all DB call here for better organization and later optimizations.
UserController = {}

--Returns user data. However, will also check if the userdata exists, if it does not, it will create an accounts.
function UserController.LoadUser(license, timestamp)
    -- Check if player exists, if not lets create them a new record.
    local UserRecord = MySQL.query.await("SELECT users.*, roles.Name, roles.Level FROM users INNER JOIN roles ON users.RoleID=roles.ID WHERE License = @license", { ['license'] = license })  
    
    if not UserRecord or not UserRecord[1] then
        MySQL.query.await(
        "INSERT INTO users (RoleID, Username, License, CreatedAt, UpdatedAt) VALUES (@roleid, @username, @license, @timestamp, @timestamp)",
            { ['roleid'] = 1, ['username'] = username, ['license'] = license,
                ['timestamp'] = timestamp })

        UserRecord = MySQL.query.await("SELECT users.*, roles.Name, roles.Level FROM users INNER JOIN roles ON users.RoleID=roles.ID WHERE License = @license", { ['license'] = license })
        UserRecord = UserRecord[1]
    else
        UserRecord = UserRecord[1]
    end

    return UserRecord
end


function UserController.GetUser(id)
    local user = MySQL.query.await("SELECT * FROM users WHERE ID = @id", { ['id'] = id })
    return user
end

function UserController.UpdateUser(currentUser)
    local timestamp = os.date("%Y-%m-%d %H:%M:%S");

    local updateduser = MySQL.query.await(
        "UPDATE users SET RoleID = @RoleID, UpdatedAt = @timestamp WHERE ID = @UserID",
        {
            ['UserID'] = currentUser.ID,
            ['RoleID'] = currentUser.RoleID,
            ['license'] = currentUser.License,
            ['timestamp'] = timestamp
        })
    return updateduser
end
