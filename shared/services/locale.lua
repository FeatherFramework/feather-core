LocalesAPI = {}
LocalesAPI.translations = {}

local function getLang(src)
    if IsOnServer() then
        local char = CharacterAPI.GetCharacterBySrc(src)
        return char.lang
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
        CharacterAPI.UpdateLang(player, params.lang)
        return res(LocalesAPI.translations[params.lang])
    end)
end

function LocalesAPI.register(key, translation)
    if LocalesAPI.translations[key] == nil then
        LocalesAPI.translations[key] = translation
        print("Locale (" .. key .. ") registered")
    else
        for tkey, tvalue in pairs(translation) do
            if LocalesAPI.translations[key][tkey] == nil then
                LocalesAPI.translations[key][tkey] = tvalue
                print("Locale (" .. key .. ") translation (" .. tkey .. ") registered")
            else
                print("Locale (" .. key .. ") translation (" .. tkey .. ") already registered")
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
