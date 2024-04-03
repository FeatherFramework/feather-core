function LoadModel(model)
  RequestModel(model)
  while not HasModelLoaded(model) do
    Wait(10)
  end
end
exports('LoadModel', LoadModel)   

----- exports['feather-core'].LoadModel

