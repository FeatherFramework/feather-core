------- File Information --------
-- Redm RPC
-- Inspired by: https://github.com/egerdnc/redm-rpc
-----------------------------------

--  Track all queued callbacks
local pendingCallbacks = {}

-- Track the number of queued callbacks
local pendingCallbackCount = 0

-- Remote methods table
local registeredProcedures = {}
local procedureCallWindows = {}

-- RPC API
RPCAPI = {}

-- Wait for resource to start before executing rpc's
RPCAPI.isWaitingForResourceStart = true

if IsOnServer() then
    -- Server event registry
    RegisterServerEvent("Feather:Call")
    RegisterServerEvent("Feather:Response")
else
    -- Client event registry
    RegisterNetEvent("Feather:Call")
    RegisterNetEvent("Feather:Response")
end

----------------------
-- Helper functions --
----------------------

local function GetNextId()
    pendingCallbackCount = pendingCallbackCount + 1
    return pendingCallbackCount
end

-- Trigger the remote event (client or server respective)
local function TriggerRemoteEvent(eventName, source, ...)
    -- Check if on server or client
    if IsOnServer() then
        TriggerClientEvent(eventName, source or -1, ...)
    else
        TriggerServerEvent(eventName, ...)
    end
end

-- Gets the response of the RPC, if available.
local function GetResponseFunction(id, requestSource, expectedSession)
    if not id then
        return function() end
    end
    local responded = false
    return function(...)
        if responded then return end
        responded = true
        if expectedSession and IsOnServer() then
            if not CharacterAPI or not CharacterAPI.IsSessionCurrent
                or not CharacterAPI.IsSessionCurrent(requestSource, expectedSession.sessionId, expectedSession.characterId) then
                TriggerRemoteEvent("Feather:Response", requestSource, id, nil, {
                    code = 'character_session_expired',
                    message = 'Character session is no longer current.'
                })
                return
            end
        end
        TriggerRemoteEvent("Feather:Response", requestSource, id, ...)
    end
end

-----------------------
-- Rate limiting --
-----------------------

-- Per-source rolling window over the shared Feather:Call bus. Every
-- procedure registered by every resource (core and downstream repos alike,
-- since RPCAPI.Register is a single table shared via the export) is
-- dispatched through the handler below, so limiting there protects the
-- whole RPC surface at once instead of each procedure reinventing a
-- throttle. (CORE-06)
local rpcCallWindows = {}

local function IsRateLimited(src)
    if not IsOnServer() or not src or src == 0 then
        return false
    end

    local now = GetGameTimer()
    local window = rpcCallWindows[src]

    if not window or (now - window.start) > Config.RPCRateLimit.windowMs then
        rpcCallWindows[src] = { start = now, count = 1 }
        return false
    end

    window.count = window.count + 1
    return window.count > Config.RPCRateLimit.maxCalls
end

local function IsProcedureRateLimited(src, name, policy)
    if not IsOnServer() or not src or src == 0 or not policy.maxCalls then return false end

    local now = GetGameTimer()
    procedureCallWindows[src] = procedureCallWindows[src] or {}
    local window = procedureCallWindows[src][name]
    if not window or (now - window.start) > policy.windowMs then
        procedureCallWindows[src][name] = { start = now, count = 1 }
        return false
    end

    window.count = window.count + 1
    return window.count > policy.maxCalls
end

local function RpcError(code, message)
    return { code = code, message = message }
end

if IsOnServer() then
    AddEventHandler('playerDropped', function()
        rpcCallWindows[source] = nil
        procedureCallWindows[source] = nil
    end)

    AddEventHandler('onResourceStop', function(resourceName)
        for name, procedure in pairs(registeredProcedures) do
            if procedure.owner == resourceName then registeredProcedures[name] = nil end
        end
    end)
end

---------------------
--  Main functions --
---------------------

-- Enacts the RPC Procedures that was registered. if the RPC has a callback, add it the the queue.
local function CallRemoteProcedures(name, params, callback, source, timeoutMs)
    local id = nil
    if callback then
        id = GetNextId()
        local expectedSource = IsOnServer() and source or nil
        pendingCallbacks[id] = { callback = callback, expectedSource = expectedSource, name = name }

        local timeout = tonumber(timeoutMs) or tonumber(Config.RPCRateLimit.timeoutMs) or 10000
        SetTimeout(math.max(1000, timeout), function()
            local pending = pendingCallbacks[id]
            if not pending then return end
            pendingCallbacks[id] = nil
            local ok, err = pcall(pending.callback, nil, RpcError('timeout', ('RPC timed out: %s'):format(tostring(name))))
            if not ok then print(('RPC timeout callback failed: %s'):format(tostring(err))) end
        end)
    end

    return TriggerRemoteEvent("Feather:Call", source, id, name, params)
end


--------------------
-- Event handling --
--------------------

-- Handle the outgoing rpc
AddEventHandler("Feather:Call", function(id, name, params)
    local requestSource = source
    -- (CORE-11) The rate-limit check used to run *after* the type/
    -- registration checks below, so a client spamming malformed or
    -- unregistered procedure names never actually hit IsRateLimited and
    -- could flood the server console (and, via the old `registeredProcedures`
    -- dump, leak every registered RPC name) at an unbounded rate. Checking
    -- first means every call -- valid or not -- counts against the same
    -- window.
    if IsRateLimited(source) then
        if id then TriggerRemoteEvent("Feather:Response", requestSource, id, nil, RpcError('rate_limited', 'RPC rate limit exceeded.')) end
        return
    end

    if type(name) ~= "string" then
        print("Name must be a string")
        if id then TriggerRemoteEvent("Feather:Response", requestSource, id, nil, RpcError('invalid_request', 'RPC name must be a string.')) end
        return
    end
    if not registeredProcedures[name] then
        print("Procedure is not registered:", name)
        if id then TriggerRemoteEvent("Feather:Response", requestSource, id, nil, RpcError('not_found', 'RPC procedure is not registered.')) end
        return
    end

    local registered = registeredProcedures[name]
    local policy = registered.policy
    if IsProcedureRateLimited(requestSource, name, policy) then
        if id then TriggerRemoteEvent("Feather:Response", requestSource, id, nil, RpcError('rate_limited', 'RPC procedure rate limit exceeded.')) end
        return
    end

    local requestContext = nil
    if IsOnServer() then
        requestContext = {
            source = requestSource,
            correlationId = ('rpc:%s:%s:%s'):format(tostring(requestSource), tostring(GetGameTimer()), tostring(id or 'notify'))
        }

        if policy.requireCharacter then
            local session = CharacterAPI and CharacterAPI.ResolveSession and CharacterAPI.ResolveSession(requestSource) or nil
            if not session then
                if id then TriggerRemoteEvent("Feather:Response", requestSource, id, nil,
                    RpcError('character_required', 'A current character session is required.')) end
                return
            end
            requestContext.characterId = session.characterId
            requestContext.sessionId = session.sessionId
            requestContext.character = session.character
        end
    end

    local encodedOk, encoded = pcall(json.encode, params)
    if not encodedOk or type(encoded) ~= 'string' or #encoded > policy.maxPayloadBytes then
        if id then TriggerRemoteEvent("Feather:Response", requestSource, id, nil, RpcError('payload_too_large', 'RPC payload is too large.')) end
        return
    end

    local ok, returnValues = pcall(function()
        local responseSession = policy.requireCharacter and requestContext or nil
        return { registered.callback(params, GetResponseFunction(id, requestSource, responseSession), requestSource, requestContext) }
    end)
    if not ok then
        print(("RPC procedure '%s' failed: %s"):format(name, tostring(returnValues)))
        if id then TriggerRemoteEvent("Feather:Response", requestSource, id, nil, RpcError('internal_error', 'RPC procedure failed.')) end
        return
    end
    if #returnValues > 0 and id then
        TriggerRemoteEvent("Feather:Response", requestSource, id, table.unpack(returnValues))
    end
end)

-- Handle the incomming response from the rpc
AddEventHandler("Feather:Response", function(id, ...)
    if type(id) ~= 'number' then return end
    local pending = pendingCallbacks[id]
    if not pending then return end
    if IsOnServer() and pending.expectedSource ~= source then return end

    pendingCallbacks[id] = nil
    local ok, err = pcall(pending.callback, ...)
    if not ok then print(('RPC response callback failed: %s'):format(tostring(err))) end
end)

--------------------
--    RPC API     --
--------------------

-- Register the procedure/method
function RPCAPI.Register(name, callback, options)
    if type(name) ~= 'string' or name == '' or not IsCallable(callback) then
        print(('RPC.Register rejected invalid registration: name=%s callbackType=%s')
            :format(tostring(name), type(callback)))
        return false
    end
    options = type(options) == 'table' and options or {}
    local owner = GetInvokingResource and GetInvokingResource() or nil
    owner = owner or GetCurrentResourceName()
    local existing = registeredProcedures[name]
    if existing and existing.owner ~= owner then
        print(("RPC procedure '%s' is already owned by %s; registration from %s rejected."):format(name, existing.owner, owner))
        return false
    end

    local defaults = Config.RPCRateLimit or {}
    local policy = {
        windowMs = math.max(100, tonumber(options.windowMs) or tonumber(defaults.windowMs) or 1000),
        maxCalls = options.maxCalls and math.max(1, tonumber(options.maxCalls) or 1) or nil,
        maxPayloadBytes = math.max(64, tonumber(options.maxPayloadBytes) or tonumber(defaults.maxPayloadBytes) or 65536),
        requireCharacter = options.requireCharacter == true
    }
    if Config.DevMode then
        print("Registered RPC: ", name)
    end

    registeredProcedures[name] = { callback = callback, policy = policy, owner = owner }

    return true
end

-- Send a single RPC but emit a callback
function RPCAPI.Notify(name, params, source)
    if not params then
        params = {}
    end
    return CallRemoteProcedures(name, params, nil, source)
end

-- Send a single rpc
function RPCAPI.Call(name, params, callback, source, timeoutMs)
    if not params then
        params = {}
    end
    return CallRemoteProcedures(name, params, callback, source, timeoutMs)
end

-- Send a single rpc but with async
function RPCAPI.CallAsync(name, params, source, timeoutMs)
    if not params then
        params = {}
    end

    -- Create a new promise "thread". Learn More: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise
    local p = promise.new()

    CallRemoteProcedures(name, params, function(...)
        -- Resolve the promise (tell the promise that it is done and can now proceed.)
        p:resolve({ ... })
    end, source, timeoutMs)

    -- Unpack the "awaited" promise. (Waits for the promise to be "done"/resolved)
    return table.unpack(Citizen.Await(p))
end
