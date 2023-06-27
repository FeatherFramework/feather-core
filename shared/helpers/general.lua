function StringChain(...)
    local args = { ... }

    local comb
    for i, v in ipairs(args) do
        if type(v) == 'function' then
            comb = v(comb)
        else
            comb = v
        end
    end

    return comb
end