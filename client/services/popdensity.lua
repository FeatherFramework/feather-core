-- Code is taken from and inspired by https://github.com/kibook/popdensity

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

function SetupDensities(multipliers)
    while true do
		if SetPedDensityMultiplierThisFrame then
			-- FiveM
			SetPedDensityMultiplierThisFrame(multipliers.ambientPeds)
			SetScenarioPedDensityMultiplierThisFrame(multipliers.scenarioPeds, multipliers.scenarioPeds)
		else
			-- RedM
			SetAmbientAnimalDensityMultiplierThisFrame(multipliers.ambientAnimals)
			SetAmbientHumanDensityMultiplierThisFrame(multipliers.ambientHumans)
			SetAmbientPedDensityMultiplierThisFrame(multipliers.ambientPeds)
			SetScenarioAnimalDensityThisFrame(multipliers.scenarioAnimals)
			SetScenarioHumanDensityThisFrame(multipliers.scenarioHumans)
			SetScenarioPedDensityMultiplierThisFrame(multipliers.scenarioPeds)
		end

		SetParkedVehicleDensityMultiplierThisFrame(multipliers.parkedVehicles)
		SetRandomVehicleDensityMultiplierThisFrame(multipliers.randomVehicles)
		SetVehicleDensityMultiplierThisFrame(multipliers.vehicles)

		Citizen.Wait(0)
	end
end


RegisterNetEvent("bcc:popdensity:clientsync")
AddEventHandler("bcc:popdensity:clientsync", SetupDensities)

function StartPopulationDensity()
    Citizen.CreateThread(function()
        TriggerServerEvent("bcc:popdensity:sync")
    end)
end