-- TODO: Test this thouroughly
-- Client-local, per-player PVP toggle (see CORE-10 in the Phase 1 audit:
-- there is no server-side PVP authority, each player's friendly-fire state
-- is entirely self-controlled). `pause` auto-suspends PVP for ~4s after
-- mounting/entering a vehicle (native 0xCEFD9220 = the "mount" control) so
-- getting on a horse doesn't instantly flag you hostile mid-mount, and
-- resumes once you're settled in or fully dismounted.
PVPAPI = {}
PVPAPI.active = Config.PVP
PVPAPI.pause = Config.pause
PVPAPI.playerhash = GetHashKey("PLAYER")

-- Applies the current active/pause state to the engine every tick (see the
-- CreateThread loop below) via NetworkSetFriendlyFireOption and the
-- PLAYER-vs-PLAYER relationship group (5 = can fight, 1 = can't).
function PVPAPI:updatePVPRelationship()
    NetworkSetFriendlyFireOption(self.active)
    if not self.pause and self.active then
        SetRelationshipBetweenGroups(5, PVPAPI.playerhash, PVPAPI.playerhash)
    else
        SetRelationshipBetweenGroups(1, PVPAPI.playerhash, PVPAPI.playerhash)
    end
end

function PVPAPI:togglePVP()
    self.active = not self.active
end

function PVPAPI:setPause(active)
    self.pause = active
end

CreateThread(function()
    while true do
        Wait(0)

        --On press of E (getting onto horse)
        if IsControlPressed(0, 0xCEFD9220) then
            PVPAPI:setPause(true)
            Wait(4000)
        end

        local playerPed = PlayerPedId()

        -- (Tier 1 audit sweep) Was the bare global `PlayerPed` (undefined),
        -- not the local `playerPed` defined above -- both natives ran
        -- against nil, so this check never reflected real mount/vehicle
        -- state.
        local isPlayerOutOfVehicle = not IsPedOnMount(playerPed) and not IsPedInAnyVehicle(playerPed, false)
        local isPlayerDriver = IsPedOnMount(playerPed) or IsPedInAnyVehicle(playerPed, false)
        if isPlayerOutOfVehicle or isPlayerDriver then
            PVPAPI:setPause(false)
        end

        PVPAPI:updatePVPRelationship()
    end
end)