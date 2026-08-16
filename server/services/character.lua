--------------------
-- Character APIs --
--------------------
CharacterAPI = {}

-- The only character fields resource code should mutate via Add/Subtract
-- (see charClass below). Keeps economy mutation on one validated path.
EconomyKeys = {
    dollars = true,
    gold = true,
    tokens = true,
    xp = true
}

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
        -- (CORE-05) Trusts client-reported coords verbatim and persists them
        -- every 30s -- no speed/bounds sanity check. Flagged, not fixed, in
        -- this pass: deferred because it's inherent to RedM's
        -- client-authoritative movement and this is a dev-only server with
        -- no anti-cheat expectation yet. Revisit before any public launch.
        CacheAPI.UpdateCacheBySrc('character', self.src, "x", x)
        CacheAPI.UpdateCacheBySrc('character', self.src, "y", y)
        CacheAPI.UpdateCacheBySrc('character', self.src, "z", z)
        self.char = CacheAPI.GetCacheBySrc("character", self.src) -- Update the char object to reflect the changes
    end
    -- (CORE-09) `lang` used to be persisted and later used to index
    -- LocalesAPI.translations with no validation -- any string (or nil)
    -- would silently break that player's translated UI from then on. Both
    -- RPC callers (UpdatePlayerLang, SetCharLang) go through this single
    -- method, so validating here covers both at once.
    function charClass:UpdateLang(lang)
        if type(lang) ~= "string" or not LocalesAPI.translations[lang] then
            print(("[feather-core] Rejected UpdateLang: unknown language %s"):format(tostring(lang)))
            return
        end
        CacheAPI.UpdateCacheBySrc('character', self.src, "lang", lang)
        self.char = CacheAPI.GetCacheBySrc("character", self.src)
    end
    function charClass:UpdateAttribute(key, val)
        -- Economy fields must go through Add/Subtract (below) so amounts
        -- are always validated -- never set directly, even server-side.
        if EconomyKeys[key] then
            print("[feather-core] UpdateAttribute rejected for economy key '" .. tostring(key) .. "' -- use Add/Subtract instead")
            return false
        end
        CacheAPI.UpdateCacheBySrc('character', self.src, key, val)
        self.char = CacheAPI.GetCacheBySrc("character", self.src)
        return true
    end

    -- Add and Subtract functions
    -- (Framework decision) These are the ONLY sanctioned way to mutate a
    -- character's economy fields (dollars/gold/tokens/xp). No client RPC
    -- calls these yet, but any future resource (shops, jobs, etc.) must
    -- route mutations through here rather than writing dollars/gold/tokens
    -- directly -- that's what keeps a future "give item" style exploit from
    -- becoming a "give money" exploit. Validates key + amount so a bad
    -- caller can't corrupt the field with a negative/non-numeric amount or
    -- drive a balance negative.
    function charClass:Add(key, amount) -- Add dollars, tokens, gold, xp from character
        if not EconomyKeys[key] then
            print("[feather-core] Add rejected for non-economy key '" .. tostring(key) .. "'")
            return false
        end
        amount = tonumber(amount)
        if not amount or amount < 0 then
            print("[feather-core] Add requires a non-negative numeric amount")
            return false
        end
        CacheAPI.UpdateCacheBySrc('character', self.src, key, (self.char[key] or 0) + amount)
        self.char = CacheAPI.GetCacheBySrc("character", self.src)
        return true
    end
    function charClass:Subtract(key, amount) -- Subtract dollars, tokens, gold, xp from character
        if not EconomyKeys[key] then
            print("[feather-core] Subtract rejected for non-economy key '" .. tostring(key) .. "'")
            return false
        end
        amount = tonumber(amount)
        if not amount or amount < 0 then
            print("[feather-core] Subtract requires a non-negative numeric amount")
            return false
        end
        local current = self.char[key] or 0
        if current < amount then
            print("[feather-core] Subtract rejected: insufficient " .. key)
            return false
        end
        CacheAPI.UpdateCacheBySrc('character', self.src, key, current - amount)
        self.char = CacheAPI.GetCacheBySrc("character", self.src)
        return true
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

-- The scoped character list: the only character ids a given src is allowed
-- to select/load are the ones this returns. Derives ownership purely from
-- `src` -> cached user -> DB, never from anything the client supplies.
function CharacterAPI.GetAvailableCharactersFromDB(src)
    local activeuser = CacheAPI.GetCacheBySrc('user', src)
    if not activeuser then
        return {}
    end
    return CharacterController.GetAvailableCharacters(activeuser.id)
end

function CharacterAPI.GetAllCharacters(src)
    local activeuser = CacheAPI.GetCacheBySrc('user', src)

    return CharacterController.GetAvailableCharacters(activeuser.id)
end

-- (CORE-02) Re-derives the calling player's owned characters server-side and
-- checks charid against that list. This is the ownership gate itself --
-- callers (feather-character, dev commands, anything else) are never
-- trusted just because they first fetched the scoped list; a client can
-- always skip straight to requesting a charid, so the check has to live
-- here, not upstream of here.
function CharacterAPI.IsCharacterOwnedByUser(src, charid)
    if not src or not charid then
        return false
    end

    local owned = CharacterAPI.GetAvailableCharactersFromDB(src)
    for _, c in ipairs(owned) do
        if tostring(c.id) == tostring(charid) then
            return true
        end
    end

    return false
end

-- The framework's permission primitive. The characters table has always
-- carried a role_id -> roles(name, level) join (seeded with 'general'=0,
-- default for every new character, and 'admin'=99), but nothing anywhere in
-- the framework ever checked it -- feather-admin, the one repo that
-- actually needs an authorization gate, previously had none at all. This is
-- the single reusable check any privileged resource should call, re-deriving
-- the caller's role from `source` rather than trusting anything the client
-- claims about itself.
function CharacterAPI.IsAdmin(src)
    local char = CharacterAPI.GetCharacter({ src = src })
    if not char or not char.char or not char.char.level then
        return false
    end
    return char.char.level >= (Config.AdminLevel or 99)
end

function CharacterAPI.InitiateCharacter(src, charid)
    if not src then
        print("Player src must be defined")
        return false
    end

    local tempchar = CacheAPI.GetCacheBySrc("character", src)

    if tempchar then
        print("Character already spawned!")
        return false
    end

    -- (CORE-02) The linchpin fix: charid is client-supplied all the way
    -- down this call chain (feather-character forwards it straight from a
    -- networked event), so it must never be trusted at face value here --
    -- even though the legitimate client flow only ever sends back an id it
    -- got from the scoped list, an executor can call this with any id,
    -- skipping that flow entirely. Character ids are sequential integers,
    -- so this was trivially enumerable/exploitable before this check.
    if not CharacterAPI.IsCharacterOwnedByUser(src, charid) then
        print(("[feather-core] Rejected InitiateCharacter: src %s does not own character %s"):format(src, tostring(charid)))
        return false
    end

    local char = CacheAPI.AddToCache("character", src, charid)
    TriggerClientEvent("Feather:Character:Spawn", src, char)
    return true
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

-- (CORE-04) `state` is a client-decided death flag with no server-side
-- damage/eligibility check, persisted straight to the character. Flagged,
-- not fixed, in this pass -- a real fix needs a server-tracked
-- health/damage source of truth (out of scope here) rather than a
-- point patch on this handler. Safe to defer only because there's no
-- trusted-player server running yet; revisit before that changes.
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