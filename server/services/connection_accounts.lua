CoreAccounts = {}

local logger = CoreLogging.Create(GetCurrentResourceName(), 'accounts')
local pendingByFingerprint = {}
local connectedBySource = {}

local acceptedIdentifierTypes = {
    license = true,
    license2 = true,
    fivem = true,
    steam = true,
    discord = true,
    xbl = true,
    live = true
}

local function PublicContext(context)
    return {
        source = context.source,
        accountId = context.accountId,
        state = context.state,
        displayName = context.account and context.account.display_name or nil,
        accountStatus = context.account and context.account.status or nil,
        created = context.created == true,
        resolvedAt = context.resolvedAt,
        connectedAt = context.connectedAt,
        disconnectedAt = context.disconnectedAt,
        reason = context.reason
    }
end

local function NormalizeIdentifiers(src)
    local normalized, seen = {}, {}
    for _, rawIdentifier in ipairs(GetPlayerIdentifiers(src)) do
        if type(rawIdentifier) == 'string' then
            local identifierType, identifierValue = rawIdentifier:match('^([^:]+):(.+)$')
            identifierType = identifierType and identifierType:lower() or nil
            identifierValue = identifierValue and identifierValue:lower():match('^%s*(.-)%s*$') or nil
            if acceptedIdentifierTypes[identifierType] and identifierValue and identifierValue ~= '' then
                local key = identifierType .. ':' .. identifierValue
                if not seen[key] then
                    seen[key] = true
                    normalized[#normalized + 1] = {
                        type = identifierType,
                        value = identifierValue
                    }
                end
            end
        end
    end

    table.sort(normalized, function(left, right)
        if left.type == right.type then return left.value < right.value end
        return left.type < right.type
    end)
    return normalized
end

local function PrimaryIdentifiers(identifiers)
    local fallback
    for _, identifier in ipairs(identifiers) do
        if identifier.type == 'license' then return { identifier } end
        if identifier.type == 'license2' and not fallback then fallback = identifier end
    end
    return fallback and { fallback } or {}
end

local function Fingerprint(identifiers)
    local parts = {}
    for _, identifier in ipairs(identifiers) do
        parts[#parts + 1] = identifier.type .. ':' .. identifier.value
    end
    return table.concat(parts, '|')
end

local function ResolveInTransaction(src, displayName, identifiers)
    local bodyResult, bodyError
    local executed, committed = pcall(MySQL.startTransaction, function(query)
        local clauses, params = {}, {}
        for _, identifier in ipairs(identifiers) do
            clauses[#clauses + 1] = '(`identifier_type` = ? AND `identifier_value` = ?)'
            params[#params + 1] = identifier.type
            params[#params + 1] = identifier.value
        end

        local matches = query(([[
            SELECT DISTINCT `account_id`
            FROM `core_account_identifiers`
            WHERE %s
            FOR UPDATE
        ]]):format(table.concat(clauses, ' OR ')), params) or {}

        if #matches > 1 then
            bodyResult = CoreResults.Err('identifier_conflict', 'Player identifiers resolve to multiple accounts.')
            return false
        end

        local accountId = matches[1] and matches[1].account_id or nil
        local created = false
        if not accountId then
            local uuidRows = query('SELECT UUID() AS `id`') or {}
            accountId = uuidRows[1] and uuidRows[1].id or nil
            if type(accountId) ~= 'string' or accountId == '' then
                bodyResult = CoreResults.Err('identity_unavailable', 'A Core account ID could not be generated.')
                return false
            end

            query(
                'INSERT INTO `core_accounts` (`id`, `display_name`, `status`) VALUES (?, ?, ?)',
                { accountId, displayName, 'active' }
            )
            created = true
        else
            query('UPDATE `core_accounts` SET `display_name` = ? WHERE `id` = ?', { displayName, accountId })
        end

        for _, identifier in ipairs(identifiers) do
            query([[
                INSERT IGNORE INTO `core_account_identifiers`
                    (`account_id`, `identifier_type`, `identifier_value`)
                VALUES (?, ?, ?)
            ]], { accountId, identifier.type, identifier.value })

            local owners = query([[
                SELECT `account_id`
                FROM `core_account_identifiers`
                WHERE `identifier_type` = ? AND `identifier_value` = ?
                FOR UPDATE
            ]], { identifier.type, identifier.value }) or {}
            if not owners[1] or owners[1].account_id ~= accountId then
                bodyResult = CoreResults.Err('identifier_conflict', 'A player identifier belongs to another account.')
                return false
            end
        end

        local accounts = query([[
            SELECT `id`, `display_name`, `status`, `created_at`, `updated_at`
            FROM `core_accounts`
            WHERE `id` = ?
            FOR UPDATE
        ]], { accountId }) or {}

        local account = accounts[1]
        if not account or account.status ~= 'active' then
            bodyResult = CoreResults.Err('account_unavailable', 'The Core account is not active.')
            return false
        end

        bodyResult = CoreResults.Ok({
            account = account,
            identifiers = identifiers,
            created = created
        })
        return true
    end)

    if not executed then
        return CoreResults.Err('identity_unavailable', 'Core account resolution failed.', {
            reason = tostring(committed)
        })
    end
    if committed ~= true then
        return bodyResult or CoreResults.Err('identity_unavailable', 'Core account resolution was rolled back.', {
            reason = tostring(bodyError)
        })
    end
    return bodyResult
end

function CoreAccounts.Resolve(src, displayName)
    src = tonumber(src)
    displayName = type(displayName) == 'string' and displayName:match('^%s*(.-)%s*$') or ''
    if not src or src <= 0 or displayName == '' then
        return CoreResults.Err('invalid_input', 'A valid player source and display name are required.')
    end

    local identifiers = PrimaryIdentifiers(NormalizeIdentifiers(src))
    if #identifiers == 0 then
        return CoreResults.Err('unauthenticated', 'A Rockstar license identifier is required.')
    end

    local result = ResolveInTransaction(src, displayName:sub(1, 100), identifiers)
    if not result.ok then return result end

    return CoreResults.Ok({
        source = src,
        accountId = result.value.account.id,
        account = result.value.account,
        identifiers = result.value.identifiers,
        identifierFingerprint = Fingerprint(result.value.identifiers),
        state = 'connecting',
        created = result.value.created,
        resolvedAt = os.time()
    })
end

function CoreAccounts.GetContext(src)
    local context = connectedBySource[tonumber(src)]
    if not context then
        return CoreResults.Err('not_found', 'No connected Core account context exists for that source.')
    end
    return CoreResults.Ok(PublicContext(context))
end

function CoreAccounts.GetPrimaryIdentifier(src)
    local context = connectedBySource[tonumber(src)]
    if not context then
        return CoreResults.Err('not_found', 'No connected Core account context exists for that source.')
    end
    local identifier = context.identifiers and context.identifiers[1] or nil
    if not identifier or (identifier.type ~= 'license' and identifier.type ~= 'license2') then
        return CoreResults.Err('not_found', 'No primary account identifier is available.')
    end
    return CoreResults.Ok({
        type = identifier.type,
        value = identifier.value,
        identifier = identifier.type .. ':' .. identifier.value
    })
end

exports('GetPrimaryIdentifier', CoreAccounts.GetPrimaryIdentifier)

function CoreAccounts.GetCounts()
    local pending, connected = 0, 0
    for _ in pairs(pendingByFingerprint) do pending = pending + 1 end
    for _ in pairs(connectedBySource) do connected = connected + 1 end
    return { pending = pending, connected = connected }
end

exports('GetAccountContext', CoreAccounts.GetContext)

local function AccountIdentityGate(src, playerName)
    local result = CoreAccounts.Resolve(src, playerName)
    if not result.ok then
        logger.Warn('account.resolve_rejected', { source = src, code = result.code })
        return 'Your account identity could not be verified. Please try again.'
    end

    local context = result.value
    context.expiresAt = GetGameTimer() + 60000
    context.connectingSource = src
    context.source = nil
    local fingerprint = context.identifierFingerprint
    local existing = pendingByFingerprint[fingerprint]
    if existing and existing.expiresAt and existing.expiresAt > GetGameTimer() then
        logger.Warn('account.connection_duplicate', { source = src, accountId = context.accountId })
        return 'This account is already connecting. Please wait and try again.'
    end
    pendingByFingerprint[fingerprint] = context
    logger.Info('account.resolved', {
        source = src,
        accountId = context.accountId,
        created = context.created
    })
    return nil
end

function SetupAccountIdentity()
    local registered = ConnectionAPI.RegisterGate('feather-core:account-identity', AccountIdentityGate, {
        priority = 10,
        timeoutMs = 10000,
        failClosed = true,
        label = 'account identity',
        failureMessage = 'Your account identity could not be verified. Please try again.'
    })
    if not registered then
        error('Core account identity gate could not be registered.')
    end
end

AddEventHandler('playerJoining', function()
    local src = source
    local currentFingerprint = Fingerprint(PrimaryIdentifiers(NormalizeIdentifiers(src)))
    local pending = pendingByFingerprint[currentFingerprint]
    if not pending then
        logger.Error('account.context_missing', { source = src })
        DropPlayer(src, 'Your account context could not be established. Please reconnect.')
        return
    end

    pendingByFingerprint[currentFingerprint] = nil
    pending.expiresAt = nil
    pending.connectingSource = nil
    pending.source = src
    pending.state = 'connected'
    pending.connectedAt = os.time()
    connectedBySource[src] = pending

    local snapshot = PublicContext(pending)
    CoreEventBroker.PublishInternal('core.account.connected.v1', snapshot)
    TriggerEvent('core.account.connected.v1', snapshot)
end)

AddEventHandler('playerDropped', function(reason)
    local src = source
    for fingerprint, pending in pairs(pendingByFingerprint) do
        if pending.connectingSource == src then
            pendingByFingerprint[fingerprint] = nil
        end
    end
    local context = connectedBySource[src]
    connectedBySource[src] = nil
    if context then
        context.state = 'disconnected'
        context.disconnectedAt = os.time()
        context.reason = tostring(reason or '')
        local snapshot = PublicContext(context)
        CoreEventBroker.PublishInternal('core.account.disconnected.v1', snapshot)
        TriggerEvent('core.account.disconnected.v1', snapshot, snapshot.reason)
    end
end)

AddEventHandler('core.connection.rejected.v1', function(src, gateName)
    src = tonumber(src)
    for fingerprint, pending in pairs(pendingByFingerprint) do
        if pending.connectingSource == src then
            pendingByFingerprint[fingerprint] = nil
            logger.Info('account.pending_released', {
                source = src,
                accountId = pending.accountId,
                rejectedBy = tostring(gateName or 'unknown')
            })
        end
    end
end)

CreateThread(function()
    while true do
        Wait(30000)
        local now = GetGameTimer()
        for fingerprint, context in pairs(pendingByFingerprint) do
            if context.expiresAt and context.expiresAt <= now then
                pendingByFingerprint[fingerprint] = nil
                logger.Warn('account.pending_expired', {
                    source = context.connectingSource,
                    accountId = context.accountId
                })
            end
        end
    end
end)

RegisterCommand('CoreAccountSmokeTest', function(source, args)
    if source ~= 0 then return end
    local target = tonumber(args and args[1])
    if not target then
        local players = GetPlayers()
        target = players[1] and tonumber(players[1]) or nil
    end
    if not target then
        print('[CoreAccountSmokeTest] no connected player is available')
        return
    end

    local tests = {
        {
            name = 'connected context',
            run = function()
                return CoreAccounts.GetContext(target).ok
            end
        },
        {
            name = 'uuid account id',
            run = function()
                local result = CoreAccounts.GetContext(target)
                return result.ok and result.value.accountId:match(
                    '^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$'
                ) ~= nil
            end
        },
        {
            name = 'database account',
            run = function()
                local result = CoreAccounts.GetContext(target)
                if not result.ok then return false end
                return tonumber(MySQL.scalar.await(
                    'SELECT COUNT(*) FROM `core_accounts` WHERE `id` = ?',
                    { result.value.accountId }
                )) == 1
            end
        },
        {
            name = 'license-only anchor',
            run = function()
                local result = CoreAccounts.GetContext(target)
                if not result.ok then return false end
                local rows = MySQL.query.await([[
                    SELECT `identifier_type` FROM `core_account_identifiers`
                    WHERE `account_id` = ?
                ]], { result.value.accountId }) or {}
                if #rows ~= 1 then return false end
                return rows[1].identifier_type == 'license' or rows[1].identifier_type == 'license2'
            end
        },
        {
            name = 'defensive snapshot',
            run = function()
                local first = CoreAccounts.GetContext(target)
                if not first.ok then return false end
                first.value.state = 'tampered'
                local second = CoreAccounts.GetContext(target)
                return second.ok and second.value.state == 'connected'
            end
        }
    }

    local passed = 0
    for _, test in ipairs(tests) do
        local ok, result = pcall(test.run)
        local success = ok and result == true
        if success then passed = passed + 1 end
        print(('[CoreAccountSmokeTest] %-24s %s'):format(test.name, success and 'PASS' or 'FAIL'))
        if not ok then
            logger.Error('account_smoke_test.errored', { test = test.name, reason = tostring(result) })
        end
    end
    print(('[CoreAccountSmokeTest] done %d/%d passed source=%s'):format(passed, #tests, target))
end, true)

RegisterCommand('CoreSplitConnectedAccount', function(source, args)
    if source ~= 0 then return end
    local target = tonumber(args and args[1])
    if not target or args[2] ~= 'CONFIRM' then
        print('[CoreSplitConnectedAccount] usage: CoreSplitConnectedAccount <serverId> CONFIRM')
        return
    end

    local contextResult = CoreAccounts.GetContext(target)
    local sessionResult = CoreSessions and CoreSessions.Get(target) or nil
    local targetAnchors = PrimaryIdentifiers(NormalizeIdentifiers(target))
    if not contextResult.ok or not sessionResult or not sessionResult.ok or #targetAnchors ~= 1 then
        print('[CoreSplitConnectedAccount] target requires a connected account and active Character session')
        return
    end

    local oldAccountId = contextResult.value.accountId
    local targetAnchor = targetAnchors[1]
    local keeperSource, keeperAnchor
    for _, rawSource in ipairs(GetPlayers()) do
        local candidate = tonumber(rawSource)
        if candidate and candidate ~= target then
            local candidateContext = CoreAccounts.GetContext(candidate)
            if candidateContext.ok and candidateContext.value.accountId == oldAccountId then
                if keeperSource then
                    print('[CoreSplitConnectedAccount] multiple other connected sources share this account; split refused')
                    return
                end
                local anchors = PrimaryIdentifiers(NormalizeIdentifiers(candidate))
                if #anchors ~= 1 then
                    print('[CoreSplitConnectedAccount] the account keeper has no unique license anchor')
                    return
                end
                keeperSource, keeperAnchor = candidate, anchors[1]
            end
        end
    end
    if not keeperAnchor or (keeperAnchor.type == targetAnchor.type and keeperAnchor.value == targetAnchor.value) then
        print('[CoreSplitConnectedAccount] a distinct connected account keeper is required')
        return
    end

    local newAccountId, failure
    local executed, committed = pcall(MySQL.startTransaction, function(query)
        local ownerRows = query([[SELECT `account_id` FROM `core_account_identifiers`
            WHERE `identifier_type` = ? AND `identifier_value` = ? FOR UPDATE]],
            { targetAnchor.type, targetAnchor.value }) or {}
        local profileRows = query([[SELECT `account_id` FROM `character_profiles`
            WHERE `character_id` = ? FOR UPDATE]], { sessionResult.value.characterId }) or {}
        if not ownerRows[1] or ownerRows[1].account_id ~= oldAccountId
            or not profileRows[1] or profileRows[1].account_id ~= oldAccountId then
            failure = 'anchor or Character ownership changed'
            return false
        end

        local uuidRows = query('SELECT UUID() AS `id`') or {}
        newAccountId = uuidRows[1] and uuidRows[1].id or nil
        if not newAccountId then failure = 'UUID generation failed'; return false end
        query([[INSERT INTO `core_accounts` (`id`, `display_name`, `status`)
            VALUES (?, ?, 'active')]], { newAccountId, GetPlayerName(target) or ('Source %s'):format(target) })
        query([[DELETE FROM `core_account_identifiers` WHERE `account_id` = ?]], { oldAccountId })
        query([[INSERT INTO `core_account_identifiers` (`account_id`, `identifier_type`, `identifier_value`)
            VALUES (?, ?, ?), (?, ?, ?)]],
            { oldAccountId, keeperAnchor.type, keeperAnchor.value,
              newAccountId, targetAnchor.type, targetAnchor.value })
        query([[INSERT INTO `character_account_state` (`account_id`) VALUES (?)
            ON DUPLICATE KEY UPDATE `account_id` = VALUES(`account_id`)]], { newAccountId })
        query([[UPDATE `character_profiles` SET `account_id` = ?
            WHERE `character_id` = ? AND `account_id` = ?]],
            { newAccountId, sessionResult.value.characterId, oldAccountId })
        query([[DELETE FROM `character_creation_requests` WHERE `character_id` = ?]],
            { sessionResult.value.characterId })
        local verified = query([[SELECT
            (SELECT COUNT(*) FROM `core_account_identifiers` WHERE `account_id` = ?) AS old_anchors,
            (SELECT COUNT(*) FROM `core_account_identifiers` WHERE `account_id` = ?) AS new_anchors,
            (SELECT COUNT(*) FROM `character_profiles` WHERE `character_id` = ? AND `account_id` = ?) AS profile_moved]],
            { oldAccountId, newAccountId, sessionResult.value.characterId, newAccountId }) or {}
        local row = verified[1] or {}
        if tonumber(row.old_anchors) ~= 1 or tonumber(row.new_anchors) ~= 1
            or tonumber(row.profile_moved) ~= 1 then
            failure = 'post-write verification failed'
            return false
        end
        return true
    end)

    if not executed or committed ~= true then
        print(('[CoreSplitConnectedAccount] split failed and rolled back: %s'):format(tostring(failure or committed)))
        return
    end
    print(('[CoreSplitConnectedAccount] split complete source=%s oldAccount=%s newAccount=%s character=%s keeperSource=%s; reconnect source %s now'):format(
        target, oldAccountId, newAccountId, sessionResult.value.characterId, keeperSource, target))
end, true)
