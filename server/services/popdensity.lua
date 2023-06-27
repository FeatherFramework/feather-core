-- Code is taken from and inspired by https://github.com/kibook/popdensity
local densityMultipliers = Config.densityMultipliers

RegisterNetEvent("bcc:popdensity:sync")
AddEventHandler("bcc:popdensity:sync", function()
	TriggerClientEvent("bcc:popdensity:clientsync", source, densityMultipliers)
end)