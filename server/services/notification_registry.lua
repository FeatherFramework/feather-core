CoreNotifications = {}

local logger = CoreLogging.Create(GetCurrentResourceName(), 'notifications')
local supportedStyles = {
    tooltip = true,
    advanced = true,
    location = true,
    right = true,
    left = true,
    top_banner = true,
    advanced_right = true,
    top = true,
    center = true,
    standard = true,
    bottom_right = true,
    mission_failed = true,
    dead_player = true,
    warning = true
}
local optionalFields = {
    title = true,
    location = true,
    dictionary = true,
    icon = true,
    color = true,
    quality = true,
    audioSource = true,
    audioName = true
}
local allowedFields = {
    source = true,
    style = true,
    message = true,
    duration = true
}
for field in pairs(optionalFields) do allowedFields[field] = true end
local rateBuckets = {}

local function PositiveLimit(name, fallback)
    return math.max(1, math.floor(tonumber(Config.NotificationRegistry[name]) or fallback))
end

local function ValidateOptionalString(request, normalized, field, maximum)
    local value = request[field]
    if value == nil then return nil end
    if type(value) ~= 'string' or #value > maximum then
        return CoreResults.Err('invalid_input', 'Notification field is invalid.', {
            field = field,
            maxLength = maximum
        })
    end
    normalized[field] = value
    return nil
end

local function RateLimitSettings()
    local windowMs = math.min(60000, math.max(100,
        math.floor(tonumber(Config.NotificationRegistry.rateWindowMs) or 1000)))
    local maxCalls = math.min(1000, math.max(1,
        math.floor(tonumber(Config.NotificationRegistry.maxCallsPerWindow) or 20)))
    return windowMs, maxCalls
end

local function CheckRateLimit(source)
    local now = GetGameTimer()
    local windowMs, maxCalls = RateLimitSettings()
    local bucket = rateBuckets[source]
    if not bucket or now >= bucket.resetsAt then
        bucket = { count = 0, resetsAt = now + windowMs }
        rateBuckets[source] = bucket
    end
    if bucket.count >= maxCalls then
        return CoreResults.Err('rate_limited', 'Notification dispatch rate exceeded.', {
            retryAfterMs = math.max(0, bucket.resetsAt - now),
            maxCalls = maxCalls,
            windowMs = windowMs
        })
    end
    bucket.count = bucket.count + 1
    return CoreResults.Ok(true)
end

local function ResetRateLimit(source)
    if source then rateBuckets[source] = nil end
end

local function ProviderLimit(limits, name)
    local value = type(limits) == 'table' and tonumber(limits[name]) or nil
    if not value or value % 1 ~= 0 then return nil end
    return value
end

local function ValidateProviderLimits(provider, request)
    local capabilities = provider.capabilities
    local limits = type(capabilities) == 'table' and capabilities.limits or nil
    local maxMessage = ProviderLimit(limits, 'maxMessageLength')
    local maxTitle = ProviderLimit(limits, 'maxTitleLength')
    local maxLocation = ProviderLimit(limits, 'maxLocationLength')
    local maxIdentifier = ProviderLimit(limits, 'maxIdentifierLength')
    local maxDuration = ProviderLimit(limits, 'maxDurationMs')
    local minQuality = ProviderLimit(limits, 'minQuality')
    local maxQuality = ProviderLimit(limits, 'maxQuality')
    if not maxMessage or maxMessage < 1 or not maxTitle or maxTitle < 1
        or not maxLocation or maxLocation < 1 or not maxIdentifier or maxIdentifier < 1
        or not maxDuration or maxDuration < 1 or not minQuality or not maxQuality
        or minQuality > maxQuality then
        return CoreResults.Err('provider_unavailable', 'The notification provider advertises invalid limits.', {
            provider = provider.name
        })
    end

    local checks = {
        { field = 'message', maximum = maxMessage },
        { field = 'title', maximum = maxTitle },
        { field = 'location', maximum = maxLocation },
        { field = 'dictionary', maximum = maxIdentifier },
        { field = 'icon', maximum = maxIdentifier },
        { field = 'color', maximum = maxIdentifier },
        { field = 'audioSource', maximum = maxIdentifier },
        { field = 'audioName', maximum = maxIdentifier }
    }
    for _, check in ipairs(checks) do
        local value = request[check.field]
        if value ~= nil and #value > check.maximum then
            return CoreResults.Err('provider_unavailable', 'The notification exceeds provider limits.', {
                provider = provider.name,
                field = check.field,
                maximum = check.maximum
            })
        end
    end
    if request.duration > maxDuration then
        return CoreResults.Err('provider_unavailable', 'The notification exceeds provider limits.', {
            provider = provider.name,
            field = 'duration',
            maximum = maxDuration
        })
    end
    if request.quality ~= nil and (request.quality < minQuality or request.quality > maxQuality) then
        return CoreResults.Err('provider_unavailable', 'The notification exceeds provider limits.', {
            provider = provider.name,
            field = 'quality',
            minimum = minQuality,
            maximum = maxQuality
        })
    end
    return CoreResults.Ok(true)
end

local function Copy(value, seen)
    if type(value) ~= 'table' then return value end

    seen = seen or {}
    if seen[value] then return nil end

    local output = {}
    seen[value] = output
    for key, child in pairs(value) do output[Copy(key, seen)] = Copy(child, seen) end
    return output
end

local function Validate(request)
    if type(request) ~= 'table' then
        return CoreResults.Err('invalid_input', 'Notification request must be a table.')
    end

    for key in pairs(request) do
        if not allowedFields[key] then
            return CoreResults.Err('invalid_input', 'Unknown notification field.', { field = key })
        end
    end

    local source = tonumber(request.source)
    if not source or source < 1 or source % 1 ~= 0 then
        return CoreResults.Err('invalid_input', 'Notification source must be a positive player ID.')
    end
    if GetPlayerName(source) == nil then
        return CoreResults.Err('invalid_input', 'Notification source must be a connected player.', {
            source = source
        })
    end

    local style = request.style or 'right'
    if not supportedStyles[style] then
        return CoreResults.Err('invalid_input', 'Notification style is unsupported.', { style = style })
    end

    local message = request.message
    local maximum = PositiveLimit('maxMessageLength', 512)
    if type(message) ~= 'string' or message == '' or #message > maximum then
        return CoreResults.Err('invalid_input', 'Notification message is invalid.', { maxLength = maximum })
    end

    local duration = tonumber(request.duration) or 3000
    local maxDuration = PositiveLimit('maxDurationMs', 15000)
    if duration < 1 or duration > maxDuration or duration % 1 ~= 0 then
        return CoreResults.Err('invalid_input', 'Notification duration is invalid.', { maxDurationMs = maxDuration })
    end

    local normalized = { source = source, style = style, message = message, duration = duration }
    local stringFields = {
        title = PositiveLimit('maxTitleLength', 256),
        location = PositiveLimit('maxLocationLength', 256),
        dictionary = PositiveLimit('maxIdentifierLength', 128),
        icon = PositiveLimit('maxIdentifierLength', 128),
        color = PositiveLimit('maxIdentifierLength', 128),
        audioSource = PositiveLimit('maxIdentifierLength', 128),
        audioName = PositiveLimit('maxIdentifierLength', 128)
    }
    for field, limit in pairs(stringFields) do
        local invalid = ValidateOptionalString(request, normalized, field, limit)
        if invalid then return invalid end
    end

    if request.quality ~= nil then
        local minimumQuality = tonumber(Config.NotificationRegistry.minQuality) or -2147483648
        local maximumQuality = tonumber(Config.NotificationRegistry.maxQuality) or 2147483647
        if type(request.quality) ~= 'number' or request.quality % 1 ~= 0
            or request.quality < minimumQuality or request.quality > maximumQuality then
            return CoreResults.Err('invalid_input', 'Notification quality is invalid.', {
                field = 'quality',
                minimum = minimumQuality,
                maximum = maximumQuality
            })
        end
        normalized.quality = request.quality
    end

    if (style == 'top_banner' or style == 'advanced' or style == 'mission_failed' or style == 'warning')
        and (type(normalized.title) ~= 'string' or normalized.title == '') then
        return CoreResults.Err('invalid_input', 'This notification style requires a title.')
    end
    return CoreResults.Ok(normalized)
end

function CoreNotifications.RegisterProvider(name, implementation, options)
    options = type(options) == 'table' and Copy(options) or {}
    options.contract = tonumber(options.contract) or 1
    options.default = options.default ~= false
    return CoreProviders.Register('notification', name, implementation, options)
end

function CoreNotifications.Send(request, providerName)
    local validated = Validate(request)
    if not validated.ok then return validated end

    local rate = CheckRateLimit(validated.value.source)
    if not rate.ok then return rate end

    local provider = CoreProviders.Get('notification', providerName, 1)
    if not provider.ok then return provider end

    local capabilities = provider.value.provider.capabilities
    local providerStyles = type(capabilities) == 'table' and capabilities.styles or nil
    if type(providerStyles) ~= 'table' or providerStyles[validated.value.style] ~= true then
        return CoreResults.Err('provider_unavailable', 'The notification provider does not support that style.', {
            provider = provider.value.provider.name,
            style = validated.value.style
        })
    end
    local providerLimits = ValidateProviderLimits(provider.value.provider, validated.value)
    if not providerLimits.ok then return providerLimits end

    local implementation = provider.value.implementation
    if type(implementation) ~= 'table' or not IsCallable(implementation.Send) then
        return CoreResults.Err('provider_unavailable', 'The notification provider does not implement Send.')
    end

    local ok, result = pcall(implementation.Send, Copy(validated.value))
    if not ok then
        logger.Error('notification.provider_failed', {
            provider = provider.value.provider.name,
            source = validated.value.source,
            reason = tostring(result)
        })
        return CoreResults.Err('provider_unavailable', 'Notification delivery failed.')
    end

    if not CoreResults.Is(result) then
        return CoreResults.Err('provider_unavailable', 'Notification provider returned an invalid result.')
    end
    return result
end

exports('RegisterNotificationProvider', CoreNotifications.RegisterProvider)
exports('SendNotification', CoreNotifications.Send)

AddEventHandler('playerDropped', function()
    ResetRateLimit(tonumber(source))
end)

RegisterCommand('CoreNotificationSmokeTest', function(source, args)
    if source ~= 0 then return end

    local target = tonumber(args and args[1])
    if not target or GetPlayerName(target) == nil then
        print('[CoreNotificationSmokeTest] FAIL -- connected source required: CoreNotificationSmokeTest <source>')
        return
    end

    CoreProviders.Unregister('notification', 'core-notification-smoke')
    local received
    local registered = CoreNotifications.RegisterProvider('core-notification-smoke', {
        Send = function(request)
            received = request
            return CoreResults.Ok({ dispatched = true })
        end
    }, { contract = 1, default = false, capabilities = {
        styles = { right = true },
        limits = {
            maxMessageLength = 8,
            maxTitleLength = 256,
            maxLocationLength = 256,
            maxIdentifierLength = 128,
            maxDurationMs = 15000,
            minQuality = -2147483648,
            maxQuality = 2147483647
        }
    } })
    local dispatched = CoreNotifications.Send({
        source = target,
        style = 'right',
        message = 'smoke',
        duration = 1000
    }, 'core-notification-smoke')
    local invalid = CoreNotifications.Send({ source = target, style = 'unknown', message = 'smoke' },
        'core-notification-smoke')
    local unsupported = CoreNotifications.Send({ source = target, style = 'left', message = 'smoke' },
        'core-notification-smoke')
    local providerLimited = CoreNotifications.Send({
        source = target,
        style = 'right',
        message = 'too long!'
    }, 'core-notification-smoke')
    local invalidField = CoreNotifications.Send({
        source = target,
        style = 'right',
        message = 'smoke',
        dictionary = {}
    }, 'core-notification-smoke')
    local unknownField = CoreNotifications.Send({
        source = target,
        style = 'right',
        message = 'smoke',
        unexpected = true
    }, 'core-notification-smoke')
    local oversized = CoreNotifications.Send({
        source = target,
        style = 'right',
        message = string.rep('x', PositiveLimit('maxMessageLength', 512) + 1)
    }, 'core-notification-smoke')
    local excessiveDuration = CoreNotifications.Send({
        source = target,
        style = 'right',
        message = 'smoke',
        duration = PositiveLimit('maxDurationMs', 15000) + 1
    }, 'core-notification-smoke')
    local fractionalQuality = CoreNotifications.Send({
        source = target,
        style = 'right',
        message = 'smoke',
        quality = 1.5
    }, 'core-notification-smoke')
    local recursive = { source = target, style = 'right', message = 'smoke' }
    recursive.dictionary = recursive
    local recursiveField = CoreNotifications.Send(recursive, 'core-notification-smoke')
    local disconnected = CoreNotifications.Send({
        source = 2147483647,
        style = 'right',
        message = 'smoke'
    }, 'core-notification-smoke')
    ResetRateLimit(target)
    local _, maxRateCalls = RateLimitSettings()
    local rateAccepted = true
    for _ = 1, maxRateCalls do
        if not CheckRateLimit(target).ok then rateAccepted = false break end
    end
    local rateLimited = CheckRateLimit(target)
    ResetRateLimit(target)
    local removed = CoreProviders.Unregister('notification', 'core-notification-smoke')

    local tests = {
        { name = 'provider registered',    passed = registered.ok },
        { name = 'dispatch envelope',      passed = dispatched.ok and dispatched.value.dispatched == true },
        { name = 'request normalized',     passed = received and received.source == target and received.duration == 1000 },
        { name = 'invalid style rejected', passed = not invalid.ok and invalid.code == 'invalid_input' },
        { name = 'unsupported style',      passed = not unsupported.ok and unsupported.code == 'provider_unavailable' },
        { name = 'provider limit enforced',passed = not providerLimited.ok and providerLimited.code == 'provider_unavailable' },
        { name = 'invalid field rejected', passed = not invalidField.ok and invalidField.code == 'invalid_input' },
        { name = 'unknown field rejected', passed = not unknownField.ok and unknownField.code == 'invalid_input' },
        { name = 'oversized rejected',     passed = not oversized.ok and oversized.code == 'invalid_input' },
        { name = 'duration rejected',      passed = not excessiveDuration.ok and excessiveDuration.code == 'invalid_input' },
        { name = 'quality rejected',       passed = not fractionalQuality.ok and fractionalQuality.code == 'invalid_input' },
        { name = 'recursive rejected',     passed = not recursiveField.ok and recursiveField.code == 'invalid_input' },
        { name = 'disconnected rejected',  passed = not disconnected.ok and disconnected.code == 'invalid_input' },
        { name = 'rate limit accepted',    passed = rateAccepted },
        { name = 'rate limit enforced',    passed = not rateLimited.ok and rateLimited.code == 'rate_limited' },
        { name = 'provider removed',       passed = removed.ok }
    }
    local passed = 0
    for _, test in ipairs(tests) do
        if test.passed then passed = passed + 1 end
        print(('[CoreNotificationSmokeTest] %-24s %s'):format(test.name, test.passed and 'PASS' or 'FAIL'))
    end
    print(('[CoreNotificationSmokeTest] done %d/%d passed'):format(passed, #tests))
end, true)

RegisterCommand('CoreNotificationAvailabilityTest', function(source, args)
    if source ~= 0 then return end
    local target = tonumber(args and args[1])
    local expected = type(args and args[2]) == 'string' and args[2]:lower() or nil
    if not target or GetPlayerName(target) == nil or (expected ~= 'available' and expected ~= 'unavailable') then
        print('[CoreNotificationAvailabilityTest] FAIL -- usage: CoreNotificationAvailabilityTest <source> <available|unavailable>')
        return
    end

    ResetRateLimit(target)
    local result = CoreNotifications.Send({
        source = target,
        style = 'right',
        message = 'Feather notification provider is available.',
        duration = 1500
    })
    ResetRateLimit(target)

    local passed = expected == 'available' and result.ok == true
        or expected == 'unavailable' and result.ok == false and result.code == 'provider_unavailable'
    print(('[CoreNotificationAvailabilityTest] expected=%s result=%s code=%s %s'):format(
        expected,
        tostring(result.ok),
        tostring(result.code or 'none'),
        passed and 'PASS' or 'FAIL'))
end, true)

RegisterCommand('CoreNotificationRateRecoveryTest', function(source, args)
    if source ~= 0 then return end
    local target = tonumber(args and args[1])
    if not target or GetPlayerName(target) == nil then
        print('[CoreNotificationRateRecoveryTest] FAIL -- connected source required: CoreNotificationRateRecoveryTest <source>')
        return
    end

    CreateThread(function()
        ResetRateLimit(target)
        local windowMs, maxCalls = RateLimitSettings()
        local accepted = true
        for _ = 1, maxCalls do
            if not CheckRateLimit(target).ok then accepted = false break end
        end
        local limited = CheckRateLimit(target)
        Wait(windowMs + 50)
        local recovered = CheckRateLimit(target)
        ResetRateLimit(target)
        print(('[CoreNotificationRateRecoveryTest] accepted=%s limited=%s recovered=%s'):format(
            tostring(accepted),
            tostring(not limited.ok and limited.code == 'rate_limited'),
            tostring(recovered.ok == true)))
    end)
end, true)
