CoreResults = {}

local function OptionalTable(value, fieldName)
    if value ~= nil and type(value) ~= 'table' then
        error(('%s must be a table when provided'):format(fieldName), 3)
    end
    return value
end

function CoreResults.Ok(value, meta)
    return {
        ok = true,
        value = value,
        meta = OptionalTable(meta, 'meta')
    }
end

function CoreResults.Err(code, message, details)
    if type(code) ~= 'string' or code == '' then
        error('code must be a non-empty string', 2)
    end

    if type(message) ~= 'string' or message == '' then
        error('message must be a non-empty string', 2)
    end

    return {
        ok = false,
        code = code,
        message = message,
        details = OptionalTable(details, 'details')
    }
end

function CoreResults.Is(value)
    if type(value) ~= 'table' or type(value.ok) ~= 'boolean' then
        return false
    end

    if value.ok then
        return value.code == nil and value.message == nil
    end

    return type(value.code) == 'string' and value.code ~= ''
        and type(value.message) == 'string' and value.message ~= ''
end

