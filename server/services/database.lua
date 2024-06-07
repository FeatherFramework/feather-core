DatabaseAPI = {}

function DatabaseAPI.SafeQuery(query, queryParams, async, callback)
    if string.find(query, "'") or string.find(query, '"') then
        print("SQL Injection attempt detected: " .. query .. " query aborted.")
    else
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
end