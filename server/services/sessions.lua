CoreSessions = {}

local logger = CoreLogging.Create(GetCurrentResourceName(), 'sessions')
local bySource = {}
local sourceByCharacter = {}
local generationBySource = {}

local function Copy(value)
    if type(value) ~= 'table' then return value end
    local output = {}
    for key, child in pairs(value) do output[key] = Copy(child) end
    return output
end

local function CharacterKey(characterId)
    return tostring(characterId)
end

local function NewSessionId()
    local sessionId = MySQL.scalar.await('SELECT UUID()')
    if type(sessionId) ~= 'string' or sessionId == '' then
        return nil
    end
    return sessionId
end

function CoreSessions.Activate(src, characterId)
    src = tonumber(src)
    if not src or src <= 0 or characterId == nil then
        return CoreResults.Err('invalid_input', 'A valid source and character ID are required.')
    end

    if bySource[src] then
        return CoreResults.Err('conflict', 'That source already has a character session.')
    end

    local accountResult = CoreAccounts.GetContext(src)
    if not accountResult.ok then
        return CoreResults.Err('unauthenticated', 'A connected Core account context is required.')
    end

    local characterKey = CharacterKey(characterId)
    local existingSource = sourceByCharacter[characterKey]
    if existingSource and existingSource ~= src then
        return CoreResults.Err('conflict', 'That character already has an active session.')
    end

    local sessionId = NewSessionId()
    if not sessionId then
        return CoreResults.Err('session_unavailable', 'A character session ID could not be generated.')
    end

    local generation = (generationBySource[src] or 0) + 1
    generationBySource[src] = generation
    local activatedAt = os.time()
    local session = {
        sessionId = sessionId,
        source = src,
        accountId = accountResult.value.accountId,
        characterId = characterId,
        generation = generation,
        state = 'ready',
        activatedAt = activatedAt,
        startedAt = activatedAt -- temporary legacy field; Contract 1 uses activatedAt
    }
    bySource[src] = session
    sourceByCharacter[characterKey] = src

    local snapshot = Copy(session)
    CoreEventBroker.PublishInternal('core.session.ready.v1', snapshot)
    TriggerEvent('core.session.ready.v1', snapshot)
    logger.Info('session.ready', {
        source = src,
        accountId = session.accountId,
        characterId = characterId,
        sessionId = sessionId,
        generation = generation
    })
    return CoreResults.Ok(snapshot)
end

function CoreSessions.Get(src)
    local session = bySource[tonumber(src)]
    if not session or session.state ~= 'ready' then
        return CoreResults.Err('character_required', 'A current character session is required.')
    end
    return CoreResults.Ok(Copy(session))
end

function CoreSessions.IsCurrent(src, sessionId, characterId)
    local session = bySource[tonumber(src)]
    if not session or session.state ~= 'ready' or session.sessionId ~= sessionId then
        return false
    end
    if characterId ~= nil and CharacterKey(session.characterId) ~= CharacterKey(characterId) then
        return false
    end
    return true
end

function CoreSessions.BeginLeaving(src, reason)
    src = tonumber(src)
    local session = bySource[src]
    if not session or session.state ~= 'ready' then
        return CoreResults.Err('character_required', 'A current character session is required.')
    end

    session.state = 'leaving'
    session.reason = type(reason) == 'string' and reason or 'logout'
    session.leavingAt = os.time()
    local snapshot = Copy(session)
    CoreEventBroker.PublishInternal('core.session.leaving.v1', snapshot)
    TriggerEvent('core.session.leaving.v1', snapshot)
    return CoreResults.Ok(snapshot)
end

function CoreSessions.CompleteLeaving(src, sessionId)
    src = tonumber(src)
    local session = bySource[src]
    if not session or session.state ~= 'leaving' or session.sessionId ~= sessionId then
        return CoreResults.Err('session_stale', 'The character session is no longer leaving.')
    end

    bySource[src] = nil
    if sourceByCharacter[CharacterKey(session.characterId)] == src then
        sourceByCharacter[CharacterKey(session.characterId)] = nil
    end
    session.state = 'left'
    session.leftAt = os.time()
    local snapshot = Copy(session)
    CoreEventBroker.PublishInternal('core.session.left.v1', snapshot)
    TriggerEvent('core.session.left.v1', snapshot)
    logger.Info('session.left', {
        source = src,
        accountId = session.accountId,
        characterId = session.characterId,
        sessionId = session.sessionId,
        reason = session.reason
    })
    return CoreResults.Ok(snapshot)
end

function CoreSessions.GetCounts()
    local ready, leaving = 0, 0
    for _, session in pairs(bySource) do
        if session.state == 'ready' then ready = ready + 1 end
        if session.state == 'leaving' then leaving = leaving + 1 end
    end
    return { ready = ready, leaving = leaving }
end

exports('GetSessionContext', CoreSessions.Get)
exports('RequireSession', CoreSessions.Get)
exports('IsSessionCurrent', CoreSessions.IsCurrent)
exports('ActivateSession', CoreSessions.Activate)
exports('BeginSessionLeaving', CoreSessions.BeginLeaving)
exports('CompleteSessionLeaving', CoreSessions.CompleteLeaving)

RegisterCommand('CoreSessionSmokeTest', function(source, args)
    if source ~= 0 then return end
    local target = tonumber(args and args[1])
    if not target then
        local players = GetPlayers()
        target = players[1] and tonumber(players[1]) or nil
    end
    if not target then
        print('[CoreSessionSmokeTest] no connected player is available')
        return
    end

    local tests = {
        {
            name = 'ready session',
            run = function() return CoreSessions.Get(target).ok end
        },
        {
            name = 'uuid session id',
            run = function()
                local result = CoreSessions.Get(target)
                return result.ok and result.value.sessionId:match(
                    '^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$'
                ) ~= nil
            end
        },
        {
            name = 'account binding',
            run = function()
                local session = CoreSessions.Get(target)
                local account = CoreAccounts.GetContext(target)
                return session.ok and account.ok and session.value.accountId == account.value.accountId
            end
        },
        {
            name = 'stale id rejected',
            run = function()
                local session = CoreSessions.Get(target)
                return session.ok and CoreSessions.IsCurrent(
                    target,
                    '00000000-0000-0000-0000-000000000000',
                    session.value.characterId
                ) == false
            end
        }
    }

    local passed = 0
    for _, test in ipairs(tests) do
        local ok, result = pcall(test.run)
        local success = ok and result == true
        if success then passed = passed + 1 end
        print(('[CoreSessionSmokeTest] %-24s %s'):format(test.name, success and 'PASS' or 'FAIL'))
        if not ok then
            logger.Error('session_smoke_test.errored', { test = test.name, reason = tostring(result) })
        end
    end
    print(('[CoreSessionSmokeTest] done %d/%d passed source=%s'):format(passed, #tests, target))
end, true)
