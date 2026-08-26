CorePolicy = {}

local logger = CoreLogging.Create(GetCurrentResourceName(), 'policy')

local function Copy(value, seen)
    if type(value) ~= 'table' then return value end
    seen = seen or {}
    if seen[value] then return nil end
    local output = {}
    seen[value] = output
    for key, child in pairs(value) do output[Copy(key, seen)] = Copy(child, seen) end
    return output
end

local function CallerResource()
    local caller = GetInvokingResource and GetInvokingResource() or nil
    return type(caller) == 'string' and caller ~= '' and caller or GetCurrentResourceName()
end

local function ValidAction(action)
    return type(action) == 'string' and action:match('^[a-z][a-z0-9_.:-]*$') ~= nil
end

local function BuildContext(action, request)
    request = type(request) == 'table' and request or {}
    local src = tonumber(request.source) or 0
    if src < 0 or src % 1 ~= 0 then
        return CoreResults.Err('invalid_input', 'Authorization source must be a non-negative integer.')
    end

    local context = {
        action = action,
        source = src,
        caller = CallerResource(),
        correlationId = type(request.correlationId) == 'string' and request.correlationId
            or ('policy:%s:%s:%s'):format(tostring(src), tostring(GetGameTimer()), action),
        subject = type(request.subject) == 'table' and Copy(request.subject) or {}
    }

    if src > 0 then
        local account = CoreAccounts.GetContext(src)
        if not account.ok then
            return CoreResults.Err('unauthenticated', 'A connected Core account context is required.')
        end
        context.accountId = account.value.accountId

        local session = CoreSessions.Get(src)
        if session.ok then
            context.characterId = session.value.characterId
            context.sessionId = session.value.sessionId
            context.generation = session.value.generation
        end
    else
        context.system = true
    end
    return CoreResults.Ok(context)
end

local function EvaluateProvider(providerResult, action, context)
    if not providerResult.ok then return providerResult end
    local implementation = providerResult.value.implementation
    if type(implementation) ~= 'table' or not IsCallable(implementation.Evaluate) then
        return CoreResults.Err('provider_unavailable', 'The policy provider does not implement Evaluate.')
    end

    local ok, decision = pcall(implementation.Evaluate, action, context)
    if not ok then
        logger.Error('policy.provider_failed', {
            action = action,
            provider = providerResult.value.provider.name,
            correlationId = context.correlationId,
            reason = tostring(decision)
        })
        return CoreResults.Err('provider_unavailable', 'Policy evaluation failed.')
    end
    if not CoreResults.Is(decision)
        or not decision.ok
        or type(decision.value) ~= 'table'
        or type(decision.value.allowed) ~= 'boolean' then
        return CoreResults.Err('provider_unavailable', 'Policy provider returned an invalid decision.')
    end

    decision.value.provider = providerResult.value.provider.name
    decision.value.contract = providerResult.value.provider.contract
    return decision
end

function CorePolicy.RegisterProvider(name, implementation, options)
    options = type(options) == 'table' and options or {}
    local registration = Copy(options)
    registration.default = registration.default ~= false
    return CoreProviders.Register('policy', name, implementation, registration)
end

function CorePolicy.Authorize(action, request)
    if not ValidAction(action) then
        return CoreResults.Err('invalid_input', 'Authorization action is invalid.')
    end

    local contextResult = BuildContext(action, request)
    if not contextResult.ok then return contextResult end
    local context = contextResult.value
    local provider = CoreProviders.Get('policy', nil, 1)
    local decision = EvaluateProvider(provider, action, context)
    if not decision.ok then
        CoreEventBroker.PublishInternal('core.policy.evaluated.v1', {
            action = action,
            source = context.source,
            caller = context.caller,
            correlationId = context.correlationId,
            allowed = false,
            outcome = 'error',
            code = decision.code
        })
        return decision
    end

    CoreEventBroker.PublishInternal('core.policy.evaluated.v1', {
        action = action,
        source = context.source,
        caller = context.caller,
        correlationId = context.correlationId,
        allowed = decision.value.allowed,
        outcome = decision.value.allowed and 'allowed' or 'denied',
        code = decision.value.code
    })
    return decision
end

exports('RegisterPolicyProvider', CorePolicy.RegisterProvider)
exports('Authorize', CorePolicy.Authorize)

RegisterCommand('CorePolicySmokeTest', function(source)
    if source ~= 0 then return end
    CoreProviders.Unregister('core-policy-smoke', 'test')
    local registered = CoreProviders.Register('core-policy-smoke', 'test', {
        Evaluate = function(action)
            if action == 'smoke.allow' then
                return CoreResults.Ok({ allowed = true, decision = 'smoke' })
            end
            return CoreResults.Ok({ allowed = false, code = 'forbidden', reason = 'smoke' })
        end
    }, { contract = 1, default = true, capabilities = { actions = 1 } })

    local provider = CoreProviders.Get('core-policy-smoke', nil, 1)
    local context = { source = 0, system = true, caller = GetCurrentResourceName(), correlationId = 'policy-smoke' }
    local allowed = EvaluateProvider(provider, 'smoke.allow', context)
    local denied = EvaluateProvider(provider, 'smoke.deny', context)
    local invalid = EvaluateProvider(CoreResults.Ok({
        provider = { name = 'invalid', contract = 1 },
        implementation = { Evaluate = function() return true end }
    }), 'smoke.allow', context)
    local removed = CoreProviders.Unregister('core-policy-smoke', 'test')

    local tests = {
        { name = 'policy registered', passed = registered.ok },
        { name = 'allow decision', passed = allowed.ok and allowed.value.allowed == true },
        { name = 'deny decision', passed = denied.ok and denied.value.allowed == false and denied.value.code == 'forbidden' },
        { name = 'invalid fails closed', passed = not invalid.ok and removed.ok }
    }
    local passed = 0
    for _, test in ipairs(tests) do
        if test.passed then passed = passed + 1 end
        print(('[CorePolicySmokeTest] %-24s %s'):format(test.name, test.passed and 'PASS' or 'FAIL'))
    end
    print(('[CorePolicySmokeTest] done %d/%d passed'):format(passed, #tests))
end, true)
