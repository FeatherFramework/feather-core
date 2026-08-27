-- Player settings menu (PVP toggle + language switch), built on feather-menu
-- directly rather than the Vue HUD -- these used to live in feather-hud's
-- NUI (SettingsView.vue + the footer PVP button) but are decoupled here so
-- they aren't tied to whatever the HUD looks like. Structured after
-- feather-admin's client/ui/menu.lua (the framework's standard shape for a
-- feather-menu-backed UI), just far smaller.
--
-- Language selection uses a button-list sub-page (like feather-admin's
-- ped_changer.lua categories -> models -> back flow) rather than feather-
-- menu's 'dropdown' element -- that component is a known mess (broken
-- pre-select wiring, boxy click-to-expand list, not an actual <select>).
PlayerSettingsUI = {}

-- Friendly display names for known locale codes; anything unmapped falls
-- back to the raw code (e.g. a resource registers a locale feather-core
-- doesn't have a label for yet).
local LanguageLabels = {
    en_us = 'English',
    es_ar = 'Español',
    fr_fr = 'Français',
    ro = 'Română'
}

local function languageLabel(lang)
    return LanguageLabels[lang] or lang
end

local function pvpLabel(active)
    return active and 'PVP: On' or 'PVP: Off'
end

-- "Language: English" rather than just "English" -- a bare language name
-- reads as a status display, not something to click.
local function languageButtonLabel(lang)
    return ('%s: %s'):format(LocalesAPI.translate(0, 'ui_settings_locale_title'), languageLabel(lang))
end

local PlayerSettingsMenu = FeatherMenu:RegisterMenu('feather-core:player_settings', {
    top = '50%',
    left = '50%',
    ['720width'] = '400px',
    ['1080width'] = '450px',
    ['2kwidth'] = '500px',
    ['4kwidth'] = '600px',
    draggable = true,
    canclose = true
})

local mainPage = PlayerSettingsMenu:RegisterPage('feather-core:player_settings:main')
local languagePage = PlayerSettingsMenu:RegisterPage('feather-core:player_settings:language')

-- Header/PVP-toggle/language-button labels depend on LocalesAPI/PVPAPI
-- state that isn't resolved yet at file-load time (LocalesAPI.translate
-- needs an active character's language, PVPAPI.active is just whatever
-- Config.PVP defaulted to before spawn) -- registered with placeholders
-- here and refreshed via :update() every time the menu opens, in
-- PlayerSettingsUI.Toggle below.
local header = mainPage:RegisterElement('header', {
    value = 'Settings',
    slot = 'header'
})

-- Forward-declared: the toggle's own callback below needs to reference
-- `pvpToggle` to update its label, but `local pvpToggle = RegisterElement(...,
-- function() ... pvpToggle ... end)` would have the closure capture a global
-- (the local isn't in scope yet inside its own initializer).
local pvpToggle
pvpToggle = mainPage:RegisterElement('toggle', {
    label = pvpLabel(false),
    start = false,
    persist = true
}, function(data)
    PVPAPI:togglePVP()
    -- The switch position alone isn't obvious at a glance -- state the
    -- on/off in the label too.
    pvpToggle:update({ label = pvpLabel(PVPAPI.active) })
end)

local languageButton = mainPage:RegisterElement('button', {
    label = 'Language',
    slot = 'content'
}, function()
    languagePage:RouteTo()
end)

-- Refreshes every translated element on the main page from LocalesAPI's
-- current language. Called on menu open and again right after a language
-- change -- otherwise the header stays in the old language until the menu
-- is closed and reopened.
local function refreshTranslations()
    header:update({ value = LocalesAPI.translate(0, 'ui_settings_title') })
end

-- LocalesAPI.translations is populated before any client_scripts run (it's
-- filled by locale/*.lua, all shared_scripts -- loaded first), so it's safe
-- to build the language button list at load time even though the values
-- above aren't.
for lang in pairs(LocalesAPI.translations) do
    languagePage:RegisterElement('button', {
        label = languageLabel(lang),
        slot = 'content'
    }, function()
        local updated = RPCAPI.CallAsync('core.account.settings.update.v1', { locale = lang })
        if type(updated) == 'table' and updated.ok == true then
            LocalesAPI.SetClientLang(updated.value.locale)
            languageButton:update({ label = languageButtonLabel(updated.value.locale) })
            refreshTranslations()
        end
        mainPage:RouteTo()
    end)
end

languagePage:RegisterElement('bottomline', { slot = 'footer' })
languagePage:RegisterElement('button', {
    label = 'Back',
    slot = 'footer'
}, function()
    mainPage:RouteTo()
end)

function PlayerSettingsUI.Toggle()
    if FeatherMenu.activeMenu and FeatherMenu.activeMenu.menuID == 'feather-core:player_settings' then
        PlayerSettingsMenu:Close()
        return
    end

    -- feather-menu's elemClass:update() reads FeatherMenu.activeMenu.menuID
    -- with no nil-guard (feather-menu/client/main.lua:252), so it can only
    -- be called once a menu is actually open -- Open() must run first.
    -- RouteTo() (triggered by startupPage below) fires before these run, so
    -- it briefly renders the placeholder values before the corrected ones
    -- arrive via a follow-up 'updateelement' message.
    PlayerSettingsMenu:Open({ startupPage = mainPage })

    refreshTranslations()
    pvpToggle:update({ value = PVPAPI.active, label = pvpLabel(PVPAPI.active) })

    local settings = RPCAPI.CallAsync('core.account.settings.get.v1', {})
    local currentLang = type(settings) == 'table' and settings.ok == true
        and settings.value.locale or Config.DefaultLang
    LocalesAPI.SetClientLang(currentLang)
    languageButton:update({ label = languageButtonLabel(currentLang) })
end

KeyPressAPI:RegisterListener(Config.PlayerSettings.hotkey, PlayerSettingsUI.Toggle)
