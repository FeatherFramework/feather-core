TEMPORARY FILE WHILE WE UPDATE DOCS ON SPAWNING HORSE!!!!

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

RegisterCommand('sleep', function()
  MyHorse:StartScenario('WORLD_ANIMAL_HORSE_SLEEPING')
end)

RegisterCommand('apo', function()
  RearUp()
end)

function RearUp()
  MyHorse:HorseAction(5)
  MyHorse:SetPedConfigFlag(207, true)
  Wait(3500)
  MyHorse:SetPedConfigFlag(207, false)
end

AddEventHandler('onResourceStop', function()
  MyHorse:Remove()
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
