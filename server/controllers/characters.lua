CharacterController = {}

function CharacterController.CreateCharacter(userID, firstname, lastname, dob, dollars, gold, xp, x, y, z)
    local timestamp = os.date("%Y-%m-%d %H:%M:%S");

    return MySQL.query.await(
        "INSERT INTO characters (UserID, FirstName, LastName, DOB, Dollars, Gold, XP, X, Y, Z, CreatedAt, UpdatedAt) VALUES (@userid, @firstname, @lastname, @dob, @dollars, @gold, @xp, @x, @y, @z, @timestamp, @timestamp)",
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
    local character = MySQL.query.await("SELECT * FROM characters WHERE ID = @ID", { ['ID'] = characterID })
    return character[1]
end

function CharacterController.GetAvailableCharacters(UserID)
    local characters = MySQL.query.await("SELECT * FROM characters WHERE UserID = @UserID", { ['UserID'] = UserID })
    return characters
end

function CharacterController.UpdateCharacter(character)
    local timestamp = os.date("%Y-%m-%d %H:%M:%S");

    if not character then
        print("Character not found for db update")
        return
    end

    local updatedCharacter MySQL.query.await(
        "UPDATE characters SET FirstName = @firstname, LastName = @lastname, DOB = @dob, Dollars = @dollars, Gold = @gold, XP = @xp, X = @x, Y = @y, Z = @z, UpdatedAt = @timestamp WHERE ID = @id",
        {
            ['firstname'] = character.FirstName,
            ['lastname'] = character.LastName,
            ['dob'] = character.DOB,
            ['dollars'] = character.Dollars,
            ['gold'] = character.Gold,
            ['xp'] = character.XP,
            ['x'] = character.X,
            ['y'] = character.Y,
            ['z'] = character.Z,
            ['timestamp'] = timestamp,
            ['id'] = character.ID,
        })

    return updatedCharacter
end
