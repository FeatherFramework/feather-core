-- The purpose of this file is to abstract all DB call here for better organization and later optimizations.
UserController = {}

--Returns user data. However, will also check if the userdata exists, if it does not, it will create an accounts.
function UserController.LoadUser(username, license, timestamp)
    -- Check if player exists, if not lets create them a new record.
    local UserRecord = MySQL.query.await("SELECT users.*, roles.name, roles.level FROM users INNER JOIN roles ON users.role_id=roles.id WHERE license = @license", { ['license'] = license })  
    
    if not UserRecord or not UserRecord[1] then
        MySQL.query.await(
        "INSERT INTO users (role_id, username, license, created_at, updated_at) VALUES (@roleid, @username, @license, @timestamp, @timestamp)",
            { ['roleid'] = 1, ['username'] = username, ['license'] = license,
                ['timestamp'] = timestamp })

        UserRecord = MySQL.query.await("SELECT users.*, roles.name, roles.level FROM users INNER JOIN roles ON users.role_id=roles.id WHERE license = @license", { ['license'] = license })
        UserRecord = UserRecord[1]
    else
        UserRecord = UserRecord[1]
    end

    return UserRecord
end


function UserController.GetUser(id)
    local user = MySQL.query.await("SELECT * FROM users WHERE id = @id", { ['id'] = id })
    return user
end

function UserController.UpdateUser(currentUser)
    local timestamp = os.date("%Y-%m-%d %H:%M:%S");

    local updateduser = MySQL.query.await(
        "UPDATE users SET role_id = @RoleID, updated_at = @timestamp WHERE id = @UserID",
        {
            ['UserID'] = currentUser.id,
            ['RoleID'] = currentUser.role_id,
            ['license'] = currentUser.license,
            ['timestamp'] = timestamp
        })
    return updateduser
end
