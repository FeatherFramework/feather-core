-- Cfx serializes functions crossing a resource boundary as callable tables.
-- Use rawget because their metatable intentionally rejects normal indexing.
function IsCallable(value)
    return type(value) == 'function'
        or (type(value) == 'table'
            and type(rawget(value, '__cfx_functionReference')) == 'string')
end

function StringChain(...)
    local args = { ... }

    local comb
    for i, v in ipairs(args) do
        if IsCallable(v) then
            comb = v(comb)
        else
            comb = v
        end
    end

    return comb
end

function IsOnServer()
    return IsDuplicityVersion()
end

function CheckVar(val, def)
    if val == nil then
        return def
    end

    return val
end
