--TODO: once initiate player is called, we need to check that interiors and everything is already loaded in properly. (This means poping up a load screen until it is)

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

function CharacterAPI.CreateCharacter(userid, roldid, firstname, lastname, dob, dollars, gold, xp, x, y, z, lang)
    CharacterController.CreateCharacter(userid, roldid, firstname, lastname, dob, dollars, gold, xp, x, y, z, lang)
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
        TriggerClientEvent("bcc:character:spawn", src, char)
    end
end

function CharacterAPI.RemoveCharacter(src)
    Citizen.CreateThread(function ()
        --TODO: Add a check here if character is in cache, if so then remove

        CacheAPI.ReloadDBFromCacheRecord("character", src)
        CacheAPI.RemoveFromCache("character", src)
    end)
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

----------------------------------
-- Character RPC Registrations --
----------------------------------
RPCAPI.Register("UpdatePlayerCoords", function (coords, res, player)
    local x, y, z = table.unpack(coords)
    CharacterAPI.UpdateCharacterPOS(player, x, y, z)
    return res("Player Coords Updated!")
end)

AddEventHandler('playerDropped', function()
    local src = source
    CharacterAPI.RemoveCharacter(src)

    print("Dropped Character Source", src)
end)


---------------------------------------------------------------------------------------------------
-- Developer Test Commands (THIS IS TEMPORARY AND WILL NEED TO BE DONE BY THE CHARACTER CREATOR) --
---------------------------------------------------------------------------------------------------
if Config.DevMode then
    RegisterCommand('CreateTestCharacter', function(source, args)
        local activeuser = CacheAPI.GetCacheBySrc('user', source)
        CharacterAPI.CreateCharacter(activeuser.id, 1, 'Test', 'Mcgee', '10-10-1941', 0, 0, 0, 0, 0, 0, "en_us")
    end)

    RegisterCommand('GetAvailableCharacters', function(source)
        local available = CharacterAPI.GetAvailableCharactersFromDB(source)
        print("Available Characters:")
        PrettyPrint(available)
    end)

    RegisterCommand('InitiateCharacter', function(source, args)
        CharacterAPI.InitiateCharacter(source, args[1])
    end)
    TriggerEvent("chat:addSuggestion", "/InitiateCharacter", "Initiate a character", {
        { name="CharID", help="character ID to spawn" }
    })

    RegisterCommand('notifytest', function(source)
        NotifyAPI.Notify('TESTING', 2000)
    end)

end
