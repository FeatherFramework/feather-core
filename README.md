# **THIS IS A WORK IN PROGRESS AND NOT READY FOR PRODUCTION USE YET!**

# Feather Core

> Welcome to Feather Core, the beating heart of the Feather Framework; An extraordinary open-source RedM framework designed to bring the ultimate RedM server vision to life.

# TODO
- Job API/Docs
- death/respawn timer
- death/respawn locations
- Make the UI configurable
- Copy to clipboard API

## First time setup

Run our easy-to-use [txadmin recipe](https://github.com/FeatherFramework/feather-recipe)!

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
  - Prompts
  - Pedestrians
  - Objects
  - Notifications
  - Text Rendering
  - Blips
  - Files
- Global per player locale
- Death handling
- Position Syncing

## API Documentation and usage

### Core API Setup

```lua
feather =  exports['feather-core'].initiate()
```

### Character

#### Create

```lua
feather.Character.CreateCharacter(userid, firstname, lastname, dob, dollars, gold, xp, x, y, z)
```

#### Initiate(spawn)

```lua
feather.Character.InitiateCharacter(src, charid)
```

#### Get All Available

```lua
feather.Character.GetAvailableCharactersFromDB(src)
```

#### Get Character by src

```lua
feather.Character.GetCharacterBySrc(src)
```

#### Get Character by ID

```lua
feather.Character.GetCharacterByID(ID)
```

#### Remove Character (despawn)

```lua
feather.Character.RemoveCharacter(src)
```

#### Update Character Field

```lua
feather.Character.UpdateAttribute(src, key, val)
```

### User

#### Get User by src

```lua
feather.Character.GetUserBySrc(src)
```

#### Get User by ID

```lua
feather.Character.GetUserByID(ID)
```

### Blips

You can leverage Feathers built in function for map blips.

#### Create a Blip

<Badge type="warning" text="Client Side Only" />

Create a marker (blip) on the players map

| Parameter | Description                                                                                                                                                                        |
| --------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| text      | What the blip will display on the map                                                                                                                                              |
| bliphash  | The hashname of the blip ([found here](https://github.com/femga/rdr3_discoveries/blob/a4b4bcd5a3006b0c1434b03e4095d038164932f7/useful_info_from_rpfs/textures/blips_mp/README.md)) |
| scale     | How big the blip is                                                                                                                                                                |
| x         | The x coordinate in the game world                                                                                                                                                 |
| y         | The y coordinate in the game world                                                                                                                                                 |
| z         | The z coordinate in the game world                                                                                                                                                 |
| vector3   | instead of params send whole vector3 just add nil to x y z                                                                                                                         |

Example Usage:

```lua
-- client side only

Citizen.CreateThread(function()

    local  blip = feather.Blip:SetBlip('Gift', 'blip_special_series_1', 0.2, x, y, z, vector3 or nil)
end)
```

#### Get Raw Blip

<Badge type="warning" text="Client Side Only" />

If you want to use any natives that are not yet included, you can utilize the raw blip.

```lua
-- client side only
Citizen.CreateThread(function()
    local  blip = feather.Blip:SetBlip('Gift', 'blip_special_series_1', 0.2, x, y, z,vector3 or nil)

    local rawblip = blip.rawblip
    -- OR
    -- local rawblip = blip:Get()

    -- use rawblip with any other native.
end)
```

#### Delete a Blip

<Badge type="warning" text="Client Side Only" />

Delete a marker (blip) on the players map

```lua
-- client side only
Citizen.CreateThread(function()
    local  blip = feather.Blip:SetBlip('Gift', 'blip_special_series_1', 0.2, x, y, z,vecotr3 or nil)

    blip:Remove()
    -- OR
    --- feather.Blip:RemoveBlip(blip.rawblip)
end)
```

#### Add Radius to Blip

<Badge type="warning" text="Client Side Only" />

Create a Radius blip

| Parameter    | Description                                                                                                                                                                                                                |
| ------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| radius       | A decimal radius                                                                                                                                                                                                           |
| bliphahashsh | The hashname of the blip ([found here](https://github.com/femga/rdr3_discoveries/blob/a4b4bcd5a3006b0c1434b03e4095d038164932f7/useful_info_from_rpfs/textures/blips_mp/README.md)) [Optional, will default to -1282792512] |

Example Usage:

```lua
-- client side only

Citizen.CreateThread(function()
    local  blip = feather.Blip:SetBlip('Gift', 'blip_special_series_1', 0.2, x, y, z,vector3 or nil)

    blip:AddRadius(64.0, -1282792512)
    -- OR
    -- feather.Blip:AddRadius(64.0, x, y, z, -1282792512)
end)
```

### Prompts

You can leverage Feathers built in function for easy in-game prompts.

#### Setup a Prompt Group

<Badge type="warning" text="Client Side Only" />

This sets up the Prompt Group, which will allow you to attach future prompts to this group so that they can be displayed. Optionally you can set the groupId yourself. This is useful for when creating a prompt when targeting an entity. This is required.

**Example Usage:**

```lua

-- client side only
Citizen.CreateThread(function()
	local  PromptGroup = feather.Prompt:SetupPromptGroup() --Setup Prompt Group

    -- Optional: Setting the Prompt Group for entities. (Used for prompts when targeting)
    local promptGroupId = Citizen.InvokeNative(0xB796970BD125FCE8, targetEntity) -- PromptGetGroupIdForTargetEntity
    local  PromptGroup = feather.Prompt:SetupPromptGroup(promptGroupId)
end)
```

#### Register Prompt

<Badge type="warning" text="Client Side Only" />

Once you have the Prompt Group setup, you can now register a prompt to display within the group.

| Parameter | Description                                                          |
| --------- | -------------------------------------------------------------------- |
| title     | What the Prompt group will display next to the press button          |
| button    | The hash key                                                         |
| enabled   | If 0 you cannot click, if 1 you can click                            |
| visible   | If 0 you cannot see the prompt, if 1 you can see the group           |
| pulsing   | If true prompt will urgently pulse, if false it will not             |
| mode      | What kind of prompt. (Options: click, hold, customhold, mash, timed) |
| options   | Extra Options for the Mode you select. (See Mode Options below)      |

**Modes Options**
| Mode | Key | Options | example|
|--|--|--|--|
| click | None | None | None |
| hold | timedeventhash | SHORT_TIMED_EVENT_MP, SHORT_TIMED_EVENT, MEDIUM_TIMED_EVENT, LONG_TIMED_EVENT, RUSTLING_CALM_TIMING, PLAYER_FOCUS_TIMING, PLAYER_REACTION_TIMING | { timedeventhash = "SHORT_TIMED_EVENT" } |
| customhold | holdtime | Miliseconds | { holdtime = 3000 }|
| mash | mashamount | > 0 | { mashamount = 20 }|
| timed | depletiontime | Miliseconds | { depletiontime = 10000}|

`PromptGroup:RegisterPrompt(title, button, enabled, visible, pulsing, mode, options)`

Example Usage:

```lua

-- client side only

Citizen.CreateThread(function()
	local PromptGroup = feather.Prompt:SetupPromptGroup() --Setup Prompt Group

	local firstprompt = PromptGroup:RegisterPrompt("Press Me", 0x4CC0E2FE, 1, 1, true, 'hold', {timedeventhash = "MEDIUM_TIMED_EVENT"}) --Register your first prompt

    while  true  do
        Citizen.Wait(0)
    end
end)
```

#### Display Prompt Group

<Badge type="warning" text="Client Side Only" />

Now that you have a Group setup and a registered Prompt, you can now display the group!

| Parameter | Description                           |
| --------- | ------------------------------------- |
| text      | Text to display under all the prompts |

`PromptGroup:ShowGroup(text)`

Example Usage:

```lua

-- client side only

Citizen.CreateThread(function()
	local PromptGroup = feather.Prompt:SetupPromptGroup() --Setup Prompt Group

	local firstprompt = PromptGroup:RegisterPrompt("Press Me", 0x4CC0E2FE, 1, 1, true, 'hold', {timedeventhash = "MEDIUM_TIMED_EVENT"}) --Register your first prompt

    while  true  do
        Citizen.Wait(0)
		PromptGroup:ShowGroup("My first prompt group") --Show your prompt group
    end
end)
```

#### Handle Prompt Completion Events

<Badge type="warning" text="Client Side Only" />

You can trigger code when a prompt has a completion event triggered (Example: clicked, held, etc)

| Parameter      | Description                                                                                                                      |
| -------------- | -------------------------------------------------------------------------------------------------------------------------------- |
| hideoncomplete | Some Options may hide or disapear when completed, Set this to false to not hide. This will default to true if nothing is entered |

`firstprompt:HasCompleted()`

Example Usage:

```lua

-- client side only

Citizen.CreateThread(function()
	local  PromptGroup = feather.Prompt:SetupPromptGroup() --Setup Prompt Group

	local firstprompt = PromptGroup:RegisterPrompt("Press Me", 0x4CC0E2FE, 1, 1, true, 'hold', {timedeventhash = "MEDIUM_TIMED_EVENT"}) --Register your first prompt

    while  true  do
        Citizen.Wait(0)

        --Show your prompt group
		PromptGroup:ShowGroup("My first prompt group")

		-- Lets listed for the prompt click and enact some code!
        if firstprompt:HasCompleted() then
            print("First Prompt Completed!")
        end
    end
end)
```

#### Handle Prompt Failure Events

<Badge type="warning" text="Client Side Only" />

You can trigger code when a prompt has a failure event triggered (Example: timed, mashed)

| Parameter      | Description                                                                                                                      |
| -------------- | -------------------------------------------------------------------------------------------------------------------------------- |
| hideoncomplete | Some Options may hide or disapear when completed, Set this to false to not hide. This will default to true if nothing is entered |

`firstprompt:HasFailed()`

Example Usage:

```lua

-- client side only

Citizen.CreateThread(function()
	local  PromptGroup = feather.Prompt:SetupPromptGroup() --Setup Prompt Group

	local firstprompt = PromptGroup:RegisterPrompt("Press Me", 0x4CC0E2FE, 1, 1, true, 'hold', {timedeventhash = "MEDIUM_TIMED_EVENT"}) --Register your first prompt

    while  true  do
        Citizen.Wait(0)

        --Show your prompt group
		PromptGroup:ShowGroup("My first prompt group")

		-- Lets listed for the prompt click and enact some code!
        if firstprompt:HasCompleted() then
            print("First Prompt Completed!")
        end

        if firstprompt:HasFailed() then
            print("First Prompt Failed!")
        end
    end
end)
```

#### Delete Prompt

<Badge type="warning" text="Client Side Only" />

Remove a prompt completely

`firstprompt:DeletePrompt()`

Example Usage:

```lua

-- client side only

Citizen.CreateThread(function()
	local  PromptGroup = feather.Prompt:SetupPromptGroup() --Setup Prompt Group

	local firstprompt = PromptGroup:RegisterPrompt("Press Me", 0x4CC0E2FE, 1, 1, true, 'hold', {timedeventhash = "MEDIUM_TIMED_EVENT"}) --Register your first prompt

    while  true  do
        Citizen.Wait(0)

        --Show your prompt group
		PromptGroup:ShowGroup("My first prompt group")

		Wait(3000)

        firstprompt:DeletePrompt()
    end
end)
```

#### Toggle Prompt Visibility

<Badge type="warning" text="Client Side Only" />

Make a prompt visible or hidden

| Parameter | Description                                   |
| --------- | --------------------------------------------- |
| toggle    | true or false; true = visible, false = hidden |

`firstprompt:TogglePrompt(toggle)`

Example Usage:

```lua

-- client side only

Citizen.CreateThread(function()
	local  PromptGroup = feather.Prompt:SetupPromptGroup() --Setup Prompt Group

	local firstprompt = PromptGroup:RegisterPrompt("Press Me", 0x4CC0E2FE, 1, 1, true, 'hold', {timedeventhash = "MEDIUM_TIMED_EVENT"}) --Register your first prompt

    while  true  do
        Citizen.Wait(0)

        --Show your prompt group
		PromptGroup:ShowGroup("My first prompt group")

		Wait(3000)

        firstprompt:TogglePrompt(false)
    end
end)
```

### Pedestrians (Peds)

You can leverage Feathers built in function for easy spawn and manipulate in-game pedestrian entities.

#### Create Ped

<Badge type="warning" text="Client Side Only" />

This will spawn a pedestrian in your game world

| Parameter  | Description                                                                                                                                                |
| ---------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| modelhash  | The [hash](https://github.com/femga/rdr3_discoveries/blob/f729ba03f75a591ce5c841642dc873345242f612/peds/peds_list.lua) of the model you want the ped to be |
| x          | x world position coordinate                                                                                                                                |
| y          | y world position coordinate                                                                                                                                |
| z          | z world position coordinate                                                                                                                                |
| heading    | The heading of the ped (Which way it is facing)                                                                                                            |
| location   | Where to spawn ped. (world, vehicle, mount)                                                                                                                |
| safeground | Should the ped spawn in a known ok location (default true, disable for more dine accuracy of ped placement)                                                |
| options    | Extra Options for the Location you select. (See Mode Options below)                                                                                        |

**Modes Options**
| Location | Key | Options | example|
|--|--|--|--|
| world | None | None | None |
| vehicle | vehicle | vehicle entity | { vehicle = yourvehicle } |
| vehicle | seat | VS_ANY_PASSENGER, VS_DRIVER, VS_FRONT_RIGHT, VS_BACK_LEFT, VS_BACK_RIGHT, VS_EXTRA_LEFT_1, VS_EXTRA_RIGHT_1, VS_EXTRA_LEFT_2, VS_EXTRA_RIGHT_2, VS_EXTRA_LEFT_3, VS_EXTRA_RIGHT_3, VS_NUM_SEATS | { seat = "VS_FRONT_RIGHT" } |
| mount | mount | mount entity | { mount = yourmount } |

`featherPeds:Create()`

Example Usage:

```lua

-- client side only

Citizen.CreateThread(function()
    local coords = {
        z = 118.38395690917968, y = 802.531982421875, x = -279.46728515625
    }

    local ped = feather.Ped:Create('u_f_m_tumgeneralstoreowner_01', coords.x, coords.y, coords.z, 0, 'world', false, isnetwork or false)
end)
```

#### Freeze Ped

<Badge type="warning" text="Client Side Only" />

Freeze a ped where they stand

| Parameter | Description                                   |
| --------- | --------------------------------------------- |
| state     | freeze or unfreeze (true/false), default true |

`ped:Freeze()`

Example Usage:

```lua

-- client side only

Citizen.CreateThread(function()
    local coords = {
        z = 118.38395690917968, y = 802.531982421875, x = -279.46728515625
    }

    local ped = feather.Ped:Create('u_f_m_tumgeneralstoreowner_01', coords.x, coords.y, coords.z, 0, 'world', false)

    ped:Freeze()
end)
```

#### Invincible Ped

<Badge type="warning" text="Client Side Only" />

Make a ped Invincible

| Parameter | Description                           |
| --------- | ------------------------------------- |
| state     | Invincible (true/false), default true |

`ped:Invincible()`

Example Usage:

```lua

-- client side only

Citizen.CreateThread(function()
    local coords = {
        z = 118.38395690917968, y = 802.531982421875, x = -279.46728515625
    }

    local ped = feather.Ped:Create('u_f_m_tumgeneralstoreowner_01', coords.x, coords.y, coords.z, 0, 'world', false)

    ped:Invincible()
end)
```

#### Ped CanBeDamaged

<Badge type="warning" text="Client Side Only" />

Make a ped not take damage

| Parameter | Description                             |
| --------- | --------------------------------------- |
| state     | CanBeDamaged (true/false), default true |

`ped:CanBeDamaged()`

Example Usage:

```lua

-- client side only

Citizen.CreateThread(function()
    local coords = {
        z = 118.38395690917968, y = 802.531982421875, x = -279.46728515625
    }

    local ped = feather.Ped:Create('u_f_m_tumgeneralstoreowner_01', coords.x, coords.y, coords.z, 0, 'world', false)

    ped:CanBeDamaged()
end)
```

#### Set Ped Heading

<Badge type="warning" text="Client Side Only" />

change the directon a ped is facing

| Parameter | Description                      |
| --------- | -------------------------------- |
| head      | the game world direction to face |

`ped:SetHeading()`

Example Usage:

```lua

-- client side only

Citizen.CreateThread(function()
    local coords = {
        z = 118.38395690917968, y = 802.531982421875, x = -279.46728515625
    }

    local ped = feather.Ped:Create('u_f_m_tumgeneralstoreowner_01', coords.x, coords.y, coords.z, 0, 'world', false)

    ped:SetHeading(0)
end)
```

#### Set Ped Seeing Range

<Badge type="warning" text="Client Side Only" />

Change how far the ped can see

| Parameter | Description |
| --------- | ----------- |
| range     | 0.0 - 100.0 |

`ped:SeeingRange()`

Example Usage:

```lua

-- client side only

Citizen.CreateThread(function()
    local coords = {
        z = 118.38395690917968, y = 802.531982421875, x = -279.46728515625
    }

    local ped = feather.Ped:Create('u_f_m_tumgeneralstoreowner_01', coords.x, coords.y, coords.z, 0, 'world', false)

    ped:SeeingRange(70.0)
end)
```

#### Set Ped Hearing Range

<Badge type="warning" text="Client Side Only" />

Change how far the ped can hear

| Parameter | Description |
| --------- | ----------- |
| range     | 0.0 - 100.0 |

`ped:HearingRange()`

Example Usage:

```lua

-- client side only

Citizen.CreateThread(function()
    local coords = {
        z = 118.38395690917968, y = 802.531982421875, x = -279.46728515625
    }

    local ped = feather.Ped:Create('u_f_m_tumgeneralstoreowner_01', coords.x, coords.y, coords.z, 0, 'world', false)

    ped:HearingRange(80.0)
end)
```

#### Set Ped Can Mount

<Badge type="warning" text="Client Side Only" />

Change if a ped can mount something.

| Parameter | Description |
| --------- | ----------- |
| state     | true/false  |

`ped:CanBeMounted(true)`

Example Usage:

```lua

-- client side only

Citizen.CreateThread(function()
    local coords = {
        z = 118.38395690917968, y = 802.531982421875, x = -279.46728515625
    }

    local ped = feather.Ped:Create('u_f_m_tumgeneralstoreowner_01', coords.x, coords.y, coords.z, 0, 'world', false)

    ped:CanBeMounted(true)
end)
```

#### Add Ped to Group

<Badge type="warning" text="Client Side Only" />

Add ped to a group

| Parameter | Description                  |
| --------- | ---------------------------- |
| group     | index of the group to add to |

`ped:AddPedToGroup(group)`

Example Usage:

```lua

-- client side only

Citizen.CreateThread(function()
    local coords = {
        z = 118.38395690917968, y = 802.531982421875, x = -279.46728515625
    }

    local ped = feather.Ped:Create('s_m_m_valdeputy_01', coords.x, coords.y, coords.z, 0, 'world', false)

    ped:AddPedToGroup(GetPedGroupIndex(PlayerPedId()))

end)
```

#### Clear a ped task

<Badge type="warning" text="Client Side Only" />

Clear any active tasks

`ped:ClearTasks()`

Example Usage:

```lua

-- client side only

Citizen.CreateThread(function()
    local coords = {
        z = 118.38395690917968, y = 802.531982421875, x = -279.46728515625
    }

    local ped = feather.Ped:Create('s_m_m_valdeputy_01', coords.x, coords.y, coords.z, 0, 'world', false)

    ped:ClearTasks()

end)
```

#### Get Task Status

<Badge type="warning" text="Client Side Only" />

Check the status of a ped task

`ped:GetTaskStatus(taskid)`

Example Usage:

```lua

-- client side only

Citizen.CreateThread(function()
    local coords = {
        z = 118.38395690917968, y = 802.531982421875, x = -279.46728515625
    }

    local ped = feather.Ped:Create('s_m_m_valdeputy_01', coords.x, coords.y, coords.z, 0, 'world', false)

    while (ped:GetTaskStatus(0x4924437d) ~= 8) do
        Wait(1000)
    end

    print("Ped task done!")

end)
```

#### Follow to offset

<Badge type="warning" text="Client Side Only" />

Add ped to a group

| Parameter | Description         |
| --------- | ------------------- |
| pedid     | id of ped to follow |

`ped:FollowToOffsetOfEntity(pedid)`

Example Usage:

```lua

-- client side only

Citizen.CreateThread(function()
    local coords = {
        z = 118.38395690917968, y = 802.531982421875, x = -279.46728515625
    }

    local ped = feather.Ped:Create('s_m_m_valdeputy_01', coords.x, coords.y, coords.z, 0, 'world', false)

    ped:FollowToOffsetOfEntity(PlayerPedId(), 0.0, -1.5, 0.0, 1.0, -1, 10, 1, 1)

end)
```

#### Follow to offset

<Badge type="warning" text="Client Side Only" />

Add ped to a group

| Parameter | Description             |
| --------- | ----------------------- |
| skinhash  | hash of skin meta cloth |

`ped:ChangeOutfit(skinhash)`

Example Usage:

```lua

-- client side only

Citizen.CreateThread(function()
    local coords = {
        z = 118.38395690917968, y = 802.531982421875, x = -279.46728515625
    }

    local ped = feather.Ped:Create('A_C_DogBluetickCoonhound_01', coords.x, coords.y, coords.z, 0, 'world', false)

    ped:ChangeOutfit(0xDC567AF8)

end)
```

#### Set Ped Blip

<Badge type="warning" text="Client Side Only" />

Set a blip on ped that follows

| Parameter | Description                                                                                                                                                                       |
| --------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| bliphash  | What the [blip](https://github.com/femga/rdr3_discoveries/blob/a4b4bcd5a3006b0c1434b03e4095d038164932f7/useful_info_from_rpfs/textures/blips_mp/README.md) should show on the map |
| title     | What the blip should say                                                                                                                                                          |

`ped:SetBlip(bliphash, title)`

Example Usage:

```lua

-- client side only

Citizen.CreateThread(function()
    local coords = {
        z = 118.38395690917968, y = 802.531982421875, x = -279.46728515625
    }

    local ped = feather.Ped:Create('s_m_m_valdeputy_01', coords.x, coords.y, coords.z, 0, 'world', false)

    ped:SetBlip(953018525, 'Person')
end)
```

#### Give Ped Weapon

<Badge type="warning" text="Client Side Only" />

Give a ped a weapon (they will only use it if they are set to be agro)

| Parameter            | Description                                                                                                                            |
| -------------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| weaponhash           | What the [weapon](https://github.com/femga/rdr3_discoveries/blob/f729ba03f75a591ce5c841642dc873345242f612/weapons/weapons.lua) will be |
| ammocount            | how much ammo                                                                                                                          |
| forceinhand          | Force the weapon to be held                                                                                                            |
| forceinholster       | Force the weapon to be holstered                                                                                                       |
| attachpoint          | Where to attach to the body                                                                                                            |
| allowmultiplecopies  | How many of this gun can the ped have                                                                                                  |
| ignoreunlocks        | Ingore unlockables                                                                                                                     |
| permanentdegredation | permanent degredation                                                                                                                  |

`ped:GiveWeapon(weaponhash, ammocount, forceinhand, forceinholster, attachpoint, allowmultiplecopies, ignoreunlocks, permanentdegredation)`

Example Usage:

```lua
-- client side only

Citizen.CreateThread(function()
    local coords = {
        z = 118.38395690917968, y = 802.531982421875, x = -279.46728515625
    }

    local ped = feather.Ped:Create('s_m_m_valdeputy_01', coords.x, coords.y, coords.z, 0, 'world', false)
    ped:AttackTarget(PlayerPedId())

    ped:GiveWeapon(0x64356159, 500, true, true, 3, false, true, true)
end)
```

#### Set Ped Flee Attribute

<Badge type="warning" text="Client Side Only" />

Enable or disable pedestrian flee attributes

| Parameter | Description                                                                                                       |
| --------- | ----------------------------------------------------------------------------------------------------------------- |
| flag      | What [flee attribute](https://github.com/femga/rdr3_discoveries/tree/master/AI/FLEE_ATTRIBUTES) to enable/disable |
| enabled   | is active of not (true/false)                                                                                     |

`ped:FleeAtribute(flag, enabled)`

Example Usage:

```lua
-- client side only

Citizen.CreateThread(function()
    local coords = {
        z = 118.38395690917968, y = 802.531982421875, x = -279.46728515625
    }

    local ped = feather.Ped:Create('s_m_m_valdeputy_01', coords.x, coords.y, coords.z, 0, 'world', false)

    ped:FleeAtribute('DISABLE_ENTER_VEHICLES', true)
end)
```

#### Set Ped Combat Attributes

<Badge type="warning" text="Client Side Only" />

Enable or disable pedestrian combat attributes

| Parameter    | Description                                                                                                                                                                                                                                                                        |
| ------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| attributes   | This is a list of [attributes](https://github.com/femga/rdr3_discoveries/tree/master/AI/COMBAT_ATTRIBUTES) you want to change Example { {flag = 1, enabled = false}, {flag = 2, enabled = false} }                                                                                 |
| attackrange  | The distance for aggro                                                                                                                                                                                                                                                             |
| abilitylevel | how good or not the ped is at fighting                                                                                                                                                                                                                                             |
| movement     | What kind of movement (0: Stationary (Will just stand in place), 1: Defensive (Will try to find cover and very likely to blind fire), 2: Offensive (Will attempt to charge at enemy but take cover as well), 3: Suicidal Offensive (Will try to flank enemy in a suicidal attack)) |

`ped:SetPedCombatAttributes(attributes, attackrange, abilitylevel, movement)`

Example Usage:

```lua
-- client side only

Citizen.CreateThread(function()
    local coords = {
        z = 118.38395690917968, y = 802.531982421875, x = -279.46728515625
    }

    local ped = feather.Ped:Create('s_m_m_valdeputy_01', coords.x, coords.y, coords.z, 0, 'world', false)

    ped:SetPedCombatAttributes({
        {flag = 0, enabled = false}
    }, 1, 0, 2)
end)
```

#### Set Ped Combat Style

<Badge type="warning" text="Client Side Only" />

Set the pedestrians combat style

| Parameter  | Description                                                                                            |
| ---------- | ------------------------------------------------------------------------------------------------------ |
| combathash | The [combat style](https://github.com/femga/rdr3_discoveries/tree/master/AI/COMBAT_STYLES) for the ped |
| duration   | How long the ped has this combat style                                                                 |

`ped:SetCombatStyle(combathash, duration)`

Example Usage:

```lua
-- client side only

Citizen.CreateThread(function()
    local coords = {
        z = 118.38395690917968, y = 802.531982421875, x = -279.46728515625
    }

    local ped = feather.Ped:Create('s_m_m_valdeputy_01', coords.x, coords.y, coords.z, 0, 'world', false)

    ped:SetCombatStyle('SituationAllStop', 240.0)
end)
```

#### Clear Ped Combat Style

<Badge type="warning" text="Client Side Only" />

Clear the pedestrians combat style

`ped:ClearCombatStyle()`

Example Usage:

```lua
-- client side only

Citizen.CreateThread(function()
    local coords = {
        z = 118.38395690917968, y = 802.531982421875, x = -279.46728515625
    }

    local ped = feather.Ped:Create('s_m_m_valdeputy_01', coords.x, coords.y, coords.z, 0, 'world', false)

    ped:ClearCombatStyle()
end)
```

#### Attack Target

<Badge type="warning" text="Client Side Only" />

Set a target for the ped to attack

| Parameter | Description                                                                     |
| --------- | ------------------------------------------------------------------------------- |
| target    | the ped to attack (can be player)                                               |
| style     | How long the ped has this combat style (GUARD, COMBAT_ANIMAL, LAW, LAW_SHERIFF) |

`ped:AttackTarget(target, style)`

Example Usage:

```lua
-- client side only

Citizen.CreateThread(function()
    local coords = {
        z = 118.38395690917968, y = 802.531982421875, x = -279.46728515625
    }

    local ped = feather.Ped:Create('s_m_m_valdeputy_01', coords.x, coords.y, coords.z, 0, 'world', false)

    ped:AttackTarget(PlayerPedId(), 'LAW')
end)
```

#### Remove Ped

<Badge type="warning" text="Client Side Only" />

Remove a Ped

`ped:Remove()`

Example Usage:

```lua
-- client side only

Citizen.CreateThread(function()
    local coords = {
        z = 118.38395690917968, y = 802.531982421875, x = -279.46728515625
    }

    local ped = feather.Ped:Create('s_m_m_valdeputy_01', coords.x, coords.y, coords.z, 0, 'world', false)

    ped:Remove()
end)
```

#### Get Ped

<Badge type="warning" text="Client Side Only" />

If there are natives this util does not yet support, you can use this to get the ped to utilize against any native.

`ped:GetPed()`

Example Usage:

```lua
-- client side only

Citizen.CreateThread(function()
    local coords = {
        z = 118.38395690917968, y = 802.531982421875, x = -279.46728515625
    }

    local ped = feather.Ped:Create('s_m_m_valdeputy_01', coords.x, coords.y, coords.z, 0, 'world', false)

    local rawped = ped:GetPed()

    -- Use rawped with whatever native required the ped entity
end)
```

### Horses

You can leverage Feathers built in function for easy spawn and manipulate in-game horse entities.

#### Create Horse

<Badge type="warning" text="Client Side Only" />

This will spawn a pedestrian in your game world

| Parameter  | Description                                                                                                                                                |
| ---------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| modelhash  | The [hash](https://github.com/femga/rdr3_discoveries/blob/f729ba03f75a591ce5c841642dc873345242f612/peds/peds_list.lua) of the model you want the ped to be |
| x          | x world position coordinate                                                                                                                                |
| y          | y world position coordinate                                                                                                                                |
| z          | z world position coordinate                                                                                                                                |
| heading    | The heading of the ped (Which way it is facing)                                                                                                            |
| gender     | Options: 'female' or 'male'                                                                                                                                |
| safeground | Should the ped spawn in a known ok location (default true, disable for more dine accuracy of ped placement)                                                |
| networked  | Should the ped be networked (default true)                                                                                                                 |

`Feather.Horse:Create()`

Example Usage:

```lua
-- client side only
Feather.Horse:Create('a_c_horse_americanstandardbred_black', x, y, z, heading, 'male')
```

#### Freeze Ped

<Badge type="warning" text="Client Side Only" />

Freeze a ped where they stand

| Parameter | Description                                   |
| --------- | --------------------------------------------- |
| state     | freeze or unfreeze (true/false), default true |

`horse:Freeze()`

Example Usage:

```lua

-- client side only
local horse = Feather.Horse:Create('a_c_horse_americanstandardbred_black', x, y, z, heading, 'male')
-- Freeze
horse:Freeze()
-- Unfreeze
horse:Freeze(false)
```

#### Invincible Ped

<Badge type="warning" text="Client Side Only" />

Make a ped Invincible

| Parameter | Description                           |
| --------- | ------------------------------------- |
| state     | Invincible (true/false), default true |

`horse:Invincible()`

Example Usage:

```lua

-- client side only
local horse = Feather.Horse:Create('a_c_horse_americanstandardbred_black', x, y, z, heading, 'male')
-- Invincible
horse:Invincible()
-- Not Invincible
horse:Invincible(false)
```

#### Ped CanBeDamaged

<Badge type="warning" text="Client Side Only" />

Make a ped not take damage

| Parameter | Description                             |
| --------- | --------------------------------------- |
| state     | CanBeDamaged (true/false), default true |

`horse:CanBeDamaged()`

Example Usage:

```lua

-- client side only
local horse = Feather.Horse:Create('a_c_horse_americanstandardbred_black', x, y, z, heading, 'male')
-- Can be Damaged
horse:CanBeDamaged()
-- Cannot be Damaged
horse:CanBeDamaged(false)
```

#### Set Ped Heading

<Badge type="warning" text="Client Side Only" />

change the directon a ped is facing

| Parameter | Description                      |
| --------- | -------------------------------- |
| head      | the game world direction to face |

`horse:SetHeading()`

Example Usage:

```lua

-- client side only
local horse = Feather.Horse:Create('a_c_horse_americanstandardbred_black', x, y, z, heading, 'male')
horse:SetHeading(heading)
```

#### Can Be Mounted

<Badge type="warning" text="Client Side Only" />

Set if the horse can be mounted or not

`horse:CanBeMounted()`

Example Usage:

```lua
-- client side only
local horse = Feather.Horse:Create('a_c_horse_americanstandardbred_black', x, y, z, heading, 'male')
-- Can Be Mounted
horse:CanBeMounted(heading)
-- Cannot Be Mounted
horse:CanBeMounted(heading)
```

#### Set Blip

<Badge type="warning" text="Client Side Only" />

Set a blip on ped that follows

| Parameter | Description                                                                                                                                                                       |
| --------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| bliphash  | What the [blip](https://github.com/femga/rdr3_discoveries/blob/a4b4bcd5a3006b0c1434b03e4095d038164932f7/useful_info_from_rpfs/textures/blips_mp/README.md) should show on the map |
| title     | What the blip should say                                                                                                                                                          |

`horse:SetBlip()`

Example Usage:

```lua

-- client side only
local horse = Feather.Horse:Create('a_c_horse_americanstandardbred_black', x, y, z, heading, 'male')
horse:SetBlip('Horse Name', -1230993421)
```

#### Set Prompt Name

<Badge type="warning" text="Client Side Only" />

Set the name on the target prompt for the horse

`horse:SetPromptName(title)`

Example Usage:

```lua
-- client side only
 local horse = Feather.Horse:Create('a_c_horse_americanstandardbred_black', x, y, z, heading, 'male')
 MyHorse:SetPromptName(HorseName)
```

#### Update Ped Variation

<Badge type="warning" text="Client Side Only" />

Should be called when making changes to things like Ped Expression and Meta Ped Outfits.

`horse:UpdatePedVariation()`

Example Usage:

```lua
-- client side only
local horse = Feather.Horse:Create('a_c_horse_americanstandardbred_black', x, y, z, heading, 'male')
horse:UpdatePedVariation()
```

#### Equip Meta Ped Outfit

<Badge type="warning" text="Client Side Only" />

Equip a [Meta Ped Outfit](https://github.com/femga/rdr3_discoveries/blob/master/peds_customization/ped_outfits.lua)

`horse:EquipMetaPedOutfit(outfitHash)`

Example Usage:

```lua
-- client side only
local horse = Feather.Horse:Create('a_c_horse_americanstandardbred_black', x, y, z, heading, 'male')
horse:EquipMetaPedOutfit(0x9F204EAA)
```

#### Clear a ped task

<Badge type="warning" text="Client Side Only" />

Clear any active tasks

`horse:ClearTasks()`

Example Usage:

```lua
-- client side only
local horse = Feather.Horse:Create('a_c_horse_americanstandardbred_black', x, y, z, heading, 'male')
horse:ClearTasks()
```

#### Set Component Enabled

<Badge type="warning" text="Client Side Only" />

Equips a given component

`horse:SetComponentEnabled(component)`

Example Usage:

```lua
-- client side only
local horse = Feather.Horse:Create('a_c_horse_americanstandardbred_black', x, y, z, heading, 'male')
horse:SetComponentEnabled(0x150D0DAA)
```

#### Remove Component

<Badge type="warning" text="Client Side Only" />

Removes a given component

`horse:RemoveComponent(component)`

Example Usage:

```lua
-- client side only
local horse = Feather.Horse:Create('a_c_horse_americanstandardbred_black', x, y, z, heading, 'male')
horse:RemoveComponent(0x150D0DAA)
```

#### Is Mount Seat Free

<Badge type="warning" text="Client Side Only" />

Checks if a given seat is free. Default: -1 (Drivers Seat)

`horse:IsMountSeatFree(title)`

Example Usage:

```lua
-- client side only
local horse = Feather.Horse:Create('a_c_horse_americanstandardbred_black', x, y, z, heading, 'male')
horse:IsMountSeatFree(-1)
```

#### Set Tag

<Badge type="warning" text="Client Side Only" />

Sets the title for the entity tag

`horse:SetTag(title)`

Example Usage:

```lua
-- client side only
local horse = Feather.Horse:Create('a_c_horse_americanstandardbred_black', x, y, z, heading, 'male')
horse:SetTag('Horse Name')
```

#### Set Tag Visibility

<Badge type="warning" text="Client Side Only" />

Shows or hides the Entity Tag. Param value is the style.

```
0 - NONE,
1 - ICON,
2 - SIMPLE,
3 - COMPLEX
```

`horse:SetTagVisibility(value)`

Example Usage:

```lua
-- client side only
local horse = Feather.Horse:Create('a_c_horse_americanstandardbred_black', x, y, z, heading, 'male')
horse:SetTagVisibility(3)
```

#### Is Tag Active

<Badge type="warning" text="Client Side Only" />

Checks to see if a tag is active for your horse

`horse:IsTagActive(value)`

Example Usage:

```lua
-- client side only
local horse = Feather.Horse:Create('a_c_horse_americanstandardbred_black', x, y, z, heading, 'male')
horse:IsTagActive()
```

#### Set Player Owns Mount

<Badge type="warning" text="Client Side Only" />

Sets the owner of the mount (Enables Lead)

`horse:SetPlayerOwnsMount(playerPed)`

Example Usage:

```lua
-- client side only
local horse = Feather.Horse:Create('a_c_horse_americanstandardbred_black', x, y, z, heading, 'male')
horse:SetPlayerOwnsMount(PlayerPedId())
```

#### Disable Shocking Event

<Badge type="warning" text="Client Side Only" />

Disables/Enables shocking events

`horse:DisableShockingEvents(playerPed)`

Example Usage:

```lua
-- client side only
local horse = Feather.Horse:Create('a_c_horse_americanstandardbred_black', x, y, z, heading, 'male')
-- Disables Shocking Events
horse:DisableShockingEvents()
-- Eables Shocking Events
horse:DisableShockingEvents(false)
```

#### Force Lock On

<Badge type="warning" text="Client Side Only" />

Forces lock on when targeting horse

`horse:ForceLockOn(playerPed)`

Example Usage:

```lua
-- client side only
local horse = Feather.Horse:Create('a_c_horse_americanstandardbred_black', x, y, z, heading, 'male')
-- Forces Lock On
horse:ForceLockOn()
-- Disables Lock On
horse:ForceLockOn(false)
```

#### Disable Flee From Gunshot

<Badge type="warning" text="Client Side Only" />

Disables your horse from fleeing from gunshots.

`horse:DisableFleeFromGunshot(playerPed)`

Example Usage:

```lua
-- client side only
local horse = Feather.Horse:Create('a_c_horse_americanstandardbred_black', x, y, z, heading, 'male')
-- Disables fleeing
horse:DisableFleeFromGunshot()
-- Enables fleeing
horse:DisableFleeFromGunshot(false)
```

#### Remove Ped

<Badge type="warning" text="Client Side Only" />

Remove a Ped

`horse:Remove()`

Example Usage:

```lua
-- client side only

local horse = Feather.Horse:Create('a_c_horse_americanstandardbred_black', x, y, z, heading, 'male')
horse:Remove()
```

#### Get Horse

<Badge type="warning" text="Client Side Only" />

If you need access to the raw entity use the GetHorse class method.

`horse:GetHorse()`

Example Usage:

```lua
-- client side only

local horse = Feather.Horse:Create('a_c_horse_americanstandardbred_black', x, y, z, heading, 'male')
horse:GetHorse()
```

#### Example Script

This example is to provide a way to spawn in a horse and set all of its basic flags until Feather Framework has a stables script. There are a few different commands that showcase the functionality of how this class works. This includes various components modeled after SavSin's horse. It also shocases a few scenarios and interactions available for horses.

```lua
Feather = exports['feather-core'].initiate()

local MyHorse
local HorseName = "Night Star"

RegisterCommand('horse', function()
  local x, y, z = table.unpack(GetEntityCoords(PlayerPedId()))
  local heading = GetEntityHeading(PlayerPedId())
  MyHorse = Feather.Horse:Create('a_c_horse_americanstandardbred_black', x, y, z, heading, 'male')

  MyHorse:SetComponentEnabled(0x150D0DAA)
  MyHorse:SetComponentEnabled(0x127E0412)
  MyHorse:SetComponentEnabled(0x75178DD2)
  MyHorse:SetComponentEnabled(0x293E17B3)
  MyHorse:SetComponentEnabled(0x9DF8175C)
  MyHorse:SetComponentEnabled(0x4124CC49)
  MyHorse:SetComponentEnabled(0x9AD2AA40)
  MyHorse:SetComponentEnabled(0x84E5AFA)
  MyHorse:SetComponentEnabled(0xC907FCA9)
  MyHorse:SetComponentEnabled(0x5497E784)

  MyHorse:SetPlayerOwnsMount(PlayerPedId())
  MyHorse:DisableShockingEvents()
  MyHorse:ForceLockOn()
  MyHorse:DisableFleeFromGunshot()

  MyHorse:SetBlip(HorseName)
  MyHorse:SetPromptName(HorseName)
  MyHorse:SetTag(HorseName)
  MyHorse:SetTagVisibility(3)
end)

RegisterCommand('clean', function()
  MyHorse:Clean()
  MyHorse:ClearDamage()
  MyHorse:ClearBloodDamage()
end)

RegisterCommand('brush', function()
  MyHorse:PlayAnimation(PlayerPedId(), joaat('Interaction_Brush'),
    joaat('p_brushHorse02x'), 1)
end)

RegisterCommand('feed', function()
  MyHorse:PlayAnimation(PlayerPedId(), joaat('Interaction_Food'),
    joaat('s_horsnack_haycube01x'), true)
end)

RegisterCommand('wallow', function()
  MyHorse:StartScenario('WORLD_ANIMAL_HORSE_WALLOW')
end)

RegisterCommand('drink', function()
  MyHorse:StartScenario('WORLD_ANIMAL_HORSE_DRINK_GROUND')
end)

RegisterCommand('apo', function()
  RearUp()
end)

AddEventHandler('onResourceStop', function()
  MyHorse:Remove()
end)

```

### Objects

You can leverage Feathers built in function for easy spawn and manipulate in-game Object entities.

#### Create Object

<Badge type="warning" text="Client Side Only" />

This will spawn an object in your game world

| Parameter | Description                                                                                                                                                |
| --------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| modelhash | The [hash](https://github.com/femga/rdr3_discoveries/blob/f729ba03f75a591ce5c841642dc873345242f612/peds/peds_list.lua) of the model you want the ped to be |
| x         | x world position coordinate                                                                                                                                |
| y         | y world position coordinate                                                                                                                                |
| z         | z world position coordinate                                                                                                                                |
| heading   | The heading of the ped (Which way it is facing)                                                                                                            |
| networked | Where to spawn ped. (world, vehicle, mount)                                                                                                                |
| method    | standard or custom - Standard will run place on ground and a few other house keeping                                                                       |

`featherObjects:Create()`

Example Usage:

```lua

-- client side only

Citizen.CreateThread(function()
    local coords = {
        z = 118.38395690917968, y = 802.531982421875, x = -279.46728515625
    }

    local obj = feather.Object:Create('p_package09', coords.x, coords.y, coords.z, 0, true, 'standard')
end)
```

#### Pickup Light

<Badge type="warning" text="Client Side Only" />

Add a light to the object

| Parameter | Description |
| --------- | ----------- |
| state     | True/False  |

`obj:PickupLight(state)`

Example Usage:

```lua

-- client side only

Citizen.CreateThread(function()
    local coords = {
        z = 118.38395690917968, y = 802.531982421875, x = -279.46728515625
    }

    local obj = feather.Object:Create('p_package09', coords.x, coords.y, coords.z, 0, true, 'standard')

    obj:PickupLight(true)
end)
```

#### Freeze

<Badge type="warning" text="Client Side Only" />

Freeze Object

| Parameter | Description |
| --------- | ----------- |
| state     | True/False  |

`obj:Freeze(state)`

Example Usage:

```lua

-- client side only

Citizen.CreateThread(function()
    local coords = {
        z = 118.38395690917968, y = 802.531982421875, x = -279.46728515625
    }

    local obj = feather.Object:Create('p_package09', coords.x, coords.y, coords.z, 0, true, 'standard')

    obj:Freeze(true)
end)
```

#### Set Heading

<Badge type="warning" text="Client Side Only" />

Set the heading of an object

| Parameter | Description                             |
| --------- | --------------------------------------- |
| heading   | number coord relative to the game world |

`obj:SetHeading(heading)`

Example Usage:

```lua

-- client side only

Citizen.CreateThread(function()
    local coords = {
        z = 118.38395690917968, y = 802.531982421875, x = -279.46728515625
    }

    local obj = feather.Object:Create('p_package09', coords.x, coords.y, coords.z, 0, true, 'standard')

    obj:SetHeading(0)
end)
```

#### Place On Ground

<Badge type="warning" text="Client Side Only" />

place the object on the groun properly

| Parameter | Description |
| --------- | ----------- |
| state     | true/false  |

`obj:PlaceOnGround(state)`

Example Usage:

```lua

-- client side only

Citizen.CreateThread(function()
    local coords = {
        z = 118.38395690917968, y = 802.531982421875, x = -279.46728515625
    }

    local obj = feather.Object:Create('p_package09', coords.x, coords.y, coords.z, 0, true, 'standard')

    obj:PlaceOnGround(true)
end)
```

#### Set As Mission

<Badge type="warning" text="Client Side Only" />

The engine will keep object when players leave the area

| Parameter | Description |
| --------- | ----------- |
| state     | true/false  |

`obj:SetAsMission(state)`

Example Usage:

```lua

-- client side only

Citizen.CreateThread(function()
    local coords = {
        z = 118.38395690917968, y = 802.531982421875, x = -279.46728515625
    }

    local obj = feather.Object:Create('p_package09', coords.x, coords.y, coords.z, 0, true, 'standard')

    obj:SetAsMission(true)
end)
```

#### Set As No Longer Needed

<Badge type="warning" text="Client Side Only" />

The engine will remove when players leave the area

`obj:SetAsNoLongerNeeded()`

Example Usage:

```lua

-- client side only

Citizen.CreateThread(function()
    local coords = {
        z = 118.38395690917968, y = 802.531982421875, x = -279.46728515625
    }

    local obj = feather.Object:Create('p_package09', coords.x, coords.y, coords.z, 0, true, 'standard')

    obj:SetAsNoLongerNeeded()
end)
```

#### Invincible

<Badge type="warning" text="Client Side Only" />

Set object as invincible

| Parameter | Description |
| --------- | ----------- |
| state     | true/false  |

`obj:Invincible(state)`

Example Usage:

```lua

-- client side only

Citizen.CreateThread(function()
    local coords = {
        z = 118.38395690917968, y = 802.531982421875, x = -279.46728515625
    }

    local obj = feather.Object:Create('p_package09', coords.x, coords.y, coords.z, 0, true, 'standard')

    obj:Invincible(true)
end)
```

#### Horse Jumpable

<Badge type="warning" text="Client Side Only" />

Sets object as not jumpable by horse.

| Parameter | Description |
| --------- | ----------- |
| state     | true/false  |

`obj:SetNotHorseJumpable(state)`

Example Usage:

```lua

-- client side only

Citizen.CreateThread(function()
    local coords = {
        z = 118.38395690917968, y = 802.531982421875, x = -279.46728515625
    }

    local obj = feather.Object:Create('p_package09', coords.x, coords.y, coords.z, 0, true, 'standard')

    obj:SetNotHorseJumpable(true)
end)
```

#### Remove

<Badge type="warning" text="Client Side Only" />

Remove Object

`obj:Remove()`

Example Usage:

```lua

-- client side only

Citizen.CreateThread(function()
    local coords = {
        z = 118.38395690917968, y = 802.531982421875, x = -279.46728515625
    }

    local obj = feather.Object:Create('p_package09', coords.x, coords.y, coords.z, 0, true, 'standard')

    Wait(5000)

    obj:Remove()
end)
```

#### Get Object

<Badge type="warning" text="Client Side Only" />

Remove Object

`obj:GetObj()`

Example Usage:

```lua

-- client side only

Citizen.CreateThread(function()
    local coords = {
        z = 118.38395690917968, y = 802.531982421875, x = -279.46728515625
    }

    local obj = feather.Object:Create('p_package09', coords.x, coords.y, coords.z, 0, true, 'standard')

    Wait(5000)

    local tobj = obj:GetObj()
end)
```

### DataView

A DataView utility

Example Usage:

```lua
-- client side only
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

### PrettyPrint

Feather provides an enhanced `print` functionality to the default Lua.

#### Features

- Table printing support
- ANSI Color and text formatting support

#### Setup

```lua

-- Server and Client
Citizen.CreateThread(function()
    --Use print as you normally would.
    feather.Print('%{bold} %{red}TEST', {
        hello = "world"
    })

    -- Print Output: TEST, { "hello" = "world"}
end)
```

#### Colors

Colors and backgrounds can be used usilizing the `%{attribute}` format

| Type             | format                                           | Description                   |
| ---------------- | ------------------------------------------------ | ----------------------------- |
| Text Format      | %{bold}                                          | Make Text Font weight heavier |
| Text Color       | %{reset}                                         | Set back to default color     |
| Text Color       | %{red}                                           |                               |
| Text Color       | %{green}                                         |                               |
| Text Color       | %{orange}                                        |                               |
| Text Color       | %{navy}                                          |                               |
| Text Color       | %{magenta} or %{purple}                          |                               |
| Text Color       | %{cyan}                                          |                               |
| Text Color       | %{gray} or %{grey}                               |                               |
| Text Color       | %{lightgray} or %{lightgrey}                     |                               |
| Text Color       | %{peach}                                         |                               |
| Text Color       | %{lightgreen}                                    |                               |
| Text Color       | %{yellow}                                        |                               |
| Text Color       | %{blue}                                          |                               |
| Text Color       | %{pink}                                          |                               |
| Text Color       | %{babyblue}                                      |                               |
| Background Color | %{highlight red}                                 |                               |
| Background Color | %{highlight green}                               |                               |
| Background Color | %{highlight orange}                              |                               |
| Background Color | %{highlight navy}                                |                               |
| Background Color | %{highlight magenta}                             |                               |
| Background Color | %{highlight cyan}                                |                               |
| Background Color | %{highlight gray} or %{highlight grey}           |                               |
| Background Color | %{highlight lightgray} or %{highlight lightgrey} |                               |
| Background Color | %{highlight peach}                               |                               |
| Background Color | %{highlight lightgreen}                          |                               |
| Background Color | %{highlight yellow}                              |                               |
| Background Color | %{highlight blue}                                |                               |
| Background Color | %{highlight pink}                                |                               |
| Background Color | %{highlight babyblue}                            |                               |

Example Usage:

```lua
    print('%{blue}moon over the rainbow')
```

![image](https://user-images.githubusercontent.com/10902965/206995197-bf635488-75a1-4f40-866a-080b5f09b065.png)

### Render

Render is an API to help with in-world and on screen drawing. (Text, Sprites, etc.)

#### WorldToScreen

<Badge type="warning" text="Client Side Only" />

Converts an in-world coordinate to a screen position

| Parameter     | Description       |
| ------------- | ----------------- |
| pos (vector3) | in-world position |

> Returns vector 2 screen coords.

> Returns Bool if its on screen

`object:WorldToScreen(vector3(x, y, z))`

Example Usage:

```lua
-- Client
RegisterCommand('trigger', function()
    local coords, onscreen = feather.Render:WorldToScreen(GetEntityCoords(PlayerPedId()))

    print(coords.x, coords.y, onscreen)
end)
```

#### WorldToHud

<Badge type="warning" text="Client Side Only" />

Converts in-world coordinate to a hud position (bounded to screen)

| Parameter     | Description       |
| ------------- | ----------------- |
| pos (vector3) | in-world position |

> Returns vector 2 screen coords

> Returns Bool if its on screen

`object:WorldToHud(vector3(x, y, z))`

Example Usage:

```lua
-- Client
RegisterCommand('trigger', function()
    local coords, onscreen = feather.Render:WorldToHud(GetEntityCoords(PlayerPedId()))

    print(coords.x, coords.y, onscreen)
end)
```

#### DrawSprite

<Badge type="warning" text="Client Side Only" />

Draw Sprites on screen

| Parameter        | Description                                                                                                                                                                          |
| ---------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| pos (vector2)    | table containing x and y coords of sprite position on screen                                                                                                                         |
| size (vector2)   | table containing x and y sizes (relative to screen x and y size, ranges from 0.0-1.0)                                                                                                |
| rotation (float) | number of sprite rotation in degrees                                                                                                                                                 |
| color (vector3)  | table of rgba values                                                                                                                                                                 |
| texturedict      | [Name of texture](https://github.com/femga/rdr3_discoveries/tree/master/useful_info_from_rpfs) dictionary to load texture from (e.g. "CommonMenu", "MPWeaponsCommon", etc.)          |
| texturename      | [Name of texture](https://github.com/femga/rdr3_discoveries/tree/master/useful_info_from_rpfs) to load from texture dictionary (e.g. "last_team_standing_icon", "tennis_icon", etc.) |

`featherRender:DrawSprite(pos, size, rotation, color, texturedict, texturename)`

Example Usage:

```lua
-- Client
Citizen.CreateThread(function()
    while  true  do
        Citizen.Wait(0)
        local onScreen, _x, _y = GetScreenCoordFromWorldCoord(GetEntityCoords(PlayerPedId()))

        if onScreen then
            feather.Render:DrawSprite(vector2(_x, _y), vector2(0.2, 0.2), 190.0, {r: 255, g: 0, b: 0, a: 255},  "feeds", "hud_menu_4a")
        end
    end
end)

```

#### Draw Rectangle

<Badge type="warning" text="Client Side Only" />

Draw a rectangle on screen

| Parameter       | Description                                                                        |
| --------------- | ---------------------------------------------------------------------------------- |
| pos (vector2)   | table containing x and y coords of sprite position on screen (ranges from 0.0-1.0) |
| size (vector2)  | table containing x and y sizes (ranges from 0.0-1.0)                               |
| color (vector3) | table of rgba values                                                               |

`featherRender:DrawRectangle(pos, size, color)`

Example Usage:

```lua
-- Client
Citizen.CreateThread(function()
    while  true  do
        Citizen.Wait(0)
        local onScreen, _x, _y = GetScreenCoordFromWorldCoord(GetEntityCoords(PlayerPedId()))

        if onScreen then
            feather.Render:DrawRectangle(vector2(_x, _y), vector2(0.2, 0.2), {r: 255, g: 0, b: 0, a: 255})
        end
    end
end)

```

#### Draw Marker

<Badge type="warning" text="Client Side Only" />

Draw a Marker in-world

| Parameter    | Description                            |
| ------------ | -------------------------------------- |
| type         |                                        |
| pos          | table containing x y and z coords      |
| dir          | table containing x y and z coords      |
| rot          | rotation of the marker                 |
| scale        | table containing x y and z scale       |
| color        | table of rgba values                   |
| bobupanddown | does it bounce (true/false)            |
| facecamera   | should it face the camera (true/false) |
| rotate       | does the marker rotate (true/false)    |
| drawonents   | (true/false)                           |

`featherRender:DrawMarker(type, pos, dir, rot, scale, color, bob, facevamera, rotate, drawonents)`

Example Usage:

```lua
-- Client
Citizen.CreateThread(function()
    while  true  do
        Citizen.Wait(0)
        feather.Render:DrawMarker(0x50638AB9, GetEntityCoords(PlayerPedId()), vector3(0.0, 0.0, 0.0), vector3(0.0, 0.0, 0.0), vecotr3(0.15, 0.15, 0.15), {r: 255, g: 0, b: 0, a: 255}, false, false, false, false)
    end
end)

```

#### Draw Text

<Badge type="warning" text="Client Side Only" />

Draw a Text on screen

| Parameter | Description                                                 |
| --------- | ----------------------------------------------------------- |
| pos       | table containing x and y coords of text position (0-1, 0-1) |
| text      | table containing x y and z coords                           |
| color     | table of rgba values                                        |
| scale     | scale of the text                                           |
| shadow    | if shadow is enabled (true/false)                           |

`feather.Render:DrawText(pos, text, color, scale, shadow)`

Example Usage:

```lua
-- Client
Citizen.CreateThread(function()
    while  true  do
        Citizen.Wait(0)
        local onScreen, _x, _y = GetScreenCoordFromWorldCoord(GetEntityCoords(PlayerPedId()))

        if onScreen then
            feather.Render:DrawText(vector2(_x, _y), 'Feather Rules!', {r: 255, g: 0, b: 0, a: 255}, 1.0, false)
        end
    end
end)

```

#### Draw Text 3D

<Badge type="warning" text="Client Side Only" />

Draw 3D Text on screen

| Parameter | Description       |
| --------- | ----------------- |
| x         | x coord           |
| y         | y coord           |
| z         | z coord           |
| text      | text to display   |
| scale     | scale of the text |

`feather.Render:Draw3DText(x, y, z, text, scale)`

Example Usage:

```lua
-- Client
Citizen.CreateThread(function()
    while  true  do
        Citizen.Wait(0)
        local playerCoords = GetEntityCoords(PlayerPedId())
        Feather.Render.Draw3DText(playerCoords.x, playerCoords.y, playerCoords.z, 'This will show at the coords', 0.2)
    end
end)

```

### Game Events

Feather has a built-in network and entity event watcher that can be utilized by other scripts easily.

#### Register Event Listener

<Badge type="warning" text="Client Side Only" />

Register a callback that will be triggered whenever an in-game client event triggers.

| Parameter | Description                                         |
| --------- | --------------------------------------------------- |
| eventname | name of the event to watch/listen to                |
| callback  | fucntion to be triggered when an event is triggered |

`featherEvents:RegisterEventListener(eventname, callback)`

Example Usage:

```lua
-- Client
Citizen.CreateThread(function()
    featherEvents:RegisterEventListener('EVENT_PICKUP_CARRIABLE', function(args)
        print("EVENT TRIGGERED: EVENT_PICKUP_CARRIABLE", args[1], args[2])
    end)
end)
```

#### Remove Event Listener

<Badge type="warning" text="Client Side Only" />

Removes an event from the listener queue, listener will no longer listen once removed. This frees up in-game memory andis best practice if using listeners in a dynamic, or temporary way.

| Parameter | Description                               |
| --------- | ----------------------------------------- |
| listener  | object returns from RegisterEventListener |

`featherEvents:RenoveEventListener(listener)`

Example Usage:

```lua
-- Client
Citizen.CreateThread(function()
    local listener = featherEvents:RegisterEventListener('EVENT_PICKUP_CARRIABLE', function(args)
        print("EVENT TRIGGERED: EVENT_PICKUP_CARRIABLE", args[1], args[2])
    end)


    Wait(40000)

    featherEvents:RenoveEventListener(listener)
end)
```

#### DevMode

<Badge type="warning" text="Client Side Only" />

This provides the ability to print every in-game event for development purpose.

| Parameter | Description                                                                                 |
| --------- | ------------------------------------------------------------------------------------------- |
| state     | object returns from RegisterEventListener                                                   |
| type      | (optional, will default to all) the type of event to listen too (entities, network, or all) |

`featherEvents:DevMode(listener)`

Example Usage:

```lua
-- Client
Citizen.CreateThread(function()
    featherEvents:DevMode(true, 'entities')
    --  featherEvents:DevMode(true, 'network')
end)
```

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

### Remote Procedure Callback - RPC

An RPC allows developers to easily communicate between the client and server without interrupting the runtime queue.

Learn more here: https://en.wikipedia.org/wiki/Remote_procedure_call

#### Register your remote prodecure

> feather.RPC.Register(name, callback)

- `name<string>` - remote method name
- `callback<function>` - method function (see method callback)

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

- `name<string>` - method name
- `params<table>` - params passed to method
- `callback<function>` - callback called when results are received
- `player<player>` - optional player source to call method on (only for server-side)

```lua
feather.RPC.Call("doSomethingRemote", { text = "World", delay = 1000 }, function (result)
    print("[Example] Callback result: "..tostring(result))
end)
```

#### Call RPC with async.

Calls remote method asynchronously. Can only be used inside `Citizen.CreateThread`.

> feather.RPC.CallAsync(name, params [, player])

- `name<string>` - method name
- `params<table>` - params passed to method
- `player<player>` - optional player source to call method on (only for server-side)
- returns `result<any>` - any data returned by remote method

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

- `name<string>` - method name
- `params<table>` - params passed to method
- `player<player>` - optional player source to call method on (only for server-side)

```lua
feather.RPC.Notify("doSomethingRemote", { text = "World", delay = 1000 }, function (result)
    print("[Example] Callback result: "..tostring(result))
end)
```

### Key codes

easy game keycodes are exposed to the API.

example

```lua
feather.Keys.A -- returns 0x7065027D
```

### Locale API

### Register Locale Translations
Registers a table of translations

> feather.locale.register(name, translation)

- `name<string>` - name of the translation
- `translation<table>` - a table of translations

```lua
feather.Locale.register("en_us", {
    loadscreen_title = "Loading the world...",
    loadscreen_subtitle = "In this dusty frontier, loading moments become tales whispered near campfires.",
    loadscreen_signature = "-Someone probably"
})
```

### Register Locale Translations
Registers a table of translations

> feather.locale.translate(src, name)

- `src` - player source (if client then 0)
-  `name<string>` - name of the translation

```lua
  -- (src, name). if on client src is 0
  feather.Locale.translate(0, "loadscreen_title")
```

### Github UI Check
You can have the core check that you have ui/index.html installed properly.

```
name 'feather-core'
github_ui_check 'true'
github_link 'https://github.com/FeatherFramework/feather-core'
```

### Github Version Control

You can have feather check if your script is up-to-date by adding the following to your github repo

```
name 'feather-core'
version '1.0.0'
github_version_check 'true'
github_version_type 'release' --OR file
github_link 'https://github.com/FeatherFramework/feather-core'
```

The script will check what current version of the script is downloaded via the Version defined in the fxmanifest.

For Example version '1.0'

#### Release(Tag) Based Checks

_How to use [Github Releases](https://docs.github.com/en/repositories/releasing-projects-on-github/managing-releases-in-a-repository)_

> Create a Release and tag with the version number

_Correct: `1.0.0`_

_Wrong: `v1.1.0`_

#### Version File Based Checks

> Create a file called `version` with the following contents

```txt
<1.3>
- More awesome updates
<1.1>
- Some awesome updates
<1.0>
- My first Update
```


### Files
Docs Coming Soon..


### Notifications
Docs Coming Soon..

### Instancing
Docs Coming Soon..
