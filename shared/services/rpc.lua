------- File Information --------
-- Redm RPC
-- OG Script: https://github.com/egerdnc/redm-rpc
-----------------------------------

--  Track all queued callbacks
local pendingCallbacks = {}

-- Track the number of queued callbacks
local pendingCallbackCount = 0

-- Tracks any callbacks that were called before resourcestarted
local pendingActivation = {}

-- Tracks if the resource has started.
local isResourceStarted = false

-- Remote methods table
local registeredMethods = {}

-- RPC API
RPCAPI = {}

-- Wait for resource to start before executing rpc's
RPCAPI.isWaitingForResourceStart = true

if IsOnServer() then
    -- Server event registry
    RegisterServerEvent("bcc:call")
    RegisterServerEvent("bcc:response")
else
    -- Client event registry
    RegisterNetEvent("bcc:call")
    RegisterNetEvent("bcc:response")
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
local function GetResponseFunction(id)
    if not id then
        return function () end
    end
    return function(...)
        TriggerRemoteEvent("bcc:response", source, id, ...)
    end
end

---------------------
--  Main functions --
---------------------

-- Enacts the RPC Method that was registered. if the RPC has a callback, add it the the queue.
local function CallRemoteMethod(name, params, callback, source)
    assert(type(name) == "string", "[RPC] CallRemoteMethod: Invalid method name. Expected string, got "..type(name))
    assert(type(params) == "table", "[RPC] CallRemoteMethod: Invalid params. Expected table, got "..type(params))

    local id = nil
    if callback then
        id = GetNextId()
        pendingCallbacks[id] = callback
    end

    return TriggerRemoteEvent("bcc:call", source, id, name, params)
end

-- Register the RPC Method/Procedure
local function RegisterMethod(name, callback)
    assert(type(name) == "string", "[RPC] RegisterMethod: Invalid method name. Expected string, got "..type(name))
    assert(callback, "[RPC] RegisterMethod: Invalid callback. Expected callback, got "..type(callback))

    registeredMethods[name] = callback
    return true
end

-- Call a method within this file, if this resource hasny initiated yet, cache the function for use later.
local function CallMethod(func, ...)
    if isResourceStarted or not RPCAPI.isWaitingForResourceStart then
        return func(...)
    else
        table.insert(pendingActivation, {
            func = func,
            args = {...}
        })
    end
end

--------------------
-- Event handling --
--------------------

-- Handle the outgoing rpc
AddEventHandler("bcc:call", function (id, name, params)
    if type(name) ~= "string" then return end
    if not registeredMethods[name] then return end

    local returnValues = {registeredMethods[name](params, source, GetResponseFunction(id))}
    if #returnValues > 0 and id then
        TriggerRemoteEvent("bcc:response", source, id, table.unpack(returnValues))
    end
end)

-- Handle the incomming response from the rpc
AddEventHandler("bcc:response", function (id, ...)
    if not id then return end
    if not pendingCallbacks[id] then return end
    pendingCallbacks[id](...)
    pendingCallbacks[id] = nil
end)

-- When the resource starts, loop through any pending RPC API calls that may have been called before startup.
AddEventHandler(("on%sResourceStart"):format(IsDuplicityVersion() and "Server" or "Client"), function (resource)
    if GetCurrentResourceName() ~= resource then return end

    for i, c in ipairs(pendingActivation) do
        c.func(table.unpack(c.args))
    end

    isResourceStarted = true
end)

--------------------
--    RPC API     --
--------------------

-- Register the procedure/method
function RPCAPI.Register(name, callback)
    return CallMethod(RegisterMethod, name, callback)
end

-- Send a single RPC but emit a callback
function RPCAPI.Notify(name, params, source)
    if not params then
        params = {}
    end
    return CallMethod(CallRemoteMethod, name, params, nil, source)
end

-- Send a single rpc
function RPCAPI.Call(name, params, callback, source)
    if not params then
        params = {}
    end
    return CallMethod(CallRemoteMethod, name, params, callback, source)
end

-- Send a single rpc but with async 
function RPCAPI.CallAsync(name, params, source)
    if not params then
        params = {}
    end

    -- Create a new promise "thread". Learn More: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise
    local p = promise.new()

    CallMethod(CallRemoteMethod, name, params, function (...)
        -- Resolve the promise (tell the promise that it is done and can now proceed.)
        p:resolve({...})
    end, source)

    -- Unpack the "awaited" promise. (Waits for the promise to be "done"/resolved)
    return table.unpack(Citizen.Await(p))
end