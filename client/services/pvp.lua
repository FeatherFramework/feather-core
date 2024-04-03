-- TODO: Test this thouroughly
PVPAPI = {}
PVPAPI.active = Config.PVP
PVPAPI.pause = Config.pause
PVPAPI.playerhash = joaat("PLAYER")

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

        local isPlayerOutOfVehicle = not IsPedOnMount(PlayerPed) and not IsPedInAnyVehicle(PlayerPed, false)
        local isPlayerDriver = IsPedOnMount(playerPed) or IsPedInAnyVehicle(playerPed, false)
        if isPlayerOutOfVehicle or isPlayerDriver then
            PVPAPI:setPause(false)
        end

        PVPAPI:updatePVPRelationship()
    end
end)