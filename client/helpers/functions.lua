function LoadModel(model)
  RequestModel(model)
  while not HasModelLoaded(model) do
    Wait(10)
  end
end
