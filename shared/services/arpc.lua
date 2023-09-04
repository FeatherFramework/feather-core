------- File Information --------
-- Redm RPC
-- OG Script: https://github.com/egerdnc/redm-rpc
-----------------------------------

--  Track all queued callbacks
local pendingCallbacks = {}

-- Track the number of queued callbacks
local pendingCallbackCount = 0

-- Remote methods table
local registeredProcedures = {}

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
local function GetResponseFunction(id)
    if not id then
        return function() end
    end
    return function(...)
        TriggerRemoteEvent("Feather:Response", source, id, ...)
    end
end

---------------------
--  Main functions --
---------------------

-- Enacts the RPC Procedures that was registered. if the RPC has a callback, add it the the queue.
local function CallRemoteProcedures(name, params, callback, source)
    local id = nil
    if callback then
        id = GetNextId()
        pendingCallbacks[id] = callback
    end

    return TriggerRemoteEvent("Feather:Call", source, id, name, params)
end


--------------------
-- Event handling --
--------------------

-- Handle the outgoing rpc
AddEventHandler("Feather:Call", function(id, name, params)
    if type(name) ~= "string" then
        print("Name must be a string")
        return
    end
    if not registeredProcedures[name] then
        print("Procedure is not registered:", name, registeredProcedures)
        return
    end

    local activeProcedure = registeredProcedures[name]

    local returnValues = { activeProcedure(params, GetResponseFunction(id), source) }
    if #returnValues > 0 and id then
        TriggerRemoteEvent("Feather:Response", source, id, table.unpack(returnValues))
    end
end)

-- Handle the incomming response from the rpc
AddEventHandler("Feather:Response", function(id, ...)
    if not id then
        print("RPC callback ID not found: ", id)
        return
    end
    if not pendingCallbacks[id] then
        print("RPC callback not found: ", id)
        return
    end


    pendingCallbacks[id](...)
    pendingCallbacks[id] = nil
end)

--------------------
--    RPC API     --
--------------------

-- Register the procedure/method
function RPCAPI.Register(name, callback)
    if Config.DevMode then
        print("Registered RPC: ", name)
    end

    registeredProcedures[name] = callback

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
function RPCAPI.Call(name, params, callback, source)
    if not params then
        params = {}
    end
    return CallRemoteProcedures(name, params, callback, source)
end

-- Send a single rpc but with async
function RPCAPI.CallAsync(name, params, source)
    if not params then
        params = {}
    end

    -- Create a new promise "thread". Learn More: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise
    local p = promise.new()

    CallRemoteProcedures(name, params, function(...)
        -- Resolve the promise (tell the promise that it is done and can now proceed.)
        p:resolve({ ... })
    end, source)

    -- Unpack the "awaited" promise. (Waits for the promise to be "done"/resolved)
    return table.unpack(Citizen.Await(p))
end
