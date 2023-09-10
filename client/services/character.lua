local PauseOpen = false
ActiveCharacter = {}
local ActiveSystems = {
    spawn = false,
    menuidle = false,
    possync = false
}

local function preventWeaponSoftlock()
    --Disable controller actions within the weapons wheel (This prevents a soft lock)
    DisableControlAction(0, 0x7DA48D2A, true)
    DisableControlAction(0, 0x9CC7A1A4, true)
    Citizen.InvokeNative(0xFC094EF26DD153FA, 2)
end

local function disableHUD()
    DisableControlAction(0, 0x580C4473, true)
    DisableControlAction(0, 0xCF8A4ECA, true)
end

local function disableUICards()
    DisableControlAction(0, 0x9CC7A1A4, true) -- Disable special ability when open hud
    DisableControlAction(0, 0x1F6D95E5, true) -- Disable f4 key that contains HUD
end

local function RagDollPlayer()
    local player = PlayerPedId()
    SetPedToRagdoll(player, 4000, 4000, 0, false, false, false)
    ResetPedRagdollTimer(player)
    DisablePedPainAudio(player, true)
end

local function killPlayer()
    SetEntityHealth(PlayerPedId(), 0, 0)
end

local function revivePlayer()
    exports.spawnmanager.setAutoSpawn(true)
    DisplayHud(true)
    DisplayRadar(true)

    AnimpostfxPlay("PlayerWakeUpInterrogation")

    local player = PlayerPedId()
    ResurrectPed(player)

    SetAttributeCoreValue(player, 0, 100)
    SetEntityHealth(player, 600, 1)
    SetAttributeCoreValue(player, 1, 100)
    RestorePedStamina(player, 1065330373)

    RPCAPI.Call("CharacterDeath", 0)
end

local function hoursLaterDisplay()
    DoScreenFadeOut(2000)
    Wait(2000)
    AnimpostfxPlay("Title_Gen_FewHoursLater")
    Wait(3000)
    DoScreenFadeIn(2000)
end

-- This respawns a player at the closes hospital.'
-- TODO: Add location to respawn at.
local function respawnPlayer()
    hoursLaterDisplay()
    revivePlayer()
end

local function setupCharacterMenuIdle()
    ActiveSystems.menuidle = true

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

            if ActiveSystems.menuidle == false then
                break
            end
        end
    end)
end


local function EssentialsLoop()
    ActiveSystems.spawn = true
    Citizen.CreateThread(function()
        while true do
            if Config.DisableRandomLootPrompts then DisableRandomLootPrompt() end

            disableHUD()
            disableUICards()
            preventWeaponSoftlock()



            if ActiveSystems.spawn == false then
                break
            end
            Wait(1)
        end
    end)
end

--Global as the main.lua uses it during initial startup. (sooner the better for this to start.)
function StartCharacterEssentials()
    -- Disables award notifications
    EventsAPI:RegisterEventListener("EVENT_CHALLENGE_GOAL_COMPLETE", ClearUIFeed)
    EventsAPI:RegisterEventListener("EVENT_CHALLENGE_REWARD", ClearUIFeed)
    EventsAPI:RegisterEventListener("EVENT_DAILY_CHALLENGE_STREAK_COMPLETED", ClearUIFeed)

    EssentialsLoop()
end

----------------------------------
-- Character Position handling --
----------------------------------
local function startPositionSync()
    ActiveSystems.possync = true
    Citizen.CreateThread(function()
        while true do
            ActiveCharacter = RPCAPI.CallAsync("UpdatePlayerCoords", GetEntityCoords(PlayerPedId()))
            Wait(Config.PositionSync)

            if ActiveSystems.possync == false then
                break
            end
        end
    end)
end

local deadInitiated = false
local function DeadCheck()
    local DeadPromptGroup = PromptsAPI:SetupPromptGroup()                                                                      --Setup Prompt Group
    local DeadPrompt = DeadPromptGroup:RegisterPrompt("Hold", Keys.R, 1, 1, true, 'hold',
        { timedeventhash = "MEDIUM_TIMED_EVENT" })                                                                                 --Register your first prompt

    CreateThread(function()
        while true do
            Wait(0)
            local player = PlayerPedId()

            if IsEntityDead(player) then
                -- Check to run dead initiate (this ensure it only runs one time when dead)
                if deadInitiated == false then
                    NetworkSetInSpectatorMode(false, player)
                    exports.spawnmanager.setAutoSpawn(false)
                    DisplayHud(false)
                    DisplayRadar(false)
                    deadInitiated = true

                    RPCAPI.Call("CharacterDeath", 1)
                    -- TODO: Send to server to update DB (then ensure dead is set from db on character initiate)
                end
                DeadPromptGroup:ShowGroup("Respawn")

                --TODO: Account for a countdown for when you can respawn
                if IsEntityAttachedToAnyPed(player) then
                    -- Player cant respawn as they are being carried
                    -- TODO: make sure the camera follows.
                    DeadPrompt:EnabledPrompt(false)
                else
                    DeadPrompt:EnabledPrompt(true)
                    if DeadPrompt:HasCompleted() then
                        respawnPlayer()
                    end
                end
            end
        end
    end)
end

----------------------------------
-- Character Spawn handling --
----------------------------------
RegisterNetEvent("Feather:Character:Spawn", function(character)
    DoScreenFadeOut(2000)

    Citizen.InvokeNative(0x1E5B70E53DB661E5, 0, 0, 0, LocalesAPI.translate(0, "loadscreen_title"),
        LocalesAPI.translate(0, "loadscreen_subtitle"), LocalesAPI.translate(0, "loadscreen_signature"))

    local player = PlayerPedId()

    local x = tonumber(character.x)
    local y = tonumber(character.y)
    local z = tonumber(character.z)

    local groundCheck, ground = nil, nil
    for height = 1, 1000 do
        groundCheck, ground = GetGroundZAndNormalFor_3dCoord(x, y, height + 0.0)
        if groundCheck then
            break
        end
    end
    z = ground

    SetEntityCoords(player, x, y, z)
    SetEntityHeading(player, GetEntityHeading(player))
    Wait(500)

    GuarmaCheck(player)
    SetEagleEye(player, Config.UseEagleEye)
    SetDeadEye(player, Config.UseDeadEye)

    startPositionSync()
    DeadCheck()
    
    -- Wait for the client natives and loaders to be ready.
    while true do
        Wait(2000)

        if InteriorsActive == true and IMapsActive == true and ClientReady == true then
            break
        end
    end

    if Config.IdleAnimation then setupCharacterMenuIdle() end

    --Set global fog of war, to to the wording of the config, we inverse the value
    MapAPI.setFOW(not Config.UseFogOfWar)

    Wait(2000)
    if character.dead == 1 then
        killPlayer()
    end

    ShutdownLoadingScreen()
    DoScreenFadeIn(2000)

    NotifyAPI.ToolTip(LocalesAPI.translate(0, "spawn_welcome"), 5000)

    ActiveCharacter = character

    TriggerServerEvent("Feather:Character:Spawned", character)
end)

RegisterCommand('logout', function()
    RPCAPI.CallAsync("UpdatePlayerCoords", GetEntityCoords(PlayerPedId()))
    RPCAPI.CallAsync("LogoutCharacter", {})
    ActiveCharacter = {}
    ActiveSystems = {
        spawn = false,
        menuidle = false,
        possync = false
    }

    MapAPI.setFOW(true)
end)
