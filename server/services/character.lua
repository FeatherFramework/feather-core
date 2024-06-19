--------------------
-- Character APIs --
--------------------
CharacterAPI = {}

-- Character- caching funtions
function CharacterAPI.GetCharacter(opts)
    local char, charClass = nil, {}

    if opts.id ~= nil then
        char = CacheAPI.GetCacheByID("character", opts.id)
        charClass.src = char.src
    elseif opts.src ~= nil then
        char = CacheAPI.GetCacheBySrc("character", opts.src)
        charClass.src = opts.src
    else
        print("Character src or ID must be defined")
        return false
    end

    charClass.char = char

    -- Cache Functions
    function charClass:UpdateCharacterPOS(x, y, z)
        CacheAPI.UpdateCacheBySrc('character', self.src, "x", x)
        CacheAPI.UpdateCacheBySrc('character', self.src, "y", y)
        CacheAPI.UpdateCacheBySrc('character', self.src, "z", z)
        self.char = CacheAPI.GetCacheBySrc("character", self.src) -- Update the char object to reflect the changes
    end
    function charClass:UpdateLang(lang)
        CacheAPI.UpdateCacheBySrc('character', self.src, "lang", lang)
        self.char = CacheAPI.GetCacheBySrc("character", self.src)
    end
    function charClass:UpdateAttribute(key, val)
        CacheAPI.UpdateCacheBySrc('character', self.src, key, val)
        self.char = CacheAPI.GetCacheBySrc("character", self.src)
    end

    -- Add and Subtract functions
    function charClass:Add(key, amount) -- Add dollars, tokens, gold, xp from character
        CacheAPI.UpdateCacheBySrc('character', self.src, key, self.char[key] + amount)
        self.char = CacheAPI.GetCacheBySrc("character", self.src)
    end
    function charClass:Subtract(key, amount) -- Subtract dollars, tokens, gold, xp from character
        CacheAPI.UpdateCacheBySrc('character', self.src, key, self.char[key] - amount)
        self.char = CacheAPI.GetCacheBySrc("character", self.src)
    end

    -- Misc Functions
    function charClass:RemoveCharacter()
        CreateThread(function()
            CacheAPI.ReloadDBFromCacheRecord("character", self.src)
            CacheAPI.RemoveFromCache("character", self.src)
            TriggerEvent("Feather:Character:Logout", self.src)
            DebugLog("Dropped Character Source", self.src)
        end)
    end
    function charClass:Logout()
        self:RemoveCharacter()
    end

    return charClass
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

----------------------------------
-- Character RPC Registrations --
----------------------------------
RPCAPI.Register("UpdatePlayerCoords", function(coords, res, player)
    local x, y, z = table.unpack(coords)
    local char = CharacterAPI.GetCharacter({src = player})
    char:UpdateCharacterPOS(x, y, z)
    return res(char.char)
end)

RPCAPI.Register("UpdatePlayerLang", function(lang, res, player)
    local char = CharacterAPI.GetCharacter({src = player})
    char:UpdateLang(lang)
    return res(char.char)
end)

RPCAPI.Register("GetCharacter", function(_, res, player)
    local char = CharacterAPI.GetCharacter({src = player})
    return res(char.char)
end)

RPCAPI.Register("LogoutCharacter", function(_, res, player)
    local char = CharacterAPI.GetCharacter({src = player})
    char:Logout()
    return res(true)
end)

RPCAPI.Register("CharacterDeath", function(state, res, player)
    local char = CharacterAPI.GetCharacter({src = player})
    char:UpdateAttribute('dead', state)
    return res(true)
end)

AddEventHandler('playerDropped', function()
    local char = CharacterAPI.GetCharacter({src = source})

    if char ~= nil then
        char:RemoveCharacter()
    end
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