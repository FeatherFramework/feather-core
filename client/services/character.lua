local PauseOpen = false
local ActiveCharacterData = {}


local function ClearUIFeed()
    Citizen.InvokeNative(0x6035E8FBCA32AC5E) --UiFeedClearAllChannels
end

local function preventWeaponSoftlock()
    --Disable controller actions within the weapons wheel (This prevents a soft lock)
    DisableControlAction(0, 0x7DA48D2A, true)
    DisableControlAction(0, 0x9CC7A1A4, true)
    Citizen.InvokeNative(0xFC094EF26DD153FA, 2)
end

local function disableRandomLootPrompt()
    -- Disable random loot prompts
    Citizen.InvokeNative(0xFC094EF26DD153FA, 2)
end

local function setupCharacterMenuIdle()
    -- This thread handles menu idle animation
    Citizen.CreateThread(function()
        while true do
            Wait(0)
            local ped = PlayerPedId()

            if IsPauseMenuActive() and not PauseOpen then
                SetCurrentPedWeapon(ped, 0xA2719263, true) -- set unarmed
                SetCurrentPedWeapon(ped, GetHashKey("weapon_unarmed"))
                if not IsPedOnMount(ped) then
                    TaskStartScenarioInPlace(PlayerPedId(), GetHashKey("WORLD_HUMAN_SIT_GROUND_READING_BOOK"), -1, true,
                        "StartScenario", 0, false)
                end
                PauseOpen = true
            end

            if not IsPauseMenuActive() and PauseOpen then
                ClearPedTasks(ped)
                Wait(4000)
                SetCurrentPedWeapon(ped, 0xA2719263, true) -- set unarmed
                SetCurrentPedWeapon(ped, GetHashKey("weapon_unarmed"))
                PauseOpen = false
            end
        end
    end)
end

--Global as the main.lua uses it during initial startup. (sooner the better for this to start.)
function StartCharacterEssentials()
    -- Disables award notifications
    EventsAPI:RegisterEventListener("EVENT_CHALLENGE_GOAL_COMPLETE", ClearUIFeed)
    EventsAPI:RegisterEventListener("EVENT_CHALLENGE_REWARD", ClearUIFeed)
    EventsAPI:RegisterEventListener("EVENT_DAILY_CHALLENGE_STREAK_COMPLETED", ClearUIFeed)
end

----------------------------------
-- Character Position handling --
----------------------------------
local function startPositionSync()
    Citizen.CreateThread(function()
        while true do
            local result = RPCAPI.CallAsync("UpdatePlayerCoords", GetEntityCoords(PlayerPedId()))
            print(tostring(result))
            Wait(Config.PositionSync)
        end
    end)
end

local function SpawnLoop()
    Citizen.CreateThread(function()
        while true do
            if Config.DisableRandomLootPrompts then disableRandomLootPrompt() end

            preventWeaponSoftlock()
            Wait(1)
        end
    end)
end

----------------------------------
-- Character Spawn handling --
----------------------------------
local function SpawnHandler(character)
    DoScreenFadeOut(1000)

    -- TODO: Maybe for funsies add a dynamic text to this load (random quote or something)
    Citizen.InvokeNative(0x1E5B70E53DB661E5, 0, 0, 0, Config.LoadScreen.title, Config.LoadScreen.subtitle, Config.LoadScreen.subtitle)

    ActiveCharacterData = character
    local player = PlayerPedId()

    local x = tonumber(character.X)
    local y = tonumber(character.Y)
    local z = tonumber(character.Z)

    SetEntityCoords(player, x, y, z)
    local valid, outPosition = GetSafeCoordForPed(x, y, z, false, 16)
    if valid then
        x = outPosition.x
        y = outPosition.y
        z = outPosition.z
    end

    local foundground, groundZ, normal = GetGroundZAndNormalFor_3dCoord(x, y, z)
    if foundground then
        z = groundZ
    end

    Wait(500)
    startPositionSync()

    if Config.IdleAnimation then setupCharacterMenuIdle() end
    SpawnLoop()
    
    -- Wait for the client natives and loaders to be ready.
    while true do
        Wait(2000)

        if InteriorsActive == true and IMapsActive == true and ClientReady == true then
            break
        end
    end

    ShutdownLoadingScreen()
    DoScreenFadeIn(2000)
end

RegisterNetEvent("bcc:character:spawn")
AddEventHandler("bcc:character:spawn", SpawnHandler)
