--This is a helper for loadscreens. Specifically for bcc-loadscreen. https://github.com/BryceCanyonCounty/bcc-loadscreen
-- The loadscreen's own JS polls `isgameinitiated` to know when it's safe to
-- let the player through: `online` flips true the first time playerSpawned
-- fires, `spacebar` flips true once either the player presses space or
-- `online` is already true (a skip/continue prompt).

local online, spacebar, firstSpawn = false, false, true

RegisterNUICallback('isgameinitiated', function(data, cb)
    cb({
        online = online,
        spacebar = spacebar
    })
end)

AddEventHandler('playerSpawned', function()
    if firstSpawn then
        online = true
        firstSpawn = false
    end
end)

CreateThread(function()
    while true do
        Wait(0)
        if Citizen.InvokeNative(0x580417101DDB492F, 0, 0xD9D0E1C0) or online then
            spacebar = true
            break
        end
    end
end)