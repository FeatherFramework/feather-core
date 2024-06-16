LocalesAPI = {}
LocalesAPI.translations = {}

local function getLang(src)
    if IsOnServer() then
        local char = CharacterAPI.GetCharacter(src)
        if not char or not char.char or not char.char.lang then
            return Config.DefaultLang
        else
            return char.char.lang
        end
    else
        print('Not for use on client')
    end
end

--This handles syncing the translations between client/server
RPCAPI.Register("SyncTranslations", function(params, res, player)
    LocalesAPI.translations = params.translations
    return res(true)
end)

if IsOnServer() then
    RPCAPI.Register("GetCharLang", function(params, res, player)
        return res(getLang(player))
    end)

    RPCAPI.Register("SetCharLang", function(params, res, player)
        local char = CharacterAPI.GetCharacter(player)
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

    
    RPCAPI.CallAsync("SyncTranslations", { translations = LocalesAPI.translations })
end

function LocalesAPI.translate(src, str, ...)
    local lang
    if IsOnServer() then
        lang = getLang(src)
    else
        lang = RPCAPI.CallAsync("GetCharLang", {})
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
