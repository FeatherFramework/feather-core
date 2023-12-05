local colors = {
    reset = "\027[0m",
    red = "\027[31m",
    green = "\027[32m",
    orange = "\027[33m",
    navy = "\027[34m",
    magenta = "\027[35m",
    purple = "\027[35m",
    cyan = "\027[36m",
    gray = "\027[90m",
    grey = "\027[90m",
    lightgray = "\027[37m",
    lightgrey = "\027[37m",
    peach = "\027[91m",
    lightgreen = "\027[92m",
    yellow = "\027[93m",
    blue = "\027[94m",
    pink = "\027[95m",
    babyblue = "\027[96m",

    highlight = {
        red = "\027[41m",
        green = "\027[42m",
        orange = "\027[43m",
        navy = "\027[44m",
        magenta = "\027[45m",
        cyan = "\027[46m",
        gray = "\027[47m",
        grey = "\027[47m",
        lightgray = "\027[100m",
        lightgrey = "\027[100m",
        peach = "\027[101m",
        lightgreen = "\027[102m",
        yellow = "\027[103m",
        blue = "\027[104m",
        pink = "\027[105m",
        babyblue = "\027[106m",
    },
    bold = "\027[1m",
    slim = "\027[2m"
}

local function SetColors(str)
    str = tostring(str or '')
    str = '%{reset}' .. str .. '%{reset}'
    str = string.gsub(str, "(%%{(.-)})", function(_, s) 
        local buffer = {}
        local index = 1
        for word in s:gmatch("%w+") do
            if index == 1 then
                buffer = colors[word]
            else
                buffer = buffer[word]
            end
            index = index + 1
            assert(buffer, "Unknown color key: " .. word) --IF output is not existent, throw an error
        end
    
        return buffer
    end)
    return str
end

local function TableToString(o)
    if type(o) == 'table' then
        local s = '{ '
        for k, v in pairs(o) do
            if type(k) ~= 'number' then k = '"' .. k .. '"' end
            s = s .. '[' .. k .. '] = ' .. TableToString(v) .. ','
        end
        return s .. '} '
    else
        return tostring(o)
    end
end

function PrettyPrint(...)
    local args = { ... }

    for i, v in ipairs(args) do
        if IsOnServer() then
            args[i] = StringChain(v, TableToString, SetColors)
        else
            args[i] = StringChain(v, TableToString)
        end
    end

    print(table.unpack(args));
end

function DebugLog(...)
    if Config.DevMode then
        PrettyPrint(...)
    end
end
