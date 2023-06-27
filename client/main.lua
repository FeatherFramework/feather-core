
-- Global Initiators
CoreClientApi = SetupAPI()

exports('initiate',function()
    return CoreClientApi
end)

AddEventHandler('playerSpawned', function()

end)