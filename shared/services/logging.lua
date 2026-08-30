CoreLogging = {}

local levels = {
    debug = 10,
    info = 20,
    warn = 30,
    error = 40
}

local redactedKeys = {
    password = true,
    secret = true,
    token = true,
    webhook = true,
    authorization = true,
    credential = true,
    identifier = true,
    license = true,
    api_key = true,
    apikey = true
}

local function Redact(value, depth)
    if type(value) ~= 'table' then
        return value
    end

    if depth >= 6 then
        return '[depth-limit]'
    end

    local output = {}
    for key, child in pairs(value) do
        local normalized = type(key) == 'string' and key:lower() or ''
        local shouldRedact = false
        for sensitive in pairs(redactedKeys) do
            if normalized:find(sensitive, 1, true) then
                shouldRedact = true
                break
            end
        end
        output[key] = shouldRedact and '[redacted]' or Redact(child, depth + 1)
    end
    return output
end

local function Encode(fields)
    if fields == nil then
        return ''
    end

    local ok, encoded = pcall(json.encode, Redact(fields, 0))
    return ok and (' ' .. encoded) or ' {"loggingError":"fields could not be encoded"}'
end

function CoreLogging.Create(resourceName, subsystem)
    if type(resourceName) ~= 'string' or resourceName == '' then
        error('resourceName must be a non-empty string', 2)
    end

    local logger = {}
    local configuredLevel = Config and Config.Logging and Config.Logging.level or 'info'
    local threshold = levels[configuredLevel] or levels.info

    local function Write(level, eventName, fields)
        if levels[level] < threshold then
            return
        end

        local prefix = ('[%s] [%s]'):format(resourceName, level:upper())
        if subsystem then
            prefix = prefix .. (' [%s]'):format(subsystem)
        end
        print(('%s %s%s'):format(prefix, tostring(eventName), Encode(fields)))
    end

    function logger.Debug(eventName, fields) Write('debug', eventName, fields) end
    function logger.Info(eventName, fields) Write('info', eventName, fields) end
    function logger.Warn(eventName, fields) Write('warn', eventName, fields) end
    function logger.Error(eventName, fields) Write('error', eventName, fields) end

    return logger
end

