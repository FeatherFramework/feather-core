CharacterController = {}

function CharacterController.CreateCharacter(userID, roleID, firstname, lastname, model, dob, img, dollars, gold, tokens, xp, x, y, z, lang, clothing, attributes, desc)
    return MySQL.query.await(
        "INSERT INTO characters (user_id, role_id, first_name, last_name,model, dob, img, dollars, gold, tokens, xp, x, y, z, lang, clothing, attributes, description, dead) VALUES (@userid, @roleid, @firstname, @lastname, @model, @dob, @img, @dollars, @gold, @tokens, @xp, @x, @y, @z, @lang, @clothing, @attributes, @description, @dead)",
        {
            ['userid'] = userID,
            ['roleid'] = roleID,
            ['firstname'] = firstname,
            ['lastname'] = lastname,
            ['model'] = model,
            ['dob'] = dob,
            ['img'] = img,
            ['dollars'] = dollars,
            ['gold'] = gold,
            ['tokens'] = tokens,
            ['xp'] = xp,
            ['x'] = x,
            ['y'] = y,
            ['z'] = z,
            ['lang'] = lang,
            ['clothing'] = clothing,
            ['attributes'] = attributes,
            ['description'] = desc,
            ['dead'] = 0
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

    if not character then
        print("Character not found for db update")
        return
    end

    --TODO: Make this update dynamic so its not a hard defined list of elelments to update.

    MySQL.query.await(
        "UPDATE characters SET first_name = @firstname, last_name = @lastname, dob = @dob, dollars = @dollars, gold = @gold, tokens = @tokens, xp = @xp, x = @x, y = @y, z = @z, dead = @dead, clothing = @clothing, attributes = @attributes, lang = @lang WHERE id = @id",
        {
            ['firstname'] = character.first_name,
            ['lastname'] = character.last_name,
            ['dob'] = character.dob,
            ['dollars'] = character.dollars,
            ['gold'] = character.gold,
            ['tokens'] = character.tokens,
            ['xp'] = character.xp,
            ['x'] = character.x,
            ['y'] = character.y,
            ['z'] = character.z,
            ['lang'] = character.lang,
            ['id'] = character.id,
            ['clothing'] = character.clothing,
            ['attributes'] = character.attributes,
            ['dead'] = character.dead
        })

    local character = MySQL.query.await(
    "SELECT characters.*, roles.name, roles.level FROM characters INNER JOIN roles ON characters.role_id=roles.id WHERE characters.id = @id",
        { ['id'] = character.id })

    return character
end
