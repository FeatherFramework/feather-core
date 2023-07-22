# Feather Core
> This is the Core system for the Feather Framework. An open source RedM framework for creating the RedM server of your dreams.

## Features
- Interiors Fixes
- Population density control
- Easy Developer API's
    - Discord Webhook API
    - User Management
    - Character Management
    - Remote Procedure Callbacks (RPC)
    - PrettyPrint
    - Dataview
    - Game Events

## API Documentation and usage
tbd

### Discord Webhooks

This API allows you to easily add [Discord webhooks](https://support.discord.com/hc/en-us/articles/228383668-Intro-to-Webhooks) messages to your scripts.

#### Send One Time Message

```lua

-- (webhookurl, webhookname, webhookavatar, name, description, embeds)
feather.Discord.sendMessage('webhookurl', 'My Script', 'https://cdn2.iconfinder.com/data/icons/frosted-glass/256/Danger.png', 'user123', 'this user is awesome')
```

#### Create Discord Re-usable instance

```lua
-- (webhookurl, webhookname, webhookavatar)
local discord = feather.Discord.setup('webhookurl', 'My Script', 'https://cdn2.iconfinder.com/data/icons/frosted-glass/256/Danger.png')

-- (name, description, embeds)
discord:sendMessage('user123', 'this user is awesome')

discord:sendMessage('user456', 'this user is ALSO awesome')

discord:sendMessage('user789', 'this user kinda really awesome', {
    {
        color = 11342935,
        title = 'Embed Item 1',
        description = 'Items awesome description?'
    },
    {
        color = 11342935,
        title = 'Embed Item 2',
        description = 'Item 2 awesome description!'
    },
})

```

### Population Density
tbd

### PrettyPrint
This is a `print` replacement which adds 
- table to string by default
- more ANSI colors (highlights, colors, etc)

```lua
Citizen.CreateThread(function()
    feather.Print('%{bold} %{red}HELLO', {
        hello = "world"
    })
end)
```

#### Print Colors
| Type | format | Description |
|--|--|--|
| Text Format | %{bold} | Make Text Font weight heavier |
| Text Color | %{reset} | Set back to default color |
| Text Color | %{red} |  |
| Text Color | %{green} |  |
| Text Color | %{orange} |  |
| Text Color | %{navy} |  |
| Text Color | %{magenta} or %{purple} |  |
| Text Color | %{cyan} |  |
| Text Color | %{gray} or %{grey}|  |
| Text Color | %{lightgray} or %{lightgrey} |  |
| Text Color | %{peach} |  |
| Text Color | %{lightgreen} |  |
| Text Color | %{yellow} |  |
| Text Color | %{blue} |  |
| Text Color | %{pink} |  |
| Text Color | %{babyblue} |  |
| Background Color | %{highlight red} |  |
| Background Color | %{highlight green} |  |
| Background Color | %{highlight orange} |  |
| Background Color | %{highlight navy} |  |
| Background Color | %{highlight magenta} |  |
| Background Color | %{highlight cyan} |  |
| Background Color | %{highlight gray} or %{highlight grey} |  |
| Background Color | %{highlight lightgray} or %{highlight lightgrey} |  |
| Background Color | %{highlight peach} |  |
| Background Color | %{highlight lightgreen} |  |
| Background Color | %{highlight yellow} |  |
| Background Color | %{highlight blue} |  |
| Background Color | %{highlight pink} |  |
| Background Color | %{highlight babyblue} |  |

### Event Listener

#### Register Event Listener

* `eventname<string>` - game event name
* `callback<function>` - method function

```lua
Citizen.CreateThread(function()
    feather.Events:RegisterEventListener('EVENT_PICKUP_CARRIABLE', function(args)
        print("EVENT TRIGGERED: EVENT_PICKUP_CARRIABLE", args[1], args[2])
    end)
end)
```

#### Remove Event Listener

* `eventlistener<listner>` - registered event listener

```lua
Citizen.CreateThread(function()
    local listener = feather.Events:RegisterEventListener('EVENT_PICKUP_CARRIABLE', function(args)
        print("EVENT TRIGGERED: EVENT_PICKUP_CARRIABLE", args[1], args[2])
    end)


    Wait(40000)

    feather.Events:RemoveEventListener(listener)
end)
```

### Dataview
A DataView utility

Example Usage:

```lua
local view = DataView.ArrayBuffer(512)
if Citizen.InvokeNative(0x79923CD21BECE14E, 1, view:Buffer(), Citizen.ReturnResultAnyway()) then
    local dlc = {
        validCheck = view:GetInt64(0),
        weaponHash = view:GetInt32(8),
        val3 = view:GetInt64(16),
        weaponCost = view:GetInt64(24),
        ammoCost = view:GetInt64(32),
        ammoType = view:GetInt64(40),
        defaultClipSize = view:GetInt64(48),
        nameLabel = view:GetFixedString(56, 64),
        descLabel = view:GetFixedString(120, 64),
        simpleDesc = view:GetFixedString(184, 64),
        upperCaseName = view:GetFixedString(248, 64),
    }
end
```

### Remote Procedure Callback - RPC
An RPC allows developers to easily communicate between the client and server without interrupting the runtime queue. 

Learn more here: https://en.wikipedia.org/wiki/Remote_procedure_call

#### Register your remote prodecure 

> feather.RPC.Register(name, callback)

* `name<string>` - remote method name
* `callback<function>` - method function (see method callback)

```lua
feather.RPC.Register("doSomething", myProcedure)

-- `params<table>` - params passed to method by remote caller
-- `res<function>` - function for returning values to the rpc call asynchronously
-- `player<player>` - player who called this method (only for server-side)
function myProcedure(params, res, player)
    return res("Hello "..tostring(params.text)..", "..GetPlayerName(player))

    -- The return is asynchronous, example:
    -- Citizen.SetTimeout(1000, function ()
    --    res("Hello from server (but delayed)")
    --end)
    -- WARNING: If you return anything from method callback, `ret` will be ignored and return value will be passed to caller
end
```

#### Call RPC with inline callback.
Calls remote method.

> feather.RPC.Call(name, params, callback [, player])

* `name<string>` - method name
* `params<table>` - params passed to method
* `callback<function>` - callback called when results are received
* `player<player>` - optional player source to call method on (only for server-side)

```lua
feather.RPC.Call("doSomethingRemote", { text = "World", delay = 1000 }, function (result)
    print("[Example] Callback result: "..tostring(result))
end)
```

#### Call RPC with async.

Calls remote method asynchronously. Can only be used inside `Citizen.CreateThread`.

> feather.RPC.CallAsync(name, params [, player])
* `name<string>` - method name
* `params<table>` - params passed to method
* `player<player>` - optional player source to call method on (only for server-side)
* returns `result<any>` - any data returned by remote method

```lua
Citizen.CreateThread(function ()
    -- Some params passed to server-side method
    local result = feather.RPC.CallAsync("doSomethingRemote", {
        text = "World",
        delay = 2000
    })
    print("[Example] Async result: "..tostring(result))
end)
```

#### Notify Remote Procedure
Calls remote method without receiving return values.

> feather.RPC.Notify(name, params [, player])

* `name<string>` - method name
* `params<table>` - params passed to method
* `player<player>` - optional player source to call method on (only for server-side)

```lua
feather.RPC.Notify("doSomethingRemote", { text = "World", delay = 1000 }, function (result)
    print("[Example] Callback result: "..tostring(result))
end)
```