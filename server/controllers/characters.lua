CharacterController = {}

function CharacterController.CreateCharacter(userID, roleID, firstname, lastname, dob, dollars, gold, xp, x, y, z, lang)
    local timestamp = os.date("%Y-%m-%d %H:%M:%S");

    return MySQL.query.await(
        "INSERT INTO characters (user_id, role_id, first_name, last_name, dob, dollars, gold, xp, x, y, z, lang, created_at, updated_at) VALUES (@userid, @roleid, @firstname, @lastname, @dob, @dollars, @gold, @xp, @x, @y, @z, @lang, @timestamp, @timestamp)",
        {
            ['userid'] = userID,
            ['roleid'] = roleID,
            ['firstname'] = firstname,
            ['lastname'] = lastname,
            ['dob'] = dob,
            ['dollars'] = dollars,
            ['gold'] = gold,
            ['xp'] = xp,
            ['x'] = x,
            ['y'] = y,
            ['z'] = z,
            ['lang'] = lang,
            ['timestamp'] = timestamp
        })
end

--Returns user data. However, will also check if the userdata exists, if it does not, it will create an accounts.
function CharacterController.GetCharacter(characterID)
    local character = MySQL.query.await(
    "SELECT characters.*, roles.name, roles.level FROM characters INNER JOIN roles ON characters.role_id=roles.id WHERE characters.id = @id",
        { ['id'] = characterID })
    return character[1]
end

function CharacterController.GetAvailableCharacters(userID)
    local characters = MySQL.query.await(
    "SELECT characters.*, roles.name, roles.level FROM characters INNER JOIN roles ON characters.role_id=roles.id WHERE characters.user_id = @UserID",
        { ['UserID'] = userID })
    return characters
end

function CharacterController.UpdateCharacter(character)
    local timestamp = os.date("%Y-%m-%d %H:%M:%S");

    if not character then
        print("Character not found for db update")
        return
    end

    MySQL.query.await(
        "UPDATE characters SET first_name = @firstname, last_name = @lastname, dob = @dob, dollars = @dollars, gold = @gold, xp = @xp, x = @x, y = @y, z = @z, lang = @lang, updated_at = @timestamp WHERE id = @id",
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
            ['lang'] = character.lang,
            ['timestamp'] = timestamp,
            ['id'] = character.id,
        })

    local character = MySQL.query.await(
    "SELECT characters.*, roles.name, roles.level FROM characters INNER JOIN roles ON characters.role_id=roles.id WHERE characters.id = @id",
        { ['id'] = character.id })

    return character
end
