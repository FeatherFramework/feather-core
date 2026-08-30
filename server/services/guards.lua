CoreGuards = {}

local logger = CoreLogging.Create(GetCurrentResourceName(), 'guards')
local guardsByAction = {}
local nextSequence = 0

local function OwnerResource()
    local owner = GetInvokingResource and GetInvokingResource() or nil
    return type(owner) == 'string' and owner ~= '' and owner or GetCurrentResourceName()
end

local function ValidName(value)
    return type(value) == 'string' and value:match('^[a-z][a-z0-9_.:-]*$') ~= nil
end

local function Copy(value, seen)
    if type(value) ~= 'table' then return value end

    seen = seen or {}
    if seen[value] then return nil end

    local output = {}
    seen[value] = output
    for key, child in pairs(value) do
        output[Copy(key, seen)] = Copy(child, seen)
    end
    return output
end

local function Ordered(action)
    local ordered = {}
    for _, guard in pairs(guardsByAction[action] or {}) do ordered[#ordered + 1] = guard end
    table.sort(ordered, function(left, right)
        if left.priority == right.priority then return left.sequence < right.sequence end
        return left.priority < right.priority
    end)
    return ordered
end

function CoreGuards.Register(action, name, callback, options)
    if not ValidName(action) or not ValidName(name) or not IsCallable(callback) then
        return CoreResults.Err('invalid_input', 'Guard action, name, and callback are required.')
    end

    options = type(options) == 'table' and options or {}
    guardsByAction[action] = guardsByAction[action] or {}
    if guardsByAction[action][name] then
        return CoreResults.Err('conflict', 'That guard is already registered.', { action = action, guard = name })
    end

    local count = 0
    for _ in pairs(guardsByAction[action]) do count = count + 1 end

    local maximum = math.max(1, math.floor(tonumber(Config.GuardRegistry.maxPerAction) or 64))
    if count >= maximum then
        return CoreResults.Err('limit_exceeded', 'That action has reached its guard limit.', { action = action })
    end

    nextSequence = nextSequence + 1
    local guard = {
        action = action,
        name = name,
        callback = callback,
        owner = OwnerResource(),
        priority = math.floor(tonumber(options.priority) or 100),
        sequence = nextSequence,
        registeredAt = os.time()
    }
    guardsByAction[action][name] = guard
    return CoreResults.Ok({
        action = action,
        name = name,
        owner = guard.owner,
        priority = guard.priority
    })
end

function CoreGuards.Unregister(action, name)
    local guard = guardsByAction[action] and guardsByAction[action][name]
    if not guard then
        return CoreResults.Err('not_found', 'That guard is not registered.', { action = action, guard = name })
    end

    if guard.owner ~= OwnerResource() then
        return CoreResults.Err('forbidden', 'That guard belongs to another resource.')
    end

    guardsByAction[action][name] = nil
    if next(guardsByAction[action]) == nil then guardsByAction[action] = nil end
    return CoreResults.Ok(true)
end

function CoreGuards.Evaluate(action, context)
    if not ValidName(action) or type(context) ~= 'table' then
        return CoreResults.Err('invalid_input', 'A valid guard action and context are required.')
    end

    local correlationId = type(context.correlationId) == 'string' and context.correlationId
        or ('guard:%s:%s'):format(tostring(GetGameTimer()), action)
    local evaluated = 0
    for _, guard in ipairs(Ordered(action)) do
        local ok, allowed, reason = pcall(guard.callback, Copy(context))
        evaluated = evaluated + 1
        if not ok then
            logger.Error('guard.failed', {
                action = action,
                guard = guard.name,
                owner = guard.owner,
                correlationId = correlationId,
                reason = tostring(allowed)
            })
            CoreEventBroker.PublishInternal('core.guard.evaluated.v1', {
                action = action,
                guard = guard.name,
                owner = guard.owner,
                correlationId = correlationId,
                allowed = false,
                outcome = 'error'
            })
            return CoreResults.Err('guard_failed', 'A required guard could not be evaluated.', {
                action = action,
                guard = guard.name,
                owner = guard.owner
            })
        end

        if type(allowed) ~= 'boolean' then
            CoreEventBroker.PublishInternal('core.guard.evaluated.v1', {
                action = action,
                guard = guard.name,
                owner = guard.owner,
                correlationId = correlationId,
                allowed = false,
                outcome = 'error'
            })
            return CoreResults.Err('guard_failed', 'A guard returned an invalid decision.', {
                action = action,
                guard = guard.name,
                owner = guard.owner
            })
        end

        if not allowed then
            local safeReason = type(reason) == 'string' and reason or 'guard_rejected'
            CoreEventBroker.PublishInternal('core.guard.evaluated.v1', {
                action = action,
                guard = guard.name,
                owner = guard.owner,
                correlationId = correlationId,
                allowed = false,
                outcome = 'denied'
            })
            return CoreResults.Ok({
                allowed = false,
                code = 'guard_rejected',
                reason = safeReason,
                guard = guard.name,
                owner = guard.owner,
                evaluated = evaluated
            })
        end
    end

    CoreEventBroker.PublishInternal('core.guard.evaluated.v1', {
        action = action,
        guard = 'all',
        owner = GetCurrentResourceName(),
        correlationId = correlationId,
        allowed = true,
        outcome = 'allowed'
    })
    return CoreResults.Ok({ allowed = true, evaluated = evaluated })
end

function CoreGuards.GetGuards()
    local output = {}
    for action in pairs(guardsByAction) do
        for _, guard in ipairs(Ordered(action)) do
            output[#output + 1] = {
                action = action,
                name = guard.name,
                owner = guard.owner,
                priority = guard.priority,
                sequence = guard.sequence,
                registeredAt = guard.registeredAt
            }
        end
    end

    table.sort(output, function(left, right)
        if left.action == right.action then
            if left.priority == right.priority then return left.sequence < right.sequence end
            return left.priority < right.priority
        end
        return left.action < right.action
    end)
    return output
end

exports('RegisterGuard', CoreGuards.Register)
exports('UnregisterGuard', CoreGuards.Unregister)
exports('EvaluateGuards', CoreGuards.Evaluate)
exports('GetGuards', function() return CoreResults.Ok(CoreGuards.GetGuards()) end)

AddEventHandler('onResourceStop', function(stoppedResource)
    for action, bucket in pairs(guardsByAction) do
        for name, guard in pairs(bucket) do
            if guard.owner == stoppedResource then bucket[name] = nil end
        end
        if next(bucket) == nil then guardsByAction[action] = nil end
    end
end)

RegisterCommand('CoreGuardSmokeTest', function(source)
    if source ~= 0 then return end

    CoreGuards.Unregister('smoke.guard', 'first')
    CoreGuards.Unregister('smoke.guard', 'second')
    local order = {}
    local first = CoreGuards.Register('smoke.guard', 'first', function(context)
        order[#order + 1] = 'first'
        context.mutated = true
        return true
    end, { priority = 10 })
    local second = CoreGuards.Register('smoke.guard', 'second', function(context)
        order[#order + 1] = 'second'
        if context.mutated then error('context was shared') end
        return false, 'smoke_veto'
    end, { priority = 20 })
    local decision = CoreGuards.Evaluate('smoke.guard', { correlationId = 'guard-smoke' })
    local cleanupOne = CoreGuards.Unregister('smoke.guard', 'first')
    local cleanupTwo = CoreGuards.Unregister('smoke.guard', 'second')
    local smokeRemaining = 0
    for _, guard in ipairs(CoreGuards.GetGuards()) do
        if guard.action == 'smoke.guard' then smokeRemaining = smokeRemaining + 1 end
    end

    local tests = {
        { name = 'guards registered', passed = first.ok and second.ok },
        { name = 'priority order',    passed = order[1] == 'first' and order[2] == 'second' },
        {
            name = 'veto envelope',
            passed = decision.ok and decision.value.allowed == false
                and decision.value.reason == 'smoke_veto'
        },
        {
            name = 'guards cleaned',
            passed = cleanupOne.ok and cleanupTwo.ok
                and smokeRemaining == 0
        }
    }
    local passed = 0
    for _, test in ipairs(tests) do
        if test.passed then passed = passed + 1 end
        print(('[CoreGuardSmokeTest] %-24s %s'):format(test.name, test.passed and 'PASS' or 'FAIL'))
    end
    print(('[CoreGuardSmokeTest] done %d/%d passed'):format(passed, #tests))
end, true)
