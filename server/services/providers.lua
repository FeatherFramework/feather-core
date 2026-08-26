CoreProviders = {}

local logger = CoreLogging.Create(GetCurrentResourceName(), 'providers')
local providers = {}
local defaults = {}

local function OwnerResource()
    local owner = GetInvokingResource and GetInvokingResource() or nil
    return type(owner) == 'string' and owner ~= '' and owner or GetCurrentResourceName()
end

local function Copy(value)
    if type(value) ~= 'table' then return value end
    local output = {}
    for key, child in pairs(value) do
        if type(child) ~= 'function' then output[key] = Copy(child) end
    end
    return output
end

local function ValidName(value)
    return type(value) == 'string' and value:match('^[a-z][a-z0-9_.-]*$') ~= nil
end

local function ProviderCount(kind)
    local count = 0
    for _ in pairs(providers[kind] or {}) do count = count + 1 end
    return count
end

local function PublicRecord(provider)
    return {
        kind = provider.kind,
        name = provider.name,
        owner = provider.owner,
        contract = provider.contract,
        capabilities = Copy(provider.capabilities),
        isDefault = defaults[provider.kind] == provider.name,
        registeredAt = provider.registeredAt
    }
end

local function RemoveProvider(provider, reason)
    local bucket = providers[provider.kind]
    if not bucket or bucket[provider.name] ~= provider then return end
    bucket[provider.name] = nil
    if next(bucket) == nil then providers[provider.kind] = nil end
    if defaults[provider.kind] == provider.name then defaults[provider.kind] = nil end

    CoreEventBroker.PublishInternal('core.provider.unregistered.v1', {
        kind = provider.kind,
        name = provider.name,
        owner = provider.owner,
        contract = provider.contract,
        reason = reason or 'unregistered'
    })
end

function CoreProviders.Register(kind, name, implementation, options)
    options = type(options) == 'table' and options or {}
    if not ValidName(kind) or not ValidName(name) or type(implementation) ~= 'table' then
        return CoreResults.Err('invalid_input', 'Provider kind, name, and implementation are required.')
    end

    local contract = tonumber(options.contract)
    if not contract or contract < 1 or contract % 1 ~= 0 then
        return CoreResults.Err('invalid_input', 'Provider contract must be a positive integer.')
    end
    if options.capabilities ~= nil and type(options.capabilities) ~= 'table' then
        return CoreResults.Err('invalid_input', 'Provider capabilities must be a table.')
    end
    if options.health ~= nil and not IsCallable(options.health) then
        return CoreResults.Err('invalid_input', 'Provider health must be callable when provided.')
    end

    providers[kind] = providers[kind] or {}
    if providers[kind][name] then
        return CoreResults.Err('conflict', 'That provider is already registered.', { kind = kind, name = name })
    end
    local maximum = math.max(1, math.floor(tonumber(Config.ProviderRegistry.maxPerKind) or 16))
    if ProviderCount(kind) >= maximum then
        return CoreResults.Err('limit_exceeded', 'That provider kind has reached its registration limit.', { kind = kind })
    end
    if options.default == true and defaults[kind] then
        return CoreResults.Err('conflict', 'That provider kind already has a default.', {
            kind = kind,
            existing = defaults[kind]
        })
    end

    local provider = {
        kind = kind,
        name = name,
        owner = OwnerResource(),
        contract = contract,
        capabilities = Copy(options.capabilities or {}),
        implementation = implementation,
        health = options.health,
        registeredAt = os.time()
    }
    providers[kind][name] = provider
    if options.default == true then defaults[kind] = name end

    local public = PublicRecord(provider)
    CoreEventBroker.PublishInternal('core.provider.registered.v1', public)
    return CoreResults.Ok(public)
end

function CoreProviders.Unregister(kind, name)
    local provider = providers[kind] and providers[kind][name]
    if not provider then
        return CoreResults.Err('not_found', 'That provider is not registered.', { kind = kind, name = name })
    end
    if provider.owner ~= OwnerResource() then
        return CoreResults.Err('forbidden', 'That provider belongs to another resource.')
    end
    RemoveProvider(provider, 'unregistered')
    return CoreResults.Ok(true)
end

function CoreProviders.Get(kind, name, minimumContract)
    if not ValidName(kind) or (name ~= nil and not ValidName(name)) then
        return CoreResults.Err('invalid_input', 'A valid provider kind and optional name are required.')
    end
    name = name or defaults[kind]
    local provider = name and providers[kind] and providers[kind][name] or nil
    if not provider then
        return CoreResults.Err('provider_unavailable', 'The requested provider is unavailable.', {
            kind = kind,
            name = name
        })
    end

    minimumContract = tonumber(minimumContract) or 1
    if minimumContract < 1 or minimumContract % 1 ~= 0 then
        return CoreResults.Err('invalid_input', 'Minimum provider contract must be a positive integer.')
    end
    if provider.contract < minimumContract then
        return CoreResults.Err('unsupported_contract', 'The provider contract is too old.', {
            kind = kind,
            name = name,
            required = minimumContract,
            actual = provider.contract
        })
    end

    return CoreResults.Ok({
        provider = PublicRecord(provider),
        implementation = provider.implementation
    })
end

function CoreProviders.Health(kind, name)
    local resolved = CoreProviders.Get(kind, name, 1)
    if not resolved.ok then return resolved end
    local provider = providers[kind][resolved.value.provider.name]
    if not provider.health then
        return CoreResults.Ok({ state = 'available' })
    end

    local ok, result = pcall(provider.health)
    if not ok then
        logger.Error('provider.health_failed', {
            kind = kind,
            name = provider.name,
            owner = provider.owner,
            reason = tostring(result)
        })
        return CoreResults.Err('provider_unavailable', 'Provider health evaluation failed.')
    end
    if not CoreResults.Is(result) then
        return CoreResults.Err('internal_error', 'Provider health returned an invalid result.')
    end
    return result
end

function CoreProviders.GetProviders()
    local output = {}
    for _, bucket in pairs(providers) do
        for _, provider in pairs(bucket) do output[#output + 1] = PublicRecord(provider) end
    end
    table.sort(output, function(left, right)
        if left.kind == right.kind then return left.name < right.name end
        return left.kind < right.kind
    end)
    return output
end

exports('RegisterProvider', CoreProviders.Register)
exports('UnregisterProvider', CoreProviders.Unregister)
exports('GetProvider', CoreProviders.Get)
exports('GetProviderHealth', CoreProviders.Health)
exports('GetProviders', function() return CoreResults.Ok(CoreProviders.GetProviders()) end)

AddEventHandler('onResourceStop', function(stoppedResource)
    local removal = {}
    for _, bucket in pairs(providers) do
        for _, provider in pairs(bucket) do
            if provider.owner == stoppedResource then removal[#removal + 1] = provider end
        end
    end
    for _, provider in ipairs(removal) do RemoveProvider(provider, 'owner_stopped') end
end)

RegisterCommand('CoreProviderSmokeTest', function(source)
    if source ~= 0 then return end
    CoreProviders.Unregister('core-smoke', 'primary')

    local registered = CoreProviders.Register('core-smoke', 'primary', {
        Ping = function() return 'pong' end
    }, {
        contract = 1,
        capabilities = { ping = 1 },
        default = true,
        health = function() return CoreResults.Ok({ state = 'healthy' }) end
    })
    local resolved = CoreProviders.Get('core-smoke', nil, 1)
    local health = CoreProviders.Health('core-smoke', nil)
    local removed = CoreProviders.Unregister('core-smoke', 'primary')

    local tests = {
        { name = 'provider registered', passed = registered.ok and registered.value.isDefault == true },
        { name = 'default resolved', passed = resolved.ok and resolved.value.implementation.Ping() == 'pong' },
        { name = 'health envelope', passed = health.ok and health.value.state == 'healthy' },
        { name = 'provider removed', passed = removed.ok and not CoreProviders.Get('core-smoke', nil, 1).ok }
    }
    local passed = 0
    for _, test in ipairs(tests) do
        if test.passed then passed = passed + 1 end
        print(('[CoreProviderSmokeTest] %-24s %s'):format(test.name, test.passed and 'PASS' or 'FAIL'))
    end
    print(('[CoreProviderSmokeTest] done %d/%d passed'):format(passed, #tests))
end, true)
