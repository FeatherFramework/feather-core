-- Cfx serializes functions crossing a resource boundary as callable tables.
-- Use rawget because their metatable intentionally rejects normal indexing.
function IsCallable(value)
    return type(value) == 'function'
        or (type(value) == 'table'
            and type(rawget(value, '__cfx_functionReference')) == 'string')
end

function StringChain(...)
    local args = { ... }
    local combined

    for _, value in ipairs(args) do
        if IsCallable(value) then
            combined = value(combined)
        else
            combined = value
        end
    end

    return combined
end

function IsOnServer()
    return IsDuplicityVersion()
end
