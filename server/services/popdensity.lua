------- File Information --------
-- inspired by popdensity by kibook
-- OG Script: https://github.com/kibook/popdensity
-----------------------------------
local densityMultipliers = Config.densityMultipliers

RegisterNetEvent("bcc:popdensity:sync")
AddEventHandler("bcc:popdensity:sync", function()
	TriggerClientEvent("bcc:popdensity:clientsync", source, densityMultipliers)
end)