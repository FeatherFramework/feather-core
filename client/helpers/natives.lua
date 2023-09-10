function SetAmbientAnimalDensityMultiplierThisFrame(multiplier)
	Citizen.InvokeNative(0xC0258742B034DFAF, multiplier)
end

function SetAmbientHumanDensityMultiplierThisFrame(multiplier)
	Citizen.InvokeNative(0xBA0980B5C0A11924, multiplier)
end

function SetAmbientPedDensityMultiplierThisFrame(multiplier)
	Citizen.InvokeNative(0xAB0D553FE20A6E25, multiplier)
end

function SetScenarioAnimalDensityThisFrame(multiplier)
	Citizen.InvokeNative(0xDB48E99F8E064E56, multiplier)
end

function SetScenarioHumanDensityThisFrame(multiplier)
	Citizen.InvokeNative(0x28CB6391ACEDD9DB, multiplier)
end

function SetAttributeCoreValue(player, type, val)
    Citizen.InvokeNative(0xC6258F41D86676E0, player, type, val)
end

function RestorePedStamina(player, val)
    Citizen.InvokeNative(0x675680D089BFA21F, player, 1065330373)
end

function GuarmaCheck(player)
    if Citizen.InvokeNative(0x43AD8FC02B429D33, GetEntityCoords(player), 10) == -512529193 then
        Citizen.InvokeNative(0xA657EC9DBC6CC900, 1935063277) -- SetMinimapZone
        Citizen.InvokeNative(0xE8770EE02AEE45C2, 1)          -- SetWorldWaterType
        Citizen.InvokeNative(0x74E2261D2A66849A, true)       -- SetGuarmaWorldhorizonActive
    end
end

function SetEagleEye(player, state)
    Citizen.InvokeNative(0xA63FCAD3A6FEC6D2, player, state)
end

function SetDeadEye(player, state)
    Citizen.InvokeNative(0x95EE1DEE1DCD9070, player, state)
end

function ClearUIFeed()
    Citizen.InvokeNative(0x6035E8FBCA32AC5E) --UiFeedClearAllChannels
end

function DisableRandomLootPrompt()
    -- Disable random loot prompts
    Citizen.InvokeNative(0xFC094EF26DD153FA, 2)
end