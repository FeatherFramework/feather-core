local logger = CoreLogging.Create(GetCurrentResourceName(), 'rpc')

local healthRoute = RPCAPI.RegisterContract('core.health.v1', function()
    return CoreResults.Ok(CoreFoundation.GetHealth())
end, {
    contract = 1,
    direction = 'client_to_server',
    windowMs = 1000,
    maxCalls = 2,
    maxPayloadBytes = 64,
    maxDepth = 2,
    maxNodes = 4,
    validatePayload = function(payload)
        return type(payload) == 'table' and next(payload) == nil, 'core.health.v1 does not accept payload fields.'
    end
})

if not healthRoute.ok then
    error(('[%s] %s'):format(healthRoute.code, healthRoute.message))
end

exports('RegisterRpc', function(name, callback, options)
    return RPCAPI.RegisterContract(name, callback, options)
end)

exports('GetRpcRoutes', function()
    return CoreResults.Ok(RPCAPI.GetRoutes())
end)

RegisterCommand('CoreRpcSmokeTest', function(source)
    if source ~= 0 then return end

    local function FindRoute(name)
        for _, route in ipairs(RPCAPI.GetRoutes()) do
            if route.route == name then return route end
        end
        return nil
    end

    local tests = {
        {
            name = 'contract route',
            run = function()
                local route = FindRoute('core.health.v1')
                return route and route.contract == 1
            end
        },
        {
            name = 'route ownership',
            run = function()
                local route = FindRoute('core.health.v1')
                return route and route.owner == GetCurrentResourceName()
            end
        },
        {
            name = 'session kernel binding',
            run = function()
                return type(CoreSessions) == 'table' and type(CoreSessions.IsCurrent) == 'function'
            end
        },
        {
            name = 'duplicate rejected',
            run = function()
                local result = RPCAPI.RegisterContract('core.health.v1', function()
                    return CoreResults.Ok(true)
                end)
                return result.ok == false and result.code == 'conflict'
            end
        }
    }

    local passed = 0
    for _, test in ipairs(tests) do
        local ok, result = pcall(test.run)
        local success = ok and result == true
        if success then passed = passed + 1 end
        print(('[CoreRpcSmokeTest] %-24s %s'):format(test.name, success and 'PASS' or 'FAIL'))
        if not ok then
            logger.Error('rpc_smoke_test.errored', { test = test.name, reason = tostring(result) })
        end
    end
    print(('[CoreRpcSmokeTest] done %d/%d passed'):format(passed, #tests))
end, true)
