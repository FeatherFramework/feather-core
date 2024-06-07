--------------------
-- Character APIs --
--------------------
CharacterAPI = {}

-- Character- caching funtions
function CharacterAPI.GetCharacterBySrc(src)
    return CacheAPI.GetCacheBySrc("character", src)
end

function CharacterAPI.GetCharacterByID(ID)
    return CacheAPI.GetCacheByID("character", ID)
end

function CharacterAPI.CreateCharacter(userid, roldid, firstname, lastname, model, dob,img, dollars, gold, tokens, xp, x, y, z, lang, desc)
    CharacterController.CreateCharacter(userid, roldid, firstname, lastname, model, dob, img, dollars, gold, tokens, xp, x, y, z, lang, desc)
end

function CharacterAPI.GetAvailableCharactersFromDB(src)
    local activeuser = CacheAPI.GetCacheBySrc('user', src)
    return CharacterController.GetAvailableCharacters(activeuser.id)
end

function CharacterAPI.GetAllCharacters(src)
    local activeuser = CacheAPI.GetCacheBySrc('user', src)

    return CharacterController.GetAvailableCharacters(activeuser.id)
end

function CharacterAPI.InitiateCharacter(src, charid)
    if not src then
        print("Player src must be defined")
        return
    end

    local tempchar = CacheAPI.GetCacheBySrc("character", src)

    if tempchar then
        print("Character already spawned!")
        return
    else
        local char = CacheAPI.AddToCache("character", src, charid)
        TriggerClientEvent("Feather:Character:Spawn", src, char)
    end
end

function CharacterAPI.RemoveCharacter(src)
    CreateThread(function()
        CacheAPI.ReloadDBFromCacheRecord("character", src)
        CacheAPI.RemoveFromCache("character", src)
        TriggerEvent("Feather:Character:Logout", src)
        DebugLog("Dropped Character Source", src)
    end)
end

function CharacterAPI.Logout(src)
    CharacterAPI.RemoveCharacter(src)
end

function CharacterAPI.UpdateCharacterPOS(src, x, y, z)
    CacheAPI.UpdateCacheBySrc('character', src, "x", x)
    CacheAPI.UpdateCacheBySrc('character', src, "y", y)
    CacheAPI.UpdateCacheBySrc('character', src, "z", z)
end

function CharacterAPI.UpdateLang(src, lang)
    CacheAPI.UpdateCacheBySrc('character', src, "lang", lang)
end

function CharacterAPI.UpdateAttribute(src, key, val)
    CacheAPI.UpdateCacheBySrc('character', src, key, val)
end

-- Add dollars, tokens, gold, xp from character
function CharacterAPI.Add(src, key, amount)
    local activeCharacter = CacheAPI.GetCacheBySrc('character', src)
    local total = activeCharacter[key] + amount
    CacheAPI.UpdateCacheBySrc('character', src, key, total)
end

-- Subtract dollars, tokens, gold, xp from character
function CharacterAPI.Subtract(src, key, amount)
    local activeCharacter = CacheAPI.GetCacheBySrc('character', src)
    local total = activeCharacter[key] - amount
    CacheAPI.UpdateCacheBySrc('character', src, key, total)
end

----------------------------------
-- Character RPC Registrations --
----------------------------------
RPCAPI.Register("UpdatePlayerCoords", function(coords, res, player)
    local x, y, z = table.unpack(coords)
    CharacterAPI.UpdateCharacterPOS(player, x, y, z)
    return res(CharacterAPI.GetCharacterBySrc(player))
end)

RPCAPI.Register("UpdatePlayerLang", function(lang, res, player)
    CharacterAPI.UpdateLang(player, lang)
    return res(CharacterAPI.GetCharacterBySrc(player))
end)

RPCAPI.Register("GetCharacter", function(_, res, player)
    return res(CharacterAPI.GetCharacterBySrc(player))
end)

RPCAPI.Register("LogoutCharacter", function(_, res, player)
    CharacterAPI.Logout(source)
    return res(true)
end)

RPCAPI.Register("CharacterDeath", function(state, res, player)
    print('Character dead!', state)
    CharacterAPI.UpdateAttribute(player, 'dead', state)
    return res(true)
end)

AddEventHandler('playerDropped', function()
    local src = source
    CharacterAPI.RemoveCharacter(src)
end)


---------------------------------------------------------------------------------------------------
-- Developer Test Commands (THIS IS TEMPORARY AND WILL NEED TO BE DONE BY THE CHARACTER CREATOR) --
---------------------------------------------------------------------------------------------------
if Config.DevMode then
    RegisterCommand('CreateTestCharacter', function(source, args)
        local activeuser = CacheAPI.GetCacheBySrc('user', source)
        CharacterAPI.CreateCharacter(activeuser.id, 1, 'Test', 'Mcgee', 'somemodel', '10-10-1941', 'someimage', 0, 0, 0, 0, 0, 0, 0, "en_us", '')
    end)

    RegisterCommand('GetAvailableCharacters', function(source)
        local available = CharacterAPI.GetAvailableCharactersFromDB(source)
        print("Available Characters:")
        PrettyPrint(available)
    end)

    RegisterCommand('InitiateCharacter', function(source, args)
        if args[1] == nil then
            print("must have character id")
            return
        end

        CharacterAPI.InitiateCharacter(source, args[1])
    end)
    TriggerClientEvent("chat:addSuggestion", "/InitiateCharacter", "Initiate a character", {
        { name = "CharID", help = "character ID to spawn" }
    })
end