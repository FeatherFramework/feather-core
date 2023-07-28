------- File Information --------
-- inspired by popdensity by kibook
-- OG Script: https://github.com/kibook/popdensity
-----------------------------------

function SetupDensities(multipliers)
	print("Starting pop density")
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

function StartPopulationDensity()
    Citizen.CreateThread(function()
		local multipliers = RPCAPI.CallAsync("popdensity:sync")
		SetupDensities(multipliers)
    end)
end