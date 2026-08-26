CoreEventBroker = {}

local logger = CoreLogging.Create(GetCurrentResourceName(), 'events')
local declarations = {}
local nextSubscriptionId = 0

local function OwnerResource()
    local owner = GetInvokingResource and GetInvokingResource() or nil
    return type(owner) == 'string' and owner ~= '' and owner or GetCurrentResourceName()
end

local function Copy(value)
    if type(value) ~= 'table' then return value end
    local output = {}
    for key, child in pairs(value) do output[key] = Copy(child) end
    return output
end

local function ValidatePlainData(value, limits, depth, seen, count)
    local valueType = type(value)
    if valueType == 'nil' or valueType == 'boolean' or valueType == 'string' then
        return true, count + 1
    end
    if valueType == 'number' then
        return value == value and value ~= math.huge and value ~= -math.huge, count + 1
    end
    if valueType ~= 'table' or depth >= limits.maxDepth or seen[value] then
        return false, count
    end

    seen[value] = true
    count = count + 1
    if count > limits.maxNodes then return false, count end
    for key, child in pairs(value) do
        local keyType = type(key)
        if keyType ~= 'string' and keyType ~= 'number' then return false, count end
        local valid
        valid, count = ValidatePlainData(child, limits, depth + 1, seen, count)
        if not valid or count > limits.maxNodes then return false, count end
    end
    seen[value] = nil
    return true, count
end

function CoreEventBroker.Declare(name, options)
    options = type(options) == 'table' and options or {}
    if type(name) ~= 'string' or not name:match('%.v%d+$') then
        return CoreResults.Err('invalid_input', 'Contract event names must end with a version suffix such as .v1.')
    end
    if declarations[name] then
        return CoreResults.Err('conflict', 'That event is already declared.', { event = name })
    end

    local validator = options.validatePayload
    if validator ~= nil and not IsCallable(validator) then
        return CoreResults.Err('invalid_input', 'validatePayload must be callable when provided.')
    end

    local defaults = Config.EventBroker or {}
    local contract = tonumber(options.contract) or tonumber(name:match('%.v(%d+)$'))
    if not contract or contract < 1 or contract % 1 ~= 0 then
        return CoreResults.Err('invalid_input', 'Event contract must be a positive integer.')
    end

    declarations[name] = {
        name = name,
        owner = OwnerResource(),
        contract = contract,
        validator = validator,
        maxPayloadBytes = math.max(64, tonumber(options.maxPayloadBytes) or tonumber(defaults.maxPayloadBytes) or 32768),
        maxDepth = math.max(1, math.min(32, tonumber(options.maxDepth) or tonumber(defaults.maxDepth) or 12)),
        maxNodes = math.max(1, math.min(10000, tonumber(options.maxNodes) or tonumber(defaults.maxNodes) or 2048)),
        maxSubscribers = math.max(1, math.floor(tonumber(options.maxSubscribers) or tonumber(defaults.maxSubscribers) or 128)),
        nextSequence = 0,
        subscribers = {}
    }
    return CoreResults.Ok({ event = name, owner = declarations[name].owner, contract = declarations[name].contract })
end

function CoreEventBroker.Subscribe(name, callback)
    local declaration = declarations[name]
    if not declaration then
        return CoreResults.Err('not_found', 'That event has not been declared.', { event = name })
    end
    if not IsCallable(callback) then
        return CoreResults.Err('invalid_input', 'Event subscriptions require a callable listener.')
    end

    local count = 0
    for _ in pairs(declaration.subscribers) do count = count + 1 end
    if count >= declaration.maxSubscribers then
        return CoreResults.Err('limit_exceeded', 'That event has reached its subscriber limit.', { event = name })
    end

    nextSubscriptionId = nextSubscriptionId + 1
    declaration.nextSequence = declaration.nextSequence + 1
    local token = ('event:%s:%d'):format(name, nextSubscriptionId)
    declaration.subscribers[token] = {
        token = token,
        owner = OwnerResource(),
        callback = callback,
        sequence = declaration.nextSequence
    }
    return CoreResults.Ok({ token = token, event = name })
end

function CoreEventBroker.Unsubscribe(token)
    if type(token) ~= 'string' or token == '' then
        return CoreResults.Err('invalid_input', 'A subscription token is required.')
    end
    local owner = OwnerResource()
    for _, declaration in pairs(declarations) do
        local subscription = declaration.subscribers[token]
        if subscription then
            if subscription.owner ~= owner then
                return CoreResults.Err('forbidden', 'That subscription belongs to another resource.')
            end
            declaration.subscribers[token] = nil
            return CoreResults.Ok(true)
        end
    end
    return CoreResults.Err('not_found', 'That event subscription was not found.')
end

local function Dispatch(declaration, name, payload)
    local plain = ValidatePlainData(payload, declaration, 0, {}, 0)
    if not plain then
        return CoreResults.Err('invalid_input', 'Event payload must contain bounded plain data.', { event = name })
    end
    local encodedOk, encoded = pcall(json.encode, payload)
    if not encodedOk or type(encoded) ~= 'string' or #encoded > declaration.maxPayloadBytes then
        return CoreResults.Err('payload_too_large', 'Event payload is too large.', { event = name })
    end
    if declaration.validator then
        local valid, reason = declaration.validator(payload)
        if valid ~= true then
            return CoreResults.Is(reason) and reason
                or CoreResults.Err('invalid_input', type(reason) == 'string' and reason or 'Event payload validation failed.')
        end
    end

    local ordered = {}
    for _, subscription in pairs(declaration.subscribers) do ordered[#ordered + 1] = subscription end
    table.sort(ordered, function(left, right) return left.sequence < right.sequence end)

    local delivered, failed = 0, 0
    for _, subscription in ipairs(ordered) do
        local ok, failure = pcall(subscription.callback, Copy(payload), {
            event = name,
            contract = declaration.contract,
            publisher = declaration.owner
        })
        if ok then
            delivered = delivered + 1
        else
            failed = failed + 1
            logger.Error('event.listener_failed', {
                event = name,
                subscriber = subscription.owner,
                reason = tostring(failure)
            })
        end
    end
    return CoreResults.Ok({ delivered = delivered, failed = failed })
end

function CoreEventBroker.Publish(name, payload)
    local declaration = declarations[name]
    if not declaration then
        return CoreResults.Err('not_found', 'That event has not been declared.', { event = name })
    end
    if declaration.owner ~= OwnerResource() then
        return CoreResults.Err('forbidden', 'Only the declaring resource may publish that event.', { event = name })
    end
    return Dispatch(declaration, name, payload)
end

-- Core services may publish Core-owned lifecycle events while handling an
-- export invoked by another resource. This bypass is not exported and still
-- refuses to publish events declared by any non-Core owner.
function CoreEventBroker.PublishInternal(name, payload)
    local declaration = declarations[name]
    if not declaration then
        return CoreResults.Err('not_found', 'That event has not been declared.', { event = name })
    end
    if declaration.owner ~= GetCurrentResourceName() then
        return CoreResults.Err('forbidden', 'Internal publication is limited to Core-owned events.', { event = name })
    end
    return Dispatch(declaration, name, payload)
end

function CoreEventBroker.GetEvents()
    local events = {}
    for name, declaration in pairs(declarations) do
        local subscriberCount = 0
        for _ in pairs(declaration.subscribers) do subscriberCount = subscriberCount + 1 end
        events[#events + 1] = {
            event = name,
            owner = declaration.owner,
            contract = declaration.contract,
            subscribers = subscriberCount,
            maxPayloadBytes = declaration.maxPayloadBytes,
            maxDepth = declaration.maxDepth,
            maxNodes = declaration.maxNodes
        }
    end
    table.sort(events, function(left, right) return left.event < right.event end)
    return events
end

exports('DeclareEvent', CoreEventBroker.Declare)
exports('SubscribeEvent', CoreEventBroker.Subscribe)
exports('UnsubscribeEvent', CoreEventBroker.Unsubscribe)
exports('PublishEvent', CoreEventBroker.Publish)
exports('GetEvents', function() return CoreResults.Ok(CoreEventBroker.GetEvents()) end)

AddEventHandler('onResourceStop', function(stoppedResource)
    for name, declaration in pairs(declarations) do
        if declaration.owner == stoppedResource then
            declarations[name] = nil
        else
            for token, subscription in pairs(declaration.subscribers) do
                if subscription.owner == stoppedResource then declaration.subscribers[token] = nil end
            end
        end
    end
end)

local function RequireFields(fields)
    return function(payload)
        if type(payload) ~= 'table' then return false, 'Event payload must be a table.' end
        for _, field in ipairs(fields) do
            if payload[field] == nil then return false, ('Event payload requires %s.'):format(field) end
        end
        return true
    end
end

local coreEvents = {
    { 'core.account.connected.v1', { 'source', 'accountId', 'state' } },
    { 'core.account.disconnected.v1', { 'source', 'accountId', 'state' } },
    { 'core.session.ready.v1', { 'source', 'accountId', 'characterId', 'sessionId', 'state' } },
    { 'core.session.leaving.v1', { 'source', 'accountId', 'characterId', 'sessionId', 'state' } },
    { 'core.session.left.v1', { 'source', 'accountId', 'characterId', 'sessionId', 'state' } },
    { 'core.provider.registered.v1', { 'kind', 'name', 'owner', 'contract' } },
    { 'core.provider.unregistered.v1', { 'kind', 'name', 'owner', 'contract', 'reason' } },
    { 'core.policy.evaluated.v1', { 'action', 'source', 'caller', 'correlationId', 'allowed', 'outcome' } },
    { 'core.guard.evaluated.v1', { 'action', 'guard', 'owner', 'correlationId', 'allowed', 'outcome' } },
    { 'core.framework.smoke.v1', { 'value' } }
}

for _, definition in ipairs(coreEvents) do
    local declared = CoreEventBroker.Declare(definition[1], {
        contract = 1,
        validatePayload = RequireFields(definition[2])
    })
    if not declared.ok then error(('[%s] %s'):format(declared.code, declared.message)) end
end

RegisterCommand('CoreEventSmokeTest', function(source)
    if source ~= 0 then return end
    local firstValue, secondValue
    local first = CoreEventBroker.Subscribe('core.framework.smoke.v1', function(payload)
        firstValue = payload.value
        payload.value = 'mutated'
    end)
    local second = CoreEventBroker.Subscribe('core.framework.smoke.v1', function(payload)
        secondValue = payload.value
    end)
    local published = CoreEventBroker.Publish('core.framework.smoke.v1', { value = 'original' })

    local tests = {
        { name = 'declared event', passed = declarations['core.framework.smoke.v1'] ~= nil },
        { name = 'deterministic delivery', passed = published.ok and published.value.delivered == 2 and firstValue == 'original' },
        { name = 'payload isolation', passed = secondValue == 'original' },
        { name = 'listener cleanup', passed = first.ok and second.ok
            and CoreEventBroker.Unsubscribe(first.value.token).ok
            and CoreEventBroker.Unsubscribe(second.value.token).ok }
    }

    local passed = 0
    for _, test in ipairs(tests) do
        if test.passed then passed = passed + 1 end
        print(('[CoreEventSmokeTest] %-24s %s'):format(test.name, test.passed and 'PASS' or 'FAIL'))
    end
    print(('[CoreEventSmokeTest] done %d/%d passed'):format(passed, #tests))
end, true)
