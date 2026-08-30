CoreFoundation = {}

local resourceName = GetCurrentResourceName()
local resourceVersion = GetResourceMetadata(resourceName, 'version', 0) or '0.0.0'
local logger = CoreLogging.Create(resourceName, 'foundation')
local startedAt = os.time()

local health = {
    state = 'stopped',
    phase = 'not_started',
    contract = 1,
    version = resourceVersion,
    startedAt = startedAt,
    readyAt = nil,
    failure = nil,
    checks = {}
}

local allowedTransitions = {
    stopped = { booting = true },
    booting = { migrating = true, starting = true, failed = true },
    migrating = { starting = true, failed = true },
    starting = { ready = true, degraded = true, failed = true },
    ready = { degraded = true, stopping = true, failed = true },
    degraded = { ready = true, stopping = true, failed = true },
    failed = { stopping = true },
    stopping = { stopped = true }
}

local function Copy(value, seen)
    if type(value) ~= 'table' then
        return value
    end

    seen = seen or {}
    if seen[value] then
        return nil
    end

    local output = {}
    seen[value] = output
    for key, child in pairs(value) do
        output[Copy(key, seen)] = Copy(child, seen)
    end
    return output
end

local function SetState(state, phase, failure)
    local current = health.state
    if current ~= state and not (allowedTransitions[current] and allowedTransitions[current][state]) then
        return CoreResults.Err('invalid_state', 'Core lifecycle transition is invalid.', {
            current = current,
            requested = state
        })
    end

    health.state = state
    health.phase = phase or state
    health.failure = failure and Copy(failure) or nil
    if state == 'ready' then
        health.readyAt = os.time()
    end

    logger.Info('lifecycle.changed', { previous = current, state = state, phase = health.phase })
    return CoreResults.Ok(CoreFoundation.GetHealth())
end

local function Check(name, valid, code, message, details)
    health.checks[name] = {
        ok = valid == true,
        checkedAt = os.time(),
        code = valid and nil or code,
        message = valid and nil or message
    }

    if valid then
        return CoreResults.Ok(true)
    end
    return CoreResults.Err(code, message, details)
end

local function ValidateConfiguration()
    local checks = {
        Check('config.exists', type(Config) == 'table', 'invalid_config', 'Config must be a table.'),

        Check('config.development_mode', type(Config and Config.DevMode) == 'boolean',
            'invalid_config', 'Config.DevMode must be true or false.'),

        Check('config.default_language', type(Config and Config.DefaultLang) == 'string' and Config.DefaultLang ~= '',
            'invalid_config', 'Config.DefaultLang must be a non-empty string.'),

        Check('config.rpc', type(Config and Config.RPCRateLimit) == 'table',
            'invalid_config', 'Config.RPCRateLimit must be a table.')
    }

    local rpc = Config and Config.RPCRateLimit or {}
    local numericFields = { 'windowMs', 'maxCalls', 'timeoutMs', 'maxPayloadBytes' }
    for _, field in ipairs(numericFields) do
        checks[#checks + 1] = Check('config.rpc.' .. field,
            type(rpc[field]) == 'number' and rpc[field] > 0,
            'invalid_config', ('Config.RPCRateLimit.%s must be a positive number.'):format(field),
            { path = 'Config.RPCRateLimit.' .. field })
    end

    local loggingLevel = Config and Config.Logging and Config.Logging.level or 'info'
    checks[#checks + 1] = Check('config.logging.level',
        loggingLevel == 'debug' or loggingLevel == 'info' or loggingLevel == 'warn' or loggingLevel == 'error',
        'invalid_config', 'Config.Logging.level must be debug, info, warn, or error.',
        { path = 'Config.Logging.level' })

    local eventConfig = Config and Config.EventBroker
    checks[#checks + 1] = Check('config.events', type(eventConfig) == 'table',
        'invalid_config', 'Config.EventBroker must be a table.')
    for _, field in ipairs({ 'maxPayloadBytes', 'maxDepth', 'maxNodes', 'maxSubscribers' }) do
        checks[#checks + 1] = Check('config.events.' .. field,
            type(eventConfig and eventConfig[field]) == 'number' and eventConfig[field] > 0,
            'invalid_config', ('Config.EventBroker.%s must be a positive number.'):format(field),
            { path = 'Config.EventBroker.' .. field })
    end

    checks[#checks + 1] = Check('config.providers.maxPerKind',
        type(Config and Config.ProviderRegistry and Config.ProviderRegistry.maxPerKind) == 'number'
            and Config.ProviderRegistry.maxPerKind > 0,
        'invalid_config', 'Config.ProviderRegistry.maxPerKind must be a positive number.',
        { path = 'Config.ProviderRegistry.maxPerKind' })

    checks[#checks + 1] = Check('config.guards.maxPerAction',
        type(Config and Config.GuardRegistry and Config.GuardRegistry.maxPerAction) == 'number'
            and Config.GuardRegistry.maxPerAction > 0,
        'invalid_config', 'Config.GuardRegistry.maxPerAction must be a positive number.',
        { path = 'Config.GuardRegistry.maxPerAction' })

    for _, field in ipairs({ 'maxMessageLength', 'maxDurationMs' }) do
        checks[#checks + 1] = Check('config.notifications.' .. field,
            type(Config and Config.NotificationRegistry and Config.NotificationRegistry[field]) == 'number'
                and Config.NotificationRegistry[field] > 0,
            'invalid_config', ('Config.NotificationRegistry.%s must be a positive number.'):format(field),
            { path = 'Config.NotificationRegistry.' .. field })
    end

    for _, result in ipairs(checks) do
        if not result.ok then
            return result
        end
    end
    return CoreResults.Ok(true)
end

function CoreFoundation.GetCapabilities()
    return CoreResults.Ok({
        resource = resourceName,
        contract = 1,
        version = resourceVersion,
        state = health.state,
        features = {
            lifecycle = 1,
            health = 1,
            results = 1,
            logging = 1,
            configValidation = 1,
            accountContext = 1,
            primaryIdentifier = 1,
            connectionGates = 1,
            sessions = 1,
            rpc = 1,
            namedRpcAccess = 1,
            events = 1,
            providers = 1,
            policy = 1,
            guards = 1,
            notifications = 1,
            localization = 1,
            accountSettings = 1
        }
    })
end

function CoreFoundation.GetHealth()
    return Copy(health)
end

function CoreFoundation.AwaitReady(timeoutMs)
    timeoutMs = tonumber(timeoutMs) or 10000
    if timeoutMs < 0 or timeoutMs > 60000 then
        return CoreResults.Err('invalid_input', 'timeoutMs must be between 0 and 60000.')
    end

    local deadline = GetGameTimer() + timeoutMs
    while health.state ~= 'ready' and health.state ~= 'failed' and GetGameTimer() < deadline do
        Wait(0)
    end

    if health.state == 'ready' then
        return CoreResults.Ok(CoreFoundation.GetHealth())
    end

    if health.state == 'failed' then
        return CoreResults.Err('not_ready', 'Feather Core failed to start.', { health = CoreFoundation.GetHealth() })
    end
    return CoreResults.Err('timeout', 'Timed out waiting for Feather Core readiness.', { health = CoreFoundation.GetHealth() })
end

function CoreFoundation.BeginStartup()
    local transition = SetState('booting', 'validating_configuration')
    if not transition.ok then
        return transition
    end

    local validation = ValidateConfiguration()
    if not validation.ok then
        SetState('failed', 'configuration_failed', validation)
        return validation
    end

    return SetState('migrating', 'database_migrations')
end

function CoreFoundation.MarkMigrationsComplete(details)
    health.checks['database.migrations'] = {
        ok = true,
        checkedAt = os.time(),
        details = Copy(details or {})
    }
    return SetState('starting', 'starting_services')
end

function CoreFoundation.MarkReady()
    return SetState('ready', 'ready')
end

function CoreFoundation.MarkFailed(code, message, details)
    local failure = CoreResults.Err(code or 'startup_failed', message or 'Feather Core failed to start.', details)
    SetState('failed', 'startup_failed', failure)
    logger.Error('startup.failed', failure)
    return failure
end

exports('GetCapabilities', CoreFoundation.GetCapabilities)
exports('GetHealth', function()
    return CoreResults.Ok(CoreFoundation.GetHealth())
end)
exports('AwaitReady', CoreFoundation.AwaitReady)

RegisterCommand('CoreContractSmokeTest', function(source)
    if source ~= 0 then
        return
    end

    local tests = {
        {
            name = 'result envelope',
            run = function()
                local result = CoreResults.Ok({ contract = 1 })
                return CoreResults.Is(result) and result.value.contract == 1
            end
        },
        {
            name = 'capabilities',
            run = function()
                local result = CoreFoundation.GetCapabilities()
                return result.ok and result.value.contract == 1 and result.value.state == 'ready'
            end
        },
        {
            name = 'health',
            run = function()
                local current = CoreFoundation.GetHealth()
                local checks = type(current) == 'table' and type(current.checks) == 'table'
                    and current.checks or {}
                local configCheck = checks['config.exists']
                local migrationCheck = checks['database.migrations']
                return type(current) == 'table' and current.state == 'ready'
                    and type(configCheck) == 'table' and configCheck.ok == true
                    and type(migrationCheck) == 'table' and migrationCheck.ok == true
            end
        },
        {
            name = 'await ready',
            run = function()
                local result = CoreFoundation.AwaitReady(0)
                return result.ok and result.value.state == 'ready'
            end
        }
    }

    local passed = 0
    for _, test in ipairs(tests) do
        local ok, result = pcall(test.run)
        local success = ok and result == true
        if success then
            passed = passed + 1
        end
        print(('[CoreContractSmokeTest] %-24s %s'):format(test.name, success and 'PASS' or 'FAIL'))

        if not ok then
            logger.Error('contract_smoke_test.errored', { test = test.name, reason = tostring(result) })
        end
    end
    print(('[CoreContractSmokeTest] done %d/%d passed'):format(passed, #tests))
end, true)

AddEventHandler('onResourceStop', function(stoppedResource)
    if stoppedResource ~= resourceName then
        return
    end

    if health.state ~= 'stopped' and health.state ~= 'stopping' then
        SetState('stopping', 'resource_stopping')
    end

    if health.state == 'stopping' then
        SetState('stopped', 'resource_stopped')
    end
end)
