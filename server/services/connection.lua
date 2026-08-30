ConnectionAPI = {}

local gates = {}
local nextSequence = 0

local function isFunctionReference(callback)
    return type(callback) == 'table'
        and type(rawget(callback, '__cfx_functionReference')) == 'string'
end

local function ownerResource()
    local owner = GetInvokingResource and GetInvokingResource() or nil
    if type(owner) ~= 'string' or owner == '' then return GetCurrentResourceName() end
    return owner
end

local function sortedGates()
    local ordered = {}
    for _, gate in pairs(gates) do ordered[#ordered + 1] = gate end
    table.sort(ordered, function(a, b)
        if a.priority == b.priority then return a.sequence < b.sequence end
        return a.priority < b.priority
    end)
    return ordered
end

-- Registers one connection check. Returning a non-empty string rejects the
-- connection; returning nil accepts it and advances to the next gate.
function ConnectionAPI.RegisterGate(name, callback, options, registeredOwner)
    local directCallback = type(callback) == 'function' or isFunctionReference(callback)
    local exportCallback = not directCallback and type(callback) == 'table'
        and type(callback.resource) == 'string' and callback.resource ~= ''
        and type(callback.export) == 'string' and callback.export ~= ''
    if type(name) ~= 'string' or name == '' or (not directCallback and not exportCallback) then
        print('[feather-core] Connection.RegisterGate requires a name and a function or export descriptor.')
        return false
    end

    options = type(options) == 'table' and options or {}
    -- A direct callback declared by Core belongs to Core even when setup is
    -- resumed from an oxmysql callback. Export descriptors retain the
    -- invoking resource as their owner.
    local owner = registeredOwner or (directCallback and GetCurrentResourceName() or ownerResource())
    if exportCallback and callback.resource ~= owner then
        print(("[feather-core] Connection gate '%s' cannot register an export owned by %s from %s.")
            :format(name, callback.resource, owner))
        return false
    end

    local existing = gates[name]
    if existing and existing.owner ~= owner then
        print(("[feather-core] Connection gate '%s' belongs to %s; registration from %s rejected.")
            :format(name, existing.owner, owner))
        return false
    end

    if not existing then
        nextSequence = nextSequence + 1
    end

    gates[name] = {
        name = name,
        owner = owner,
        callback = callback,
        callbackType = directCallback and 'function' or 'export',
        sequence = existing and existing.sequence or nextSequence,
        priority = tonumber(options.priority) or 100,
        timeoutMs = math.max(1000, tonumber(options.timeoutMs) or 10000),
        failClosed = options.failClosed ~= false,
        label = type(options.label) == 'string' and options.label or name,
        failureMessage = type(options.failureMessage) == 'string' and options.failureMessage
            or 'A required connection check could not be completed. Please try again.'
    }
    return true
end

function ConnectionAPI.UnregisterGate(name)
    local gate = gates[name]
    if not gate or gate.owner ~= ownerResource() then return false end

    gates[name] = nil
    return true
end

exports('RegisterConnectionGate', function(name, callback, options)
    local caller = ownerResource()
    local descriptorOwner = type(callback) == 'table' and callback.resource or nil
    if type(descriptorOwner) ~= 'string' or descriptorOwner == '' then
        return ConnectionAPI.RegisterGate(name, callback, options, caller)
    end

    if caller ~= GetCurrentResourceName() and caller ~= descriptorOwner then
        print(("[feather-core] Connection gate '%s' descriptor owner %s does not match caller %s.")
            :format(tostring(name), descriptorOwner, caller))
        return false
    end
    return ConnectionAPI.RegisterGate(name, callback, options, descriptorOwner)
end)

function ConnectionAPI.GetGates()
    local output = {}
    for _, gate in ipairs(sortedGates()) do
        output[#output + 1] = {
            name = gate.name,
            owner = gate.owner,
            priority = gate.priority,
            timeoutMs = gate.timeoutMs,
            failClosed = gate.failClosed,
            type = gate.callbackType,
            label = gate.label
        }
    end
    return output
end

exports('GetConnectionGates', function()
    return CoreResults.Ok(ConnectionAPI.GetGates())
end)

RegisterCommand('CoreConnectionGates', function(source)
    if source ~= 0 then return end

    for _, gate in ipairs(ConnectionAPI.GetGates()) do
        print(('[CoreConnectionGates] name=%s owner=%s priority=%s type=%s failClosed=%s'):format(
            gate.name, gate.owner, gate.priority, gate.type, tostring(gate.failClosed)))
    end
end, true)

local function runGate(gate, src, playerName)
    local completed, succeeded, result = false, false, nil
    CreateThread(function()
        local ok, rejection
        if gate.callbackType == 'export' then
            ok, rejection = pcall(function()
                local resourceExports = exports[gate.callback.resource]
                -- Dynamic export calls must preserve Lua's method semantics.
                -- Without the proxy as `self`, CFX consumes the first payload
                -- argument and the callee receives playerName in place of src.
                return resourceExports[gate.callback.export](resourceExports, src, playerName)
            end)
        else
            ok, rejection = pcall(gate.callback, src, playerName)
        end
        if completed then return end
        succeeded, result, completed = ok, rejection, true
    end)

    local deadline = GetGameTimer() + gate.timeoutMs
    while not completed and GetGameTimer() < deadline do Wait(0) end

    if not completed then
        completed = true
        print(("[feather-core] Connection gate '%s' timed out after %sms."):format(gate.name, gate.timeoutMs))
        return gate.failClosed and gate.failureMessage or nil
    end

    if not succeeded then
        print(("[feather-core] Connection gate '%s' failed: %s"):format(gate.name, tostring(result)))
        return gate.failClosed and gate.failureMessage or nil
    end

    if result == nil or result == false then return nil end

    if type(result) ~= 'string' or result == '' then
        print(("[feather-core] Connection gate '%s' returned an invalid rejection value."):format(gate.name))
        return gate.failClosed and gate.failureMessage or nil
    end
    return result
end

function ConnectionAPI.RunGates(src, playerName, deferrals)
    for _, gate in ipairs(sortedGates()) do
        deferrals.update(('Checking %s...'):format(gate.label))
        local rejection = runGate(gate, src, playerName)
        if rejection then
            TriggerEvent('core.connection.rejected.v1', src, gate.name, rejection)
            return rejection
        end
    end
    return nil
end

AddEventHandler('onResourceStop', function(resourceName)
    for name, gate in pairs(gates) do
        if gate.owner == resourceName then gates[name] = nil end
    end
end)
