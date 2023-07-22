-- Removes events and challenge notfications
--TODO: MIGRATE THIS TO USE THE EVENT HANDLER
-- Citizen.CreateThread(function()
--     while true do
--         Citizen.Wait(10)
--         local size = GetNumberOfEvents(0)
--         if size > 0 then
--             for i = 0, size - 1 do
--                 local eventAtIndex = GetEventAtIndex(0, i)
--                 if eventAtIndex == GetHashKey("EVENT_CHALLENGE_GOAL_COMPLETE") or eventAtIndex == GetHashKey("EVENT_CHALLENGE_REWARD") or eventAtIndex == GetHashKey("EVENT_DAILY_CHALLENGE_STREAK_COMPLETED") then 
--                     Citizen.InvokeNative(0x6035E8FBCA32AC5E) --UiFeedClearAllChannels
--                 end
--             end
--         end
--     end
-- end)



-- Make player sit and read book while in pause menu
-- local PauseOpen = false

-- Citizen.CreateThread(function()
--     while true do
--         Wait(0)
--         local ped = PlayerPedId()
--         if IsPauseMenuActive() and not PauseOpen then
--             SetCurrentPedWeapon(ped, 0xA2719263, true) -- set unarmed
--             SetCurrentPedWeapon(ped, GetHashKey("weapon_unarmed"))
--             if not IsPedOnMount(ped) then
--                 TaskStartScenarioInPlace(PlayerPedId(), GetHashKey("WORLD_HUMAN_SIT_GROUND_READING_BOOK"), -1, true, "StartScenario", 0, false)
--             end
--             PauseOpen = true
--         end

--         if not IsPauseMenuActive() and PauseOpen then
--             ClearPedTasks(ped)
--             Wait(4000)
--             SetCurrentPedWeapon(ped, 0xA2719263, true) -- set unarmed
--             SetCurrentPedWeapon(ped, GetHashKey("weapon_unarmed"))
--             PauseOpen = false
--         end
--     end
-- end)