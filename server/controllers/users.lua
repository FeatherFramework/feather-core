-- The purpose of this file is to abstract all DB call here for better organization and later optimizations.
UserController = {}

--Returns user data. However, will also check if the userdata exists, if it does not, it will create an accounts.
function UserController.LoadUser(username, license)
    -- Check if player exists, if not lets create them a new record.
    local UserRecord = MySQL.query.await("SELECT * FROM users WHERE license = @license", { ['license'] = license })
    
    if not UserRecord or not UserRecord[1] then
        MySQL.query.await(
        "INSERT INTO users (username, license) VALUES (@username, @license)",
            { ['username'] = username, ['license'] = license })

        UserRecord = MySQL.query.await("SELECT * FROM users WHERE license = @license", { ['license'] = license })
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

-- For now there isnt anything to update, but there will be at sompoint.
function UserController.UpdateUser(currentUser)
    -- local updateduser = MySQL.query.await(
    --     "UPDATE users SET updated_at = @timestamp WHERE id = @UserID",
    --     {
    --         ['UserID'] = currentUser.id,
    --         ['timestamp'] = timestamp
    --     })
    return {}
end
