CharacterController = {}

function CharacterController.CreateCharacter(userID, firstname, lastname, dob, dollars, gold, xp, x, y, z)
    local timestamp = os.date("%Y-%m-%d %H:%M:%S");

    return MySQL.query.await(
        "INSERT INTO characters (user_id, first_name, last_name, dob, dollars, gold, xp, x, y, z, created_at, updated_at) VALUES (@userid, @firstname, @lastname, @dob, @dollars, @gold, @xp, @x, @y, @z, @timestamp, @timestamp)",
        {
            ['userid'] = userID,
            ['firstname'] = firstname,
            ['lastname'] = lastname,
            ['dob'] = dob,
            ['dollars'] = dollars,
            ['gold'] = gold,
            ['xp'] = xp,
            ['x'] = x,
            ['y'] = y,
            ['z'] = z,
            ['timestamp'] = timestamp
        })
end

--Returns user data. However, will also check if the userdata exists, if it does not, it will create an accounts.
function CharacterController.GetCharacter(characterID)
    local character = MySQL.query.await("SELECT * FROM characters WHERE id = @id", { ['id'] = characterID })
    return character[1]
end

function CharacterController.GetAvailableCharacters(userID)
    local characters = MySQL.query.await("SELECT * FROM characters WHERE user_id = @UserID", { ['UserID'] = userID })
    return characters
end

function CharacterController.UpdateCharacter(character)
    local timestamp = os.date("%Y-%m-%d %H:%M:%S");

    if not character then
        print("Character not found for db update")
        return
    end

    local updatedCharacter MySQL.query.await(
        "UPDATE characters SET first_name = @firstname, last_name = @lastname, dob = @dob, dollars = @dollars, gold = @gold, xp = @xp, x = @x, y = @y, z = @z, updated_at = @timestamp WHERE id = @id",
        {
            ['firstname'] = character.first_name,
            ['lastname'] = character.last_name,
            ['dob'] = character.dob,
            ['dollars'] = character.dollars,
            ['gold'] = character.gold,
            ['xp'] = character.xp,
            ['x'] = character.x,
            ['y'] = character.y,
            ['z'] = character.z,
            ['timestamp'] = timestamp,
            ['id'] = character.id,
        })

    return updatedCharacter
end
