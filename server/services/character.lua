--TODO: For player spawn, dont spawn (show loadscreen), until ClientReady is true

--------------------
-- Character APIs --
--------------------
CharacterAPI = {
    GetCharacterBySrc = GetCharacterBySrc,
    GetCharacterByID = GetCharacterByID
}

function CharacterAPI.CreateCharacter(userid, firstname, lastname, dob, dollars, gold, xp, x, y, z)
    CharacterController.CreateCharacter(userid, firstname, lastname, dob, dollars, gold, xp, x, y, z)
end

function CharacterAPI.GetAvailableCharactersFromDB(src)
    local activeuser = CacheAPI.GetCacheBySrc('user', src)
    return CharacterController.GetAvailableCharacters(activeuser.ID)
end

function CharacterAPI.SpawnCharacter(src, charid)
    if not src then
        print("Player src  ust be defined")
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

function CharacterAPI.DespawnCharacter(src)
    Citizen.CreateThread(function ()
        CacheAPI.ReloadCacheRecord("character", src)
        CacheAPI.RemoveFromCache("character", src)
    end)
end

function CharacterAPI.UpdateCharacterPOS(src, x, y, z)
    CacheAPI.UpdateCacheBySrc('character', src, "X", x)
    CacheAPI.UpdateCacheBySrc('character', src, "Y", y)
    CacheAPI.UpdateCacheBySrc('character', src, "Z", z)
end

----------------------------------
-- Character RPCS Registrations --
----------------------------------
--TODO:Update POS DB along with cache as pos should always be live.
RPCAPI.Register("UpdatePlayerCoords", function (coords, res, player)
    local x, y, z = table.unpack(coords)
    CharacterAPI.UpdateCharacterPOS(player, x, y, z)

    return res("Player Coords Updated!")
end)


AddEventHandler('playerDropped', function()
    local src = source
    CharacterAPI.DespawnCharacter(src)

    print("Dropped Character Source", src)
end)
---------------------------------------------------------------------------------------------------
-- Developer Test Commands (THIS IS TEMPORARY AND WILL NEED TO BE DONE BY THE CHARACTER CREATOR) --
---------------------------------------------------------------------------------------------------

if Config.DevMode then
    RegisterCommand('CreateTestCharacter', function(source, args)
        local activeuser = CacheAPI.GetCacheBySrc('user', source)
        CharacterAPI.CreateCharacter(activeuser.ID, 'Test', 'Mcgee', '10-10-1941', 0, 0, 0, 0, 0, 0)
    end)

    RegisterCommand('GetAvailableCharacters', function(source)
        local available = CharacterAPI.GetAvailableCharactersFromDB(source)
        print("Available Characters:")
        PrettyPrint(available)
    end)

    RegisterCommand('SpawnCharacter', function(source, args)
        CharacterAPI.SpawnCharacter(source, args[1])
    end)
end
