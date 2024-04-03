------- File Information --------
-- inspired by Wagonfix
-- OG Script: https://github.com/kaddarem-tebex/RedM-FixWagon
-----------------------------------

function StartWagonFix()
    CreateThread(function()
        local vehiclePool = {}
        local wagon = 0
        local driver = 0
        local horse = 0
        while true do
            vehiclePool = GetGamePool('CVehicle') -- Get the list of vehicles (entities) from the pool
            for i = 1, #vehiclePool do -- loop through each vehicle (entity)
                wagon = vehiclePool[i]
                -- Is wagon stopped
                if IsEntityAVehicle(wagon) and IsVehicleStopped(wagon) then
                    -- Get the horse
                    horse = Citizen.InvokeNative(0xA8BA0BAE0173457B,wagon,0)
                    -- If vehicle stopped but the horse walks = buggy wagon
                    if IsPedWalking(horse) then
                        if not IsEntityAMissionEntity(wagon) then --if the wagon is not a mission entity. Peds spawned naturally by game return false, peds created by script return true by default preventing this from deleting entities intentionally spawned by scripts
                            -- Delete driver & wagon
                            driver = Citizen.InvokeNative(0x2963B5C1637E8A27,wagon)
                            if driver ~= PlayerPedId() then -- Ensure the driver is not a player
                                if driver then
                                    DeleteEntity(driver) -- Delete driver from wagon if there is one
                                end
                                DeleteEntity(wagon) -- Delete buggy wagon
                            end
                        end
                    end
                end
            end
            Wait(1000)
        end
    end)
end