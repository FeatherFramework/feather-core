CoreAccountSettings = {}

local function ValidAccountId(value)
    return type(value) == 'string'
        and value:match('^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$') ~= nil
end

local function ValidLocale(value)
    return type(value) == 'string' and #value <= 16
        and type(LocalesAPI.translations[value]) == 'table'
end

function CoreAccountSettings.Get(accountId)
    if not ValidAccountId(accountId) then
        return CoreResults.Err('invalid_input', 'accountId must be a UUID.')
    end
    local locale = MySQL.scalar.await(
        'SELECT `locale` FROM `core_account_settings` WHERE `account_id` = ? LIMIT 1',
        { accountId })
    if not ValidLocale(locale) then locale = Config.DefaultLang end
    if not ValidLocale(locale) then
        return CoreResults.Err('invalid_config', 'The configured default locale is not registered.')
    end
    return CoreResults.Ok({ locale = locale })
end

function CoreAccountSettings.GetBySource(source)
    local account = CoreAccounts and CoreAccounts.GetContext(source)
    if type(account) ~= 'table' or account.ok ~= true then
        return CoreResults.Err('unauthenticated', 'A connected account context is required.')
    end
    return CoreAccountSettings.Get(account.value.accountId)
end

function CoreAccountSettings.Set(accountId, locale)
    if not ValidAccountId(accountId) then
        return CoreResults.Err('invalid_input', 'accountId must be a UUID.')
    end
    if not ValidLocale(locale) then
        return CoreResults.Err('locale_invalid', 'The requested locale is not registered.')
    end
    MySQL.query.await([[
        INSERT INTO `core_account_settings` (`account_id`, `locale`) VALUES (?, ?)
        ON DUPLICATE KEY UPDATE `locale` = VALUES(`locale`)
    ]], { accountId, locale })
    return CoreResults.Ok({ locale = locale })
end

local function EmptyPayload(payload)
    return type(payload) == 'table' and next(payload) == nil,
        'core.account.settings.get.v1 does not accept payload fields.'
end

local function UpdatePayload(payload)
    if type(payload) ~= 'table' or type(payload.locale) ~= 'string' then
        return false, 'locale is required.'
    end
    for key in pairs(payload) do
        if key ~= 'locale' then return false, 'Only locale is accepted.' end
    end
    return true
end

local getRoute = RPCAPI.RegisterContract('core.account.settings.get.v1', function(_, _, context)
    if not context or not context.accountId then
        return CoreResults.Err('unauthenticated', 'A connected account context is required.')
    end
    return CoreAccountSettings.Get(context.accountId)
end, {
    contract = 1, direction = 'client_to_server', requireCharacter = false,
    windowMs = 2000, maxCalls = 6, maxPayloadBytes = 64, maxDepth = 2, maxNodes = 4,
    validatePayload = EmptyPayload
})
if not getRoute.ok then error(('[%s] %s'):format(getRoute.code, getRoute.message)) end

local updateRoute = RPCAPI.RegisterContract('core.account.settings.update.v1', function(payload, _, context)
    if not context or not context.accountId then
        return CoreResults.Err('unauthenticated', 'A connected account context is required.')
    end
    return CoreAccountSettings.Set(context.accountId, payload.locale)
end, {
    contract = 1, direction = 'client_to_server', requireCharacter = false,
    windowMs = 2000, maxCalls = 4, maxPayloadBytes = 96, maxDepth = 2, maxNodes = 4,
    validatePayload = UpdatePayload
})
if not updateRoute.ok then error(('[%s] %s'):format(updateRoute.code, updateRoute.message)) end

exports('GetAccountSettings', CoreAccountSettings.GetBySource)

RegisterCommand('CoreAccountSettingsSmokeTest', function(source, args)
    if source ~= 0 then return end
    local target = tonumber(args and args[1])
    if not target then
        local players = GetPlayers()
        target = players[1] and tonumber(players[1]) or nil
    end
    if not target then
        print('[CoreAccountSettingsSmokeTest] no connected player is available')
        return
    end
    local account = CoreAccounts.GetContext(target)
    local original = account.ok and CoreAccountSettings.Get(account.value.accountId) or nil
    local persisted = original and original.ok
        and CoreAccountSettings.Set(account.value.accountId, original.value.locale) or nil
    local reread = account.ok and CoreAccountSettings.Get(account.value.accountId) or nil
    local routes = RPCAPI.GetRoutes()
    local routeNames = {}
    for _, route in ipairs(routes) do routeNames[route.route] = true end
    local tests = {
        { name = 'account context', passed = account.ok == true },
        { name = 'settings table', passed = tonumber(MySQL.scalar.await([[
            SELECT COUNT(*) FROM information_schema.TABLES
            WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'core_account_settings'
        ]])) == 1 },
        { name = 'registered locale', passed = original and original.ok == true
            and type(LocalesAPI.translations[original.value.locale]) == 'table' },
        { name = 'persistence round trip', passed = persisted and persisted.ok == true
            and reread and reread.ok == true and reread.value.locale == original.value.locale },
        { name = 'invalid locale rejected', passed = account.ok
            and CoreAccountSettings.Set(account.value.accountId, '__invalid__').code == 'locale_invalid' },
        { name = 'versioned routes', passed = routeNames['core.account.settings.get.v1'] == true
            and routeNames['core.account.settings.update.v1'] == true }
    }
    local passed = 0
    for _, test in ipairs(tests) do
        if test.passed then passed = passed + 1 end
        print(('[CoreAccountSettingsSmokeTest] %-24s %s'):format(test.name, test.passed and 'PASS' or 'FAIL'))
    end
    print(('[CoreAccountSettingsSmokeTest] done %d/%d passed source=%s'):format(passed, #tests, target))
end, true)
