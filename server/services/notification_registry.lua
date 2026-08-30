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

    local source = tonumber(request.source)
    if not source or source < 1 or source % 1 ~= 0 then
        return CoreResults.Err('invalid_input', 'Notification source must be a positive player ID.')
    end

    local style = request.style or 'right'
    if not supportedStyles[style] then
        return CoreResults.Err('invalid_input', 'Notification style is unsupported.', { style = style })
    end

    local message = request.message
    local maximum = math.max(1, math.floor(tonumber(Config.NotificationRegistry.maxMessageLength) or 512))
    if type(message) ~= 'string' or message == '' or #message > maximum then
        return CoreResults.Err('invalid_input', 'Notification message is invalid.', { maxLength = maximum })
    end

    local duration = tonumber(request.duration) or 3000
    local maxDuration = math.max(1, math.floor(tonumber(Config.NotificationRegistry.maxDurationMs) or 15000))
    if duration < 1 or duration > maxDuration or duration % 1 ~= 0 then
        return CoreResults.Err('invalid_input', 'Notification duration is invalid.', { maxDurationMs = maxDuration })
    end

    local normalized = { source = source, style = style, message = message, duration = duration }
    for key in pairs(optionalFields) do
        if request[key] ~= nil then normalized[key] = Copy(request[key]) end
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

    local provider = CoreProviders.Get('notification', providerName, 1)
    if not provider.ok then return provider end

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

RegisterCommand('CoreNotificationSmokeTest', function(source)
    if source ~= 0 then return end

    CoreProviders.Unregister('notification', 'core-notification-smoke')
    local received
    local registered = CoreNotifications.RegisterProvider('core-notification-smoke', {
        Send = function(request)
            received = request
            return CoreResults.Ok({ delivered = true })
        end
    }, { contract = 1, default = false, capabilities = { styles = { right = true } } })
    local delivered = CoreNotifications.Send({
        source = 1,
        style = 'right',
        message = 'smoke',
        duration = 1000
    }, 'core-notification-smoke')
    local invalid = CoreNotifications.Send({ source = 1, style = 'unknown', message = 'smoke' },
        'core-notification-smoke')
    local removed = CoreProviders.Unregister('notification', 'core-notification-smoke')

    local tests = {
        { name = 'provider registered',    passed = registered.ok },
        { name = 'delivery envelope',      passed = delivered.ok and delivered.value.delivered == true },
        { name = 'request normalized',     passed = received and received.source == 1 and received.duration == 1000 },
        { name = 'invalid style rejected', passed = not invalid.ok and invalid.code == 'invalid_input' },
        { name = 'provider removed',       passed = removed.ok }
    }
    local passed = 0
    for _, test in ipairs(tests) do
        if test.passed then passed = passed + 1 end
        print(('[CoreNotificationSmokeTest] %-24s %s'):format(test.name, test.passed and 'PASS' or 'FAIL'))
    end
    print(('[CoreNotificationSmokeTest] done %d/%d passed'):format(passed, #tests))
end, true)
