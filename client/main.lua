function RunCore()
    StartAPI()
    StartPopulationDensity()
    StartInteriorsFix()
end
RunCore()

AddEventHandler('playerSpawned', function()

end)