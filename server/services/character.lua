--------------------
-- Character APIs --
--------------------
CharacterAPI = {}

-- A character session identifies one specific source -> character binding.
-- It is runtime-only: reconnecting, switching characters, or restarting core
-- creates a different session and invalidates in-flight work.
local CharacterSessions = {}
local CharacterSessionGenerations = {}

local function NextCharacterSessionId(src, characterId)
    local generation = (CharacterSessionGenerations[src] or 0) + 1
    CharacterSessionGenerations[src] = generation
    return ('%s:%s:%s:%s'):format(tostring(src), tostring(characterId), tostring(generation), tostring(GetGameTimer()))
end

local function BeginCharacterSession(src, character)
    local session = {
        source = src,
        characterId = character.id,
        sessionId = NextCharacterSessionId(src, character.id),
        state = 'ready',
        startedAt = os.time()
    }
    CharacterSessions[src] = session
    return session
end

local function BeginCharacterLeaving(src, reason)
    local session = CharacterSessions[src]
    if not session or session.state ~= 'ready' then return nil end

    session.state = 'leaving'
    session.reason = reason or 'logout'
    session.leavingAt = os.time()
    TriggerEvent('Feather:Server:Character:Leaving', session)
    return session
end

local function CompleteCharacterLeaving(src, session)
    if CharacterSessions[src] == session then CharacterSessions[src] = nil end
    if not session then return end

    session.state = 'left'
    session.leftAt = os.time()
    TriggerEvent('Feather:Server:Character:Left', session)
end

function CharacterAPI.GetSession(src)
    local session = CharacterSessions[tonumber(src) or src]
    if not session or session.state ~= 'ready' then return nil end
    return {
        source = session.source,
        characterId = session.characterId,
        sessionId = session.sessionId,
        state = session.state,
        startedAt = session.startedAt
    }
end

function CharacterAPI.ResolveSession(src)
    local session = CharacterAPI.GetSession(src)
    if not session then return nil end

    local character = CacheAPI.GetCacheBySrc('character', src)
    if not character or tostring(character.id) ~= tostring(session.characterId) then return nil end
    session.character = character
    return session
end

function CharacterAPI.IsSessionCurrent(src, sessionId, characterId)
    local session = CharacterSessions[tonumber(src) or src]
    if not session or session.state ~= 'ready' or session.sessionId ~= sessionId then return false end
    if characterId ~= nil and tostring(session.characterId) ~= tostring(characterId) then return false end
    return true
end

function CharacterAPI.GetCapabilities()
    return {
        contractVersion = 1,
        characterSessions = true,
        lifecycle = {
            ready = 'Feather:Server:Character:Ready',
            leaving = 'Feather:Server:Character:Leaving',
            left = 'Feather:Server:Character:Left'
        },
        rpc = { requireCharacter = true, correlationId = true, lateResponseRejection = true }
    }
end

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
        -- every 30s -- no speed sanity check. Flagged, not fixed, in this
        -- pass: deferred because it's inherent to RedM's client-authoritative
        -- movement and this is a dev-only server with no anti-cheat
        -- expectation yet. Revisit before any public launch.
        --
        -- (CORE-32) Range IS enforced now, though: `characters.x/y/z` are
        -- `decimal(15,10)` (5 digits before the point), so a client sending
        -- something like `x = 1e9` produced an out-of-range DB error ~30s
        -- later on the cache flush thread -- which had no per-row pcall
        -- (see CacheAPI.ReloadDBFromCache) and so died permanently, silently
        -- ending persistence for every player until restart. 50000 is far
        -- outside any real RDR3 map coordinate but safely inside the
        -- column's range.
        if type(x) ~= 'number' or type(y) ~= 'number' or type(z) ~= 'number'
            or math.abs(x) > 50000 or math.abs(y) > 50000 or math.abs(z) > 50000 then
            print(("[feather-core] Rejected UpdateCharacterPOS: out-of-range coords from src %s (%s, %s, %s)")
                :format(tostring(self.src), tostring(x), tostring(y), tostring(z)))
            return
        end
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
    function charClass:Add(key, amount)
    if not EconomyKeys[key] then
        print("[feather-core] Add rejected for non-economy key '" .. tostring(key) .. "'")
        return false
    end

    amount = tonumber(amount)
    if not amount or amount ~= amount or amount == math.huge or amount < 0 then
        print("[feather-core] Add requires a non-negative numeric amount")
        return false
    end

    -- API objects crossing a resource boundary contain a marshaled snapshot.
    -- Always calculate from Core's live cache so concurrent adjustments do
    -- not overwrite one another using an older balance.
    local cached = CacheAPI.GetCacheBySrc('character', self.src)
    if not cached then
        print("[feather-core] Add rejected: character cache not found")
        return false
    end

    local current = tonumber(cached[key])
    if current == nil or current ~= current or current == math.huge or current == -math.huge then
        print("[feather-core] Add rejected: invalid current " .. key .. " balance")
        return false
    end

    CacheAPI.UpdateCacheBySrc('character', self.src, key, current + amount)
    self.char = CacheAPI.GetCacheBySrc("character", self.src)
    -- Live push so HUD-style displays (e.g. feather-hud's resource strip)
    -- update immediately instead of only on the next spawn/full refresh.
    TriggerClientEvent("Feather:Character:EconomyUpdated", self.src, self.char)
    return true
end

function charClass:Subtract(key, amount)
    if not EconomyKeys[key] then
        print("[feather-core] Subtract rejected for non-economy key '" .. tostring(key) .. "'")
        return false
    end

    amount = tonumber(amount)
    if not amount or amount ~= amount or amount == math.huge or amount < 0 then
        print("[feather-core] Subtract requires a non-negative numeric amount")
        return false
    end

    -- Read from the authoritative cache for the same reason as Add above.
    local cached = CacheAPI.GetCacheBySrc('character', self.src)
    if not cached then
        print("[feather-core] Subtract rejected: character cache not found")
        return false
    end

    local current = tonumber(cached[key])
    if current == nil or current ~= current or current == math.huge or current == -math.huge then
        print("[feather-core] Subtract rejected: invalid current " .. key .. " balance")
        return false
    end

    if current < amount then
        print("[feather-core] Subtract rejected: insufficient " .. key)
        return false
    end

    CacheAPI.UpdateCacheBySrc('character', self.src, key, current - amount)
    self.char = CacheAPI.GetCacheBySrc("character", self.src)
    TriggerClientEvent("Feather:Character:EconomyUpdated", self.src, self.char)
    return true
end

    -- Misc Functions
    function charClass:RemoveCharacter(reason)
        local session = BeginCharacterLeaving(self.src, reason)
        if not session then return false end

        CreateThread(function()
            CacheAPI.ReloadDBFromCacheRecord("character", self.src)
            CacheAPI.RemoveFromCache("character", self.src)
            TriggerEvent("Feather:Character:Logout", self.src)
            CompleteCharacterLeaving(self.src, session)
            DebugLog("Dropped Character Source", self.src)
        end)
        return true
    end
    function charClass:Logout()
        return self:RemoveCharacter('logout')
    end

    return charClass
end

function CharacterAPI.CreateCharacter(userid, roldid, firstname, lastname, model, dob,img, dollars, gold, tokens, xp, x, y, z, lang, desc)
    -- (CORE-21) Was dropping CharacterController.CreateCharacter's return
    -- value entirely -- callers (feather-character's character-creation
    -- flow) always got nil back instead of the new row/id.
    return CharacterController.CreateCharacter(userid, roldid, firstname, lastname, model, dob, img, dollars, gold, tokens, xp, x, y, z, lang, desc)
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
    if not char or not char.char or not char.char.role_level then
        return false
    end
    local roleLevel = tonumber(char.char.role_level)
    return roleLevel ~= nil and roleLevel >= (Config.AdminLevel or 99)
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

    local session = BeginCharacterSession(src, char)

    -- `char.first_spawn` (see controllers/characters.lua) is read here and
    -- immediately cleared in the DB so this is the only spawn that ever
    -- sees it set -- the client uses it to decide whether to surface-find
    -- this placement (first-ever spawn, a designer-picked town coordinate)
    -- or trust it exactly (every later login, a previously-occupied
    -- position).
    if tonumber(char.first_spawn) == 1 then
        CharacterController.ClearFirstSpawn(charid)
    end

    TriggerClientEvent("Feather:Character:Spawn", src, char)

    -- (INV-13) Server-internal signal for other resources (feather-inventory,
    -- feather-weapons, ...) that need to react to a spawn with a trustworthy
    -- character id. `char` and `src` are both authoritative here -- ownership
    -- was just verified above -- unlike the client's re-broadcast
    -- `TriggerServerEvent("Feather:Character:Spawned", ...)`, which any
    -- client can call directly with a forged character. TriggerEvent only,
    -- never networked.
    TriggerEvent("Feather:Server:Character:Spawned", char, src)
    TriggerEvent("Feather:Server:Character:Ready", {
        source = session.source,
        characterId = session.characterId,
        sessionId = session.sessionId,
        state = session.state,
        startedAt = session.startedAt
    }, char)
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

RPCAPI.Register("LogoutCharacter", function(coords, res, player)
    local char = CharacterAPI.GetCharacter({src = player})

    if not char or not char.char then
        return res(false)
    end

    local x, y, z = table.unpack(coords or {})
    x, y, z = tonumber(x), tonumber(y), tonumber(z)
    if x and y and z then
        char:UpdateCharacterPOS(x, y, z)
    else
        print(("[feather-core] LogoutCharacter received invalid coordinates from source %s"):format(tostring(player)))
    end

    char:Logout()
    return res(true)
end)

-- (CORE-04) `state` is a client-decided death flag with no server-side
-- damage/eligibility check, persisted straight to the character. Flagged,
-- not fixed -- and, after actually verifying it against the CFX source
-- rather than assuming, not fixable as a point patch on this handler at
-- all on RedM today:
--
--   * GET_ENTITY_HEALTH is registered server-side (ServerGameState_Scripting.cpp),
--     but reads through syncTree->GetPedHealth() -- and RDR3's sync tree
--     (SyncTrees_RDR3.h) hardcodes that accessor to `return nullptr;`,
--     unlike FiveM's (SyncTrees_Five.h), which actually pulls the synced
--     node. Confirmed by reading both, not assumed. Always returns 0
--     server-side for any RedM ped, healthy or not.
--   * The native event queue behind EVENT_NETWORK_DAMAGE_ENTITY /
--     EVENT_ENTITY_DESTROYED (GET_NUMBER_OF_EVENTS / GET_EVENT_AT_INDEX)
--     has no server-side implementation in citizen-server-impl at all
--     (grep-confirmed) -- client-observed only, for either game.
--   * IS_PLAYER_DEAD is client-API-set only; no server equivalent exists
--     to even attempt.
--
-- Every path bottoms out at the same wall: there is no server-side
-- vantage point on RedM that observes a player's actual health/death
-- state independent of that same player's client telling it. This isn't
-- a gap in this handler, it's the current shape of the platform. A real
-- improvement here is graduated trust, not verification: relay the richer
-- native event payload (killer/weapon/coords) instead of a bare boolean,
-- corroborate against IS_PLAYER_DEAD via a server-initiated RPC poll, and
-- gate anything economically consequential (bounties, insurance, loot)
-- behind that corroboration -- while accepting a determined client can
-- still fake all of it at once, and keeping the cosmetic "show the death
-- screen" path cheap and trusting since faking that only griefs yourself.
-- Log claims either way so a real anti-cheat/admin pass has signal to
-- work with. Revisit if RedM ever ships a real server-side health sync.
RPCAPI.Register("CharacterDeath", function(state, res, player)
    -- `state` still can't be verified server-side (see the note above), but
    -- it can at least be locked to the two values this framework actually
    -- understands -- 0 (alive) or 1 (dead) -- instead of accepting whatever
    -- a client sends verbatim.
    local deadState = tonumber(state)
    if deadState ~= 0 and deadState ~= 1 then
        return res(false)
    end

    local char = CharacterAPI.GetCharacter({src = player})
    if not char or not char.char then
        return res(false)
    end

    char:UpdateAttribute('dead', deadState)
    return res(true)
end)

AddEventHandler('playerDropped', function()
    local char = CharacterAPI.GetCharacter({src = source})

    if char ~= nil then
        char:RemoveCharacter('disconnect')
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
