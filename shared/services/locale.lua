LocalesAPI = {}
LocalesAPI.translations = {}

-- Locale preference is account-scoped, so it is available before character
-- selection and remains stable while switching characters. The client keeps
-- a local copy and only reads the versioned account-settings route when the
-- cache has not been initialized yet.
local ClientLangCache = nil

function LocalesAPI.SetClientLang(lang)
    ClientLangCache = lang
end

function LocalesAPI.RefreshClientLang()
    if IsOnServer() then return false end
    local settings = RPCAPI.CallAsync('core.account.settings.get.v1', {})
    if type(settings) ~= 'table' or settings.ok ~= true then return false end
    ClientLangCache = settings.value.locale
    return true
end

if not IsOnServer() then
    AddEventHandler('playerSpawned', function()
        CreateThread(function()
            for _ = 1, 10 do
                if LocalesAPI.RefreshClientLang() then return end
                Wait(1000)
            end
        end)
    end)
end

local function getLang(src)
    if IsOnServer() then
        local settings = CoreAccountSettings and CoreAccountSettings.GetBySource(src)
        return type(settings) == 'table' and settings.ok == true
            and settings.value.locale or Config.DefaultLang
    else
        print('Not for use on client')
    end
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

    
end

function LocalesAPI.translate(src, str, ...)
    local lang
    if IsOnServer() then
        lang = getLang(src)
    else
        if ClientLangCache == nil then
            if not LocalesAPI.RefreshClientLang() then ClientLangCache = Config.DefaultLang end
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

local function RegisterLocale(key, translations)
    if type(key) ~= 'string' or key == '' or type(translations) ~= 'table' then
        return CoreResults.Err('invalid_input', 'Locale name and translation table are required.')
    end
    LocalesAPI.register(key, translations)
    return CoreResults.Ok({ locale = key })
end

local function TranslateLocale(src, key, ...)
    if type(key) ~= 'string' or key == '' then
        return CoreResults.Err('invalid_input', 'Translation key is required.')
    end
    local ok, translated = pcall(LocalesAPI.translate, src, key, ...)
    if not ok then
        return CoreResults.Err('internal_error', 'Translation failed.')
    end
    return CoreResults.Ok(translated)
end

exports('RegisterLocale', RegisterLocale)
exports('TranslateLocale', TranslateLocale)
exports('SetClientLocale', function(locale)
    if IsOnServer() then return CoreResults.Err('invalid_context', 'Client locale can only be set on a client.') end
    if type(locale) ~= 'string' or LocalesAPI.translations[locale] == nil then
        return CoreResults.Err('invalid_input', 'Locale is not registered.', { locale = locale })
    end
    LocalesAPI.SetClientLang(locale)
    return CoreResults.Ok({ locale = locale })
end)
