DiscordWebHookAPI = {}
local webhookQueue = {}
local processingWebhook = false
local maxWebhookQueue = 500

local function retryDelay(status, text, headers)
    if status ~= 429 then return 2000 end
    local ok, body = pcall(json.decode, text or '')
    if ok and type(body) == 'table' and tonumber(body.retry_after) then
        return math.max(1000, math.floor(tonumber(body.retry_after) * 1000))
    end
    local header = headers and (headers['retry-after'] or headers['Retry-After'])
    return math.max(1000, math.floor((tonumber(header) or 1) * 1000))
end

local function processWebhookQueue()
    if processingWebhook or #webhookQueue == 0 then return end
    processingWebhook = true
    local item = webhookQueue[1]

    PerformHttpRequest(item.url, function(status, text, headers)
        status = tonumber(status) or 0
        if status >= 200 and status < 300 then
            table.remove(webhookQueue, 1)
            processingWebhook = false
            processWebhookQueue()
            return
        end

        item.attempts = item.attempts + 1
        if item.attempts >= 5 or (status ~= 429 and status < 500) then
            print(('[feather-core] Webhook delivery failed: status=%s attempts=%s'):format(status, item.attempts))
            table.remove(webhookQueue, 1)
            processingWebhook = false
            processWebhookQueue()
            return
        end

        local delay = retryDelay(status, text, headers)
        processingWebhook = false
        SetTimeout(delay, processWebhookQueue)
    end, 'POST', item.payload, { ['Content-Type'] = 'application/json' })
end

local _internalSendMessage = function (webhookurl, webhookname, webhookavatar, name, description, embeds)
    if embeds == nil then
        embeds = {{
            color = 11342935,
            title = name,
            description = description
        }}
    end

    local payload = {
        username = webhookname,
        avatar_url = webhookavatar,
        type = 'rich',
        embeds = embeds
    }

    if #webhookQueue >= maxWebhookQueue then
        print('[feather-core] Webhook queue is full; message dropped.')
        return false
    end

    webhookQueue[#webhookQueue + 1] = {
        url = webhookurl,
        payload = json.encode(payload),
        attempts = 0
    }
    processWebhookQueue()
    return true
end

-- Straight forward call
DiscordWebHookAPI.sendMessage = _internalSendMessage


-- Object/Class based call, allows for an "instance" that you can continue to sendmessages with.
DiscordWebHookAPI.setup = function (webhookurl, webhookname, webhookavatar)
    local discord_data = {}

    discord_data.webhookname = webhookname
    discord_data.webhookavatar = webhookavatar
    discord_data.webhookurl = webhookurl

    function discord_data:sendMessage(name, description, embeds)
        _internalSendMessage(self.webhookurl, self.webhookname, self.webhookavatar, name, description, embeds)
    end

    return discord_data
end
