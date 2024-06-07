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

    if Config.Character.death.cameraRotation == true then
        EndDeathCam()
    end

    RPCAPI.Call("CharacterDeath", 0)

    TriggerServerEvent('Feather:Character:Revived')
end

local function teleportToClosestMedical()
    local closestIndex = 1
    local closestDistance = 99999999999999
    local player = PlayerPedId()
    local pcoords = GetEntityCoords(player)
    for index, location in ipairs(Config.RespawnLocations) do
        local distance = #(location.coords - pcoords)
        if distance < closestDistance then
            closestIndex = index
            closestDistance = distance
        end
    end

    local hospital = Config.RespawnLocations[closestIndex]
    local x, y, z = table.unpack(hospital.coords)
    local groundCheck, ground = nil, nil
    for height = 1, 1000 do
        groundCheck, ground = GetGroundZAndNormalFor_3dCoord(x, y, height + 0.0)
        if groundCheck then
            break
        end
    end

    if ground > 0.0 then
        z = ground
    end
    
    SetEntityCoords(player, x, y, z)
    SetEntityHeading(player, hospital.heading)
    Citizen.InvokeNative(0x9587913B9E772D29, player, 0)
end

local function hoursLaterDisplay()
    AnimpostfxPlay("Title_Gen_FewHoursLater")
    Wait(3000)
    DoScreenFadeIn(2000)
end

-- This respawns a player at the closes hospital.'
-- TODO: Add location to respawn at.
local function respawnPlayer()
    DoScreenFadeOut(2000)
    Wait(2000)
    teleportToClosestMedical()
    hoursLaterDisplay()
    revivePlayer()
end

local function setupCharacterMenuIdle()
    ActiveSystems.menuidle = true

    -- This thread handles menu idle animation
    CreateThread(function()
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
    CreateThread(function()
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
    CreateThread(function()
        while true do
            ActiveCharacter = RPCAPI.CallAsync("UpdatePlayerCoords", GetEntityCoords(PlayerPedId()))
            Wait(Config.PositionSync)

            if ActiveSystems.possync == false then
                break
            end
        end
    end)
end

local deathTimer = 0
local function startDeathTimer()
    CreateThread(function()
        deathTimer = Config.Character.death.timer
        while deathTimer > 0 do
            Wait(1000)
            deathTimer = deathTimer - 1
        end
    end)
end

local function DeadCheck()
    local deadInitiated = false
    local deadPromptGroup = PromptsAPI:SetupPromptGroup() --Setup Prompt Group
    local deadPrompt = deadPromptGroup:RegisterPrompt(LocalesAPI.translate(0, "death_prompt"), Keys.R, 1, 1, true, 'hold',
        { timedeventhash = "MEDIUM_TIMED_EVENT" })        --Register your first prompt

    local deathText = LocalesAPI.translate(0, "death_text")
    local deathTimerText = LocalesAPI.translate(0, "death_timer")

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

                    if Config.Character.death.cameraRotation == true then
                        StartDeathCam()
                    end

                    startDeathTimer()

                    RPCAPI.Call("CharacterDeath", 1)
                end

                -- For some reason the prompt is flashing 
                if deathTimer > 0 then
                    deadPromptGroup:ShowGroup(tostring(deathTimer) .. " " .. deathTimerText)
                    deadPrompt:EnabledPrompt(false)
                else
                    deadPromptGroup:ShowGroup(deathText)

                    -- Check if player is being carried
                    if IsEntityAttachedToAnyPed(player) then
                        -- TODO: Test this to make sure the camera follows.
                        deadPrompt:EnabledPrompt(false)
                    else
                        deadPrompt:EnabledPrompt(true)
                        if deadPrompt:HasCompleted() then
                            deadInitiated = false
                            respawnPlayer()
                        end
                    end
                end

                if Config.Character.death.cameraRotation == true then
                    ProcessCamControls()
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
    DisplayRadar(true)
    TriggerServerEvent("Feather:Character:Spawned", character)
end)

RegisterNetEvent("Feather:Character:Revive", function()
    revivePlayer()
end)

--TODO: Have this re-initiate Character select
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
