-- Raw DB access for the `characters` table. Nothing in this file re-derives
-- or checks identity -- ownership validation happens one layer up, in
-- CharacterAPI (server/services/character.lua). Every SELECT here joins in
-- aliased role fields so they cannot collide with future character columns
-- alongside its data (see CharacterAPI.IsAdmin, which reads `.role_level` off
-- of this join).
CharacterController = {}

-- `first_spawn` distinguishes a brand-new character's very first spawn
-- (placed at a designer-picked town coordinate from feather-character's
-- creation flow -- may need surface-correction, same as the hospital
-- respawn locations) from every subsequent login (an exact, previously-
-- occupied position that must NOT be surface-corrected). See
-- CharacterAPI.InitiateCharacter's one-shot read+clear of it below, and the
-- client's use of it in client/services/character.lua's
-- "Feather:Character:Spawn" handler.
local function EnsureFirstSpawnColumn()
    local columns = MySQL.query.await("SHOW COLUMNS FROM `characters` LIKE 'first_spawn';")
    if #columns < 1 then
        MySQL.query.await("ALTER TABLE `characters` ADD COLUMN `first_spawn` TINYINT(1) NOT NULL DEFAULT 1;")
    end
end

CreateThread(function()
    EnsureFirstSpawnColumn()
end)

-- One-shot: clears the flag once a character has actually been placed at
-- its first spawn so every later login skips surface-finding.
function CharacterController.ClearFirstSpawn(characterID)
    MySQL.query.await("UPDATE characters SET first_spawn = 0 WHERE id = @id", { ['id'] = characterID })
end

-- Inserts a brand-new character row. Called from feather-character's
-- SaveCharacterData RPC handler once a user finishes character creation.
-- (CHAR-07/TOCTOU) Was MySQL.query.await, whose return for an INSERT is an
-- OkPacket-shaped table, not a usable id -- callers had no way to learn the
-- new row's id except re-deriving it with a separate SELECT, which is where
-- CHAR-07's wrong-character-id race lived. MySQL.insert.await returns the
-- real insertId directly (the convention already used elsewhere in the
-- framework, e.g. feather-admin's audit_log.lua), so the caller never needs
-- to re-derive it.
function CharacterController.CreateCharacter(userID, roleID, firstname, lastname, model, dob, img, dollars, gold, tokens, xp, x, y, z, lang, desc)
    return MySQL.insert.await(
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
    "SELECT characters.*, roles.name AS role_name, roles.level AS role_level FROM characters INNER JOIN roles ON characters.role_id=roles.id WHERE characters.id = @id",
        { ['id'] = characterID })
    return character[1]
end

-- All characters belonging to a given user id -- this is the actual
-- ownership-scoped query (see CharacterAPI.GetAvailableCharactersFromDB/
-- IsCharacterOwnedByUser, which build the framework's ownership checks on
-- top of this).
function CharacterController.GetAvailableCharacters(userID)
    local characters = MySQL.query.await(
    "SELECT characters.*, roles.name AS role_name, roles.level AS role_level FROM characters INNER JOIN roles ON characters.role_id=roles.id WHERE characters.user_id = @UserID",
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
    "SELECT characters.*, roles.name AS role_name, roles.level AS role_level FROM characters INNER JOIN roles ON characters.role_id=roles.id WHERE characters.id = @id",
        { ['id'] = character.id })

    return character
end
