-- Client-side character lifecycle: spawn-in, the death/respawn loop, and
-- position sync. `ActiveSystems` flags gate the three long-running
-- CreateThread loops below (EssentialsLoop/setupCharacterMenuIdle/
-- startPositionSync) so /logout can cleanly stop them without leaving
-- orphaned threads running for a character that's no longer active.
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

-- Resets the ped to a healthy, controllable state after death (health,
-- cores, stamina, camera) and tells the server the character is alive
-- again via the CharacterDeath RPC (state 0). Called both from the normal
-- respawnPlayer() flow and directly by the server-pushed
-- Feather:Character:Revive event.
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
    RestorePedStamina(player, 100.0)

    if Config.Character.death.cameraRotation == true then
        EndDeathCam()
    end

    RPCAPI.Call("CharacterDeath", 0)

    TriggerServerEvent('Feather:Character:Revived')
end

-- Finds the nearest configured respawn point (Config.RespawnLocations) and
-- moves the ped there via TeleportAPI:ToCoords (client/services/teleport.lua),
-- which handles surface/ground detection and collision streaming.
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
    -- (CORE-28) Was a naive upward ground-probe (z=1..1000, one unit at a
    -- time), which stops at the FIRST solid surface it crosses -- often a
    -- dock, bridge, or floor slab below the real outdoor terrain -- instead
    -- of the actual ground, and silently does nothing if the real terrain
    -- sits above z=1000. TeleportAPI:ToCoords (this same resource's own
    -- client/services/teleport.lua, already used by feather-admin's
    -- teleport tooling) does this properly: it streams the destination first
    -- and requires repeated downward raycasts to agree on the topmost surface.
    -- fade=false because respawnPlayer() (the only caller) has already
    -- faded to black and fades back in itself via hoursLaterDisplay().
    TeleportAPI:ToCoords(hospital.coords, {
        entity = player,
        heading = hospital.heading,
        mode = 'surface',
        streamTimeout = 10000,
        surfaceTimeout = 10000,
        settleTimeout = 10000,
        fade = false
    })
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

-- While the pause menu is open, disarms the ped and plays a sit-and-read
-- idle animation (skipped if mounted); reverts back to unarmed/no-anim once
-- the menu closes. Purely cosmetic, gated by Config.IdleAnimation.
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


-- Runs every tick while a character is spawned: disables loot-prompt spam
-- (if configured), hides parts of the HUD/UI cards, and blocks the weapon
-- wheel controls that are known to soft-lock input if left enabled. Started
-- once from StartCharacterEssentials(), stopped by /logout via
-- ActiveSystems.spawn.
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
-- Periodically reports the ped's current world position to the server via
-- the UpdatePlayerCoords RPC, which persists it to the character row (see
-- feather-core's CORE-05 note: this is trusted verbatim server-side, no
-- speed/bounds sanity check). Interval is Config.PositionSync (ms).
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

-- The core death/respawn loop: polls IsEntityDead every tick. On first
-- detecting death, hides HUD/radar, starts the death camera + countdown
-- timer, and tells the server (CharacterDeath RPC, state 1). While the
-- countdown is running the player can only watch; once it hits 0 a "hold R"
-- prompt appears (skipped if being carried) and completing it triggers
-- respawnPlayer(). Runs for the lifetime of the spawned character.
local function DeadCheck()
    local deadPromptGroup = PromptsAPI:SetupPromptGroup() --Setup Prompt Group
    local deadPrompt = deadPromptGroup:RegisterPrompt(LocalesAPI.translate(0, "death_prompt"), Keys.R, 1, 1, true, 'hold',
        { timedeventhash = "MEDIUM_TIMED_EVENT" })        --Register your first prompt

    local deathText = LocalesAPI.translate(0, "death_text")
    local deathTimerText = LocalesAPI.translate(0, "death_timer")

    -- (CORE-29) DeadCheck() is called once per spawn (see the
    -- "Feather:Character:Spawn" handler below), and its `while true do`
    -- loop had no exit condition -- every respawn/character-switch left the
    -- previous call's loop running forever in the background, permanently
    -- polling IsEntityDead every tick. `Feather:Character:Logout` already
    -- fires on logout; this loop now stops itself on the next logout after
    -- it started, so only the current spawn's loop is ever alive.
    local stopped = false
    local stopHandler
    stopHandler = AddEventHandler('Feather:Character:Logout', function()
        stopped = true
        RemoveEventHandler(stopHandler)
    end)

    local deadInitiated = false
    CreateThread(function()
        while not stopped do
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
-- Server-pushed once CharacterAPI.InitiateCharacter succeeds (see
-- server/services/character.lua). Places the ped at the character's saved
-- coords via TeleportAPI:ToCoords (client/services/teleport.lua), waits for
-- interiors/maps/core to finish loading, starts the position-sync and
-- death-watch loops, and finally re-broadcasts Feather:Character:Spawned
-- both to the server (so other resources like feather-weapons/
-- feather-inventory can react) and locally on the client.
-- `character.dead == 1` replays the death state if they logged out dead.
RegisterNetEvent("Feather:Character:Spawn", function(character)
    DoScreenFadeOut(2000)

    Citizen.InvokeNative(0x1E5B70E53DB661E5, 0, 0, 0, LocalesAPI.translate(0, "loadscreen_title"),
        LocalesAPI.translate(0, "loadscreen_subtitle"), LocalesAPI.translate(0, "loadscreen_signature"))

    local player = PlayerPedId()

    local x = tonumber(character.x)
    local y = tonumber(character.y)
    local z = tonumber(character.z)

    if x == nil or y == nil or z == nil then
        print(('[feather-core] Cannot spawn character %s: invalid saved coordinates (%s, %s, %s)'):format(
            tostring(character.id or 'unknown'),
            tostring(character.x),
            tostring(character.y),
            tostring(character.z)
        ))
        ShutdownLoadingScreen()
        DoScreenFadeIn(500)
        return
    end

    -- (CORE-28) `first_spawn` (see controllers/characters.lua, cleared
    -- one-shot by InitiateCharacter) tells a brand-new character's very
    -- first placement -- a designer-picked town coordinate from
    -- feather-character's creation flow, which may need surface-correction
    -- the same way the hospital respawn locations do -- apart from every
    -- later login, whose saved position was actually occupied (a dock,
    -- porch, upper floor, ...) and must be trusted exactly, never
    -- surface-corrected. fade=false because this handler owns its own
    -- loading-screen/fade choreography around the whole spawn sequence.
    local firstSpawn = tonumber(character.first_spawn) == 1
    local placed = TeleportAPI:ToCoords(vector3(x, y, z), {
        entity = player,
        mode = firstSpawn and 'surface' or 'exact',
        requireNearbySurface = firstSpawn,
        streamTimeout = 10000,
        surfaceTimeout = 10000,
        settleTimeout = 10000,
        fade = false
    })
    if not placed.success then
        print(('[feather-core] Spawn placement for character %s did not complete cleanly: %s'):format(
            tostring(character.id or 'unknown'), tostring(placed.reason)))
    end

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
    TriggerEvent("Feather:Character:Spawned", character)
end)

RegisterNetEvent("Feather:Character:Revive", function()
    revivePlayer()
end)

--TODO: Have this re-initiate Character select
RegisterCommand('logout', function()
    -- Save the final position and flush the character in one request.
    RPCAPI.CallAsync(
        "LogoutCharacter",
        GetEntityCoords(PlayerPedId())
    )

    ActiveCharacter = {}
    ActiveSystems = {
        spawn = false,
        menuidle = false,
        possync = false
    }

    MapAPI.setFOW(true)
    -- Local lifecycle signal for resources that keep character-scoped UI/state.
    TriggerEvent("Feather:Character:Logout")
end, false)
