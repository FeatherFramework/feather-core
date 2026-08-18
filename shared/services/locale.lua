LocalesAPI = {}
LocalesAPI.translations = {}

-- (CORE-17) `LocalesAPI.translate` used to round-trip the "GetCharLang" RPC
-- to the server on every single call -- every translated string in every
-- UI, every frame it's redrawn. Cache the resolved language client-side
-- instead: seeded from the character payload the server already sends on
-- spawn (no extra RPC needed for that), refreshed by LocalesAPI.SetClientLang
-- whenever the language actually changes (see client/services/ui.lua's
-- 'updatelocale' NUI callback), and falls back to the RPC only if translate()
-- is ever called before either of those has populated it.
local ClientLangCache = nil

function LocalesAPI.SetClientLang(lang)
    ClientLangCache = lang
end

if not IsOnServer() then
    RegisterNetEvent("Feather:Character:Spawn", function(character)
        ClientLangCache = character and character.lang or ClientLangCache
    end)
end

local function getLang(src)
    if IsOnServer() then
        local char = CharacterAPI.GetCharacter({ src = src})
        if not char or not char.char or not char.char.lang then
            return Config.DefaultLang
        else
            return char.char.lang
        end
    else
        print('Not for use on client')
    end
end

--This handles syncing the translations between client/server.
-- (CORE-01) Previously did `LocalesAPI.translations = params.translations`,
-- which let any unauthenticated caller (this RPC has no IsOnServer guard,
-- since e.g. feather-admin's client-only translations legitimately need to
-- reach the server this way) replace the ENTIRE global translation table,
-- wiping every other resource's locale strings for every player. Fixed to
-- merge additively instead -- same "first writer wins" semantics as
-- LocalesAPI.register below -- so a caller can only fill in keys nobody has
-- registered yet, never overwrite or wipe existing ones.
RPCAPI.Register("SyncTranslations", function(params, res, player)
    if not params or type(params.translations) ~= "table" then
        return res(false)
    end

    for lang, translations in pairs(params.translations) do
        if type(translations) == "table" then
            if LocalesAPI.translations[lang] == nil then
                LocalesAPI.translations[lang] = translations
            else
                for tkey, tvalue in pairs(translations) do
                    if LocalesAPI.translations[lang][tkey] == nil then
                        LocalesAPI.translations[lang][tkey] = tvalue
                    end
                end
            end
        end
    end

    return res(true)
end)

if IsOnServer() then
    RPCAPI.Register("GetCharLang", function(params, res, player)
        return res(getLang(player))
    end)

    RPCAPI.Register("SetCharLang", function(params, res, player)
        local char = CharacterAPI.GetCharacter({ src = player })
        char:UpdateLang(params.lang)
        return res(LocalesAPI.translations[params.lang])
    end)
end

function LocalesAPI.register(key, translation)
    if LocalesAPI.translations[key] == nil then
        LocalesAPI.translations[key] = translation
        DebugLog("Locale (" .. key .. ") registered")
    else
        for tkey, tvalue in pairs(translation) do
            if LocalesAPI.translations[key][tkey] == nil then
                LocalesAPI.translations[key][tkey] = tvalue
                DebugLog("Locale (" .. key .. ") translation (" .. tkey .. ") registered")
            else
                DebugLog("Locale (" .. key .. ") translation (" .. tkey .. ") already registered")
            end
        end
    end

    
    -- Client-only resource translations need to reach the server. The server
    -- already owns its local table and must not broadcast a callback RPC to
    -- every client, since a callback has exactly one expected responder.
    if not IsOnServer() then
        RPCAPI.CallAsync("SyncTranslations", { translations = LocalesAPI.translations })
    end
end

function LocalesAPI.translate(src, str, ...)
    local lang
    if IsOnServer() then
        lang = getLang(src)
    else
        if ClientLangCache == nil then
            ClientLangCache = RPCAPI.CallAsync("GetCharLang", {})
        end
        lang = ClientLangCache
    end

    if LocalesAPI.translations[lang] ~= nil then
        local translations = LocalesAPI.translations[lang]
        if translations[str] ~= nil then
            return string.format(translations[str], ...)
        else
            return 'Translation [' .. lang .. '][' .. str .. '] does not exist'
        end
    else
        return 'Locale [' .. lang .. '] does not exist'
    end
end
