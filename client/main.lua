-- TODO: Create a system (when character logic is added) to hide or enact a loadscreen 
-- while interiors and everything loads (essentially need to keep track of when the core is fully loaded and "ready")

ClientReady = false

function RunCore()
    StartAPI()
    StartPopulationDensity()
    StartInteriorsFix()
    StartCharacterEssentials()
    


    ClientReady = true
end
RunCore()

-- AddEventHandler('playerSpawned', function()

-- end)