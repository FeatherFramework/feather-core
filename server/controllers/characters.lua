-- Raw DB access for the `characters` table. Nothing in this file re-derives
-- or checks identity -- ownership validation happens one layer up, in
-- CharacterAPI (server/services/character.lua). Every SELECT here joins in
-- `roles.name`/`roles.level` so the caller always gets the character's role
-- alongside its data (see CharacterAPI.IsAdmin, which reads `.level` off
-- of this join).
CharacterController = {}

-- Inserts a brand-new character row. Called from feather-character's
-- SaveCharacterData RPC handler once a user finishes character creation.
function CharacterController.CreateCharacter(userID, roleID, firstname, lastname, model, dob, img, dollars, gold, tokens, xp, x, y, z, lang, desc)
    return MySQL.query.await(
        "INSERT INTO characters (user_id, role_id, first_name, last_name,model, dob, img, dollars, gold, tokens, xp, x, y, z, lang, description, dead) VALUES (@userid, @roleid, @firstname, @lastname, @model, @dob, @img, @dollars, @gold, @tokens, @xp, @x, @y, @z, @lang, @description, @dead)",
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
            ['description'] = desc,
            ['dead'] = 0
        })
end

-- Raw lookup by primary key, no ownership check -- callers (CharacterAPI)
-- are responsible for verifying the caller is actually allowed to load
-- this character before calling this.
function CharacterController.GetCharacter(characterID)
    local character = MySQL.query.await(
    "SELECT characters.*, roles.name, roles.level FROM characters INNER JOIN roles ON characters.role_id=roles.id WHERE characters.id = @id",
        { ['id'] = characterID })
    return character[1]
end

-- All characters belonging to a given user id -- this is the actual
-- ownership-scoped query (see CharacterAPI.GetAvailableCharactersFromDB/
-- IsCharacterOwnedByUser, which build the framework's ownership checks on
-- top of this).
function CharacterController.GetAvailableCharacters(userID)
    local characters = MySQL.query.await(
    "SELECT characters.*, roles.name, roles.level FROM characters INNER JOIN roles ON characters.role_id=roles.id WHERE characters.user_id = @UserID",
        { ['UserID'] = userID })
    return characters
end

-- Persists a cached character record back to the DB -- called by
-- CacheAPI.ReloadDBFromCache(Record) on the periodic flush timer and on
-- disconnect, not directly by request handlers.
function CharacterController.UpdateCharacter(character)

    if not character then
        print("Character not found for db update")
        return
    end

    --TODO: Make this update dynamic so its not a hard defined list of elelments to update.

    MySQL.query.await(
        "UPDATE characters SET first_name = @firstname, last_name = @lastname, dob = @dob, dollars = @dollars, gold = @gold, tokens = @tokens, xp = @xp, x = @x, y = @y, z = @z, dead = @dead, lang = @lang WHERE id = @id",
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
            ['dead'] = character.dead
        })

    local character = MySQL.query.await(
    "SELECT characters.*, roles.name, roles.level FROM characters INNER JOIN roles ON characters.role_id=roles.id WHERE characters.id = @id",
        { ['id'] = character.id })

    return character
end
