DatabaseAPI = {}

-- (CORE-08) Despite the name, the actual injection protection here is
-- `queryParams` -- oxmysql binds those as parameters, which is what
-- actually makes this safe against injection. This used to also reject any
-- query containing a `'` or `"` character at all, which added no real
-- protection (a parameterized query is already safe regardless of what
-- quote characters appear in the literal SQL text) while breaking any
-- legitimate query written with quoted identifiers/literals. Removed.
function DatabaseAPI.SafeQuery(query, queryParams, async, callback)
    if async then
        local retval = MySQL.query.await(query, queryParams)
        if callback then
            callback(retval)
        end
    else
        exports.oxmysql:execute(query, queryParams, function(retval)
            if callback then
                callback(retval)
            end
        end)
    end
end