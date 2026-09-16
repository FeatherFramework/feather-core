-- Client readiness mirrors the server AwaitReady contract through Core's
-- versioned health RPC. Resource dependency order does not guarantee that the
-- server has completed migrations and service registration when a client VM
-- begins running.
if IsDuplicityVersion() then return end

local function AwaitClientReady(timeoutMs)
    timeoutMs = tonumber(timeoutMs) or 10000
    if timeoutMs < 0 or timeoutMs > 60000 then
        return CoreResults.Err('invalid_input', 'timeoutMs must be between 0 and 60000.')
    end

    local deadline = GetGameTimer() + timeoutMs
    repeat
        local remaining = math.max(1, deadline - GetGameTimer())
        local result = RPCAPI.CallAsync('core.health.v1', {}, nil, math.min(remaining, 2000))
        if CoreResults.Is(result) and type(result.value) == 'table' then
            if result.value.state == 'ready' then
                return CoreResults.Ok(result.value)
            end
            if result.value.state == 'failed' then
                return CoreResults.Err('not_ready', 'Feather Core failed to start.', { health = result.value })
            end
        end

        if GetGameTimer() >= deadline then break end
        Wait(math.min(250, math.max(0, deadline - GetGameTimer())))
    until false

    return CoreResults.Err('timeout', 'Timed out waiting for Feather Core readiness.')
end

exports('AwaitReady', AwaitClientReady)

RegisterCommand('CoreClientReadinessSmokeTest', function()
    local result = AwaitClientReady(3000)
    local passed = result.ok == true and type(result.value) == 'table' and result.value.state == 'ready'
    print(('[CoreClientReadinessSmokeTest] client await ready       %s'):format(passed and 'PASS' or 'FAIL'))
    print(('[CoreClientReadinessSmokeTest] done %d/1 passed'):format(passed and 1 or 0))
end, false)
