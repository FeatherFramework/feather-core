-- Neutral client safeguards that apply for the entire connection. Character
-- lifecycle, position persistence, death, and respawn belong to domain
-- resources and are deliberately absent from this Core runtime.

local function PreventWeaponSoftlock()
    DisableControlAction(0, 0x7DA48D2A, true)
    DisableControlAction(0, 0x9CC7A1A4, true)
    Citizen.InvokeNative(0xFC094EF26DD153FA, 2)
end

local function DisableFrameworkHudControls()
    DisableControlAction(0, 0x580C4473, true)
    DisableControlAction(0, 0xCF8A4ECA, true)
    DisableControlAction(0, 0x9CC7A1A4, true)
    DisableControlAction(0, 0x1F6D95E5, true)
end

function StartPlayerRuntime()
    EventsAPI:RegisterEventListener('EVENT_CHALLENGE_GOAL_COMPLETE', ClearUIFeed)
    EventsAPI:RegisterEventListener('EVENT_CHALLENGE_REWARD', ClearUIFeed)
    EventsAPI:RegisterEventListener('EVENT_DAILY_CHALLENGE_STREAK_COMPLETED', ClearUIFeed)

    CreateThread(function()
        while true do
            if Config.DisableRandomLootPrompts then DisableRandomLootPrompt() end
            DisableFrameworkHudControls()
            PreventWeaponSoftlock()
            Wait(1)
        end
    end)
end
