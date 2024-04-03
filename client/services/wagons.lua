--[[
  This class is to provide an API for developers to interface with vehicles of any kind. Some of the class methods will not apply to all vehicles.
  Please review the documentation around the specific vehicle model you are using when making calls to the API.

  In the Feather Core API Documentation there are links to the available options for these methods. (if known)
  If there is anything not added that you'd like to have added please open an issue on GitHub, Submit a PR, or contact us in discord.
]]

WagonsAPI = {}

function WagonsAPI:Create(modelHash, x, y, z, heading, safeground, networked, vector4)
  local WagonClass = {}

  if not x and not y and not z and not heading then
    x, y, z, heading = table.unpack(vector4)
  end

  if CheckVar(safeground, true) then
    local groundCheck, ground = nil, nil
    for height = 1, 1000 do
      groundCheck, ground = GetGroundZAndNormalFor_3dCoord(x, y, height + 0.0)
      if groundCheck then
        break
      end
    end
    z = ground
  end

  local hash
  if type(modelHash) == "string" then
    hash = joaat(modelHash)
    if not Citizen.InvokeNative(0xB9D5BDDA88E1BB66, hash) then
      error('The provide model is not a draft vehicle.')
      return
    end
  end

  exports['feather-core'].LoadModel(hash)

  WagonClass.Wagon = CreateVehicle(hash, x, y, z, heading, networked, false, false, false)
  Citizen.InvokeNative(0x7263332501E07F52, WagonClass.Wagon, true)
  SetModelAsNoLongerNeeded(hash)

  function WagonClass:Freeze(state)
    Citizen.InvokeNative(0x7D9EFB7AD6B19754, self.Wagon, CheckVar(state, true))
  end

  function WagonClass:SetBlip(title, blipHash)
    blipHash = CheckVar(blipHash, -1749618580)
    if type(blipHash) == 'string' then
      blipHash = joaat(blipHash)
    end

    local blip = Citizen.InvokeNative(0x23F74C2FDA6E7C61, blipHash, self.Wagon)
    Citizen.InvokeNative(0x74F74D3207ED525C, blip, blipHash, true)
    Citizen.InvokeNative(0x9CB1A1623062F402, blip, CheckVar(title, 'MyWagon'))

    return blip
  end

  function WagonClass:SetTag(title)
    local tag = Citizen.InvokeNative(0xE961BF23EAB76B12, self.Wagon, CheckVar(title, 'MyWagon'))
    Citizen.InvokeNative(0x5F57522BC1EB9D9D, tag, joaat('PLAYER_HORSE'))
    Citizen.InvokeNative(0xA0D7CE5F83259663, tag)
    return tag
  end

  function WagonClass:SetTagVisibility(tag, state)
    Citizen.InvokeNative(0x93171DDDAB274EB8, tag, CheckVar(state, 2))
  end

  function WagonClass:IsTagActive(tag)
    Citizen.InvokeNative(0x502E1591A504F843, tag, self.Wagon)
  end

  function WagonClass:IsVehicleSeatFree(seat)
    return Citizen.InvokeNative(0xE052C1B1CAA4ECE4, self.Wagon, CheckVar(seat, -1))
  end

  function WagonClass:SetPedOwnsVehicle(ped)
    Citizen.InvokeNative(0x838C216C2B05A009, self.Wagon, CheckVar(ped, PlayerPedId()))
  end

  function WagonClass:SetPlayerOwnsVehicle(ped)
    Citizen.InvokeNative(0xD0E02AA618020D17, self.Wagon, CheckVar(ped, PlayerPedId()))
  end

  function WagonClass:SetEntityHeading(heading)
    Citizen.InvokeNative(0xCF2B9C0645C4651B, self.Wagon, CheckVar(heading, GetEntityHeading(PlayerPedId())))
  end

  -- Test
  -- https://github.com/femga/rdr3_discoveries/blob/master/vehicles/vehicle_modding/vehicle_propsets.lua
  function WagonClass:AddPropSet(propSet)
    if not propSet or propSet == 0 then
      error('propSet is required')
      return
    end

    if type(propSet) == 'string' then
      propSet = joaat(propSet)
    end

    Citizen.InvokeNative(0xD80FAF919A2E56EA, propSet, 0)
  end

  -- Test
  -- https://github.com/femga/rdr3_discoveries/blob/master/vehicles/vehicle_modding/vehicle_propsets.lua
  function WagonClass:AddAdditionalPropSet(propSet)
    if not propSet or propSet == 0 then
      error('propSet is required')
      return
    end

    if type(propSet) == 'string' then
      propSet = joaat(propSet)
    end

    Citizen.InvokeNative(0x75F90E4051CC084C, self.Wagon, propSet)
  end

  -- https://github.com/femga/rdr3_discoveries/blob/master/vehicles/vehicle_modding/vehicle_lantern_propsets.lua
  function WagonClass:AddLightPropSet(propSet)
    if not propSet or propSet == 0 then
      error('propSet is required')
      return
    end

    if type(propSet) == 'string' then
      propSet = joaat(propSet)
    end

    Citizen.InvokeNative(0xC0F0417A90402742, self.wagon, propSet)
  end

  function WagonClass:SetVehicleTarpHeight(height)
    Citizen.InvokeNative(0x31F343383F19C987, self.Wagon, CheckVar(tonumber(height), 0), true)
  end

  function WagonClass:IsVehiclePropSetLoaded()
    return Citizen.InvokeNative(0x7264F9CA87A9830B, self.Wagon)
  end

  function WagonClass:IsVehiclePropSetApplied()
    return Citizen.InvokeNative(0xD798DF5DB67B1659, self.Wagon)
  end

  function WagonClass:IsVehicleLightPropSetLoaded()
    return Citizen.InvokeNative(0x0790473EEE1977D3, self.Wagon)
  end

  function WagonClass:RemoveAllPropSets()
    Citizen.InvokeNative(0x75F90E4051CC084C, self.Wagon, 0)
  end

  function WagonClass:RemoveAllLightPropSets()
    Citizen.InvokeNative(self.Wagon)
  end

  function WagonClass:AreSeatsFree()
    return Citizen.InvokeNative(0xA0A424505A1B6429, self.Wagon)
  end

  function WagonClass:HaltVehicle(distance, duration)
    Citizen.InvokeNative(0x260BE8F09E326A20, CheckVar(distance, 20), CheckVar(duration, 30), false)
  end

  function WagonClass:IsVehicleHalted()
    return Citizen.InvokeNative(0x404527BC03DA0E6C, self.Wagon)
  end

  function WagonClass:GetActiveLivery()
    return Citizen.InvokeNative(0xBB765B8FD49A796C, self.Wagon)
  end

  -- https://github.com/femga/rdr3_discoveries/blob/master/vehicles/vehicle_modding/vehicle_liveries.lua
  function WagonClass:SetVehicleLivery(index)
    Citizen.InvokeNative(0xF89D82A0582E46ED, self.Wagon, tonumber(index))
  end

  function WagonClass:GetActiveTint()
    return Citizen.InvokeNative(0xA44D65E6C624526F, self.Wagon)
  end

  function WagonClass:SetTint(tint)
    Citizen.InvokeNative(0x8268B098F6FCA4E2, self.Wagon, tonumber(tint))
  end

  function WagonClass:GetMaxPassengers()
    return Citizen.InvokeNative(0xA9C55F1C15E62E06, self.Wagon)
  end

  function WagonClass:GetOwner()
    return Citizen.InvokeNative(0xB729679356A889AE, self.Wagon)
  end

  function WagonClass:SetYokeCanBreak(value)
    Citizen.InvokeNative(0x226C6A4E3346D288, self.Wagon, CheckVar(value, true))
  end

  function WagonClass:LockPassengerSeats(value)
    Citizen.InvokeNative(0xECB9E9BC887E8060, CheckVar(value, false))
  end

  function WagonClass:SetVehicleVisibleDamage(value)
    Citizen.InvokeNative(0x4BF8131AE811541C, self.Wagon, CheckVar(value, true))
  end

  function WagonClass:SetVehicleCanBreak(value)
    Citizen.InvokeNative(0xC5ED9D59B4646611, self.Wagon, CheckVar(value, true))
  end

  -- 0.0 to 1.0
  function WagonClass:SetDirtLevel(value)
    Citizen.InvokeNative(0xBAE0EEDF93F05EAA, self.Wagon, CheckVar(value, 0))
  end

  -- 0.0 to 1.0
  function WagonClass:SetMudLevel(value)
    Citizen.InvokeNative(0x4D15E49764CB328A, self.Wagon, CheckVar(value, 0))
  end

  -- 0.0 to 1.0
  function WagonClass:SetSnowLevel(value)
    Citizen.InvokeNative(0x6F73EFAB11651D7F, self.Wagon, CheckVar(value, 0))
  end

  -- 0.0 to 1.0
  function WagonClass:SetWetLevel(value)
    Citizen.InvokeNative(0x5AABB09F6FBD1F87, self.Wagon, CheckVar(value, 0))
  end

  -- https://github.com/femga/rdr3_discoveries/blob/master/vehicles/vehicle_modding/vehicle_extras.lua
  function WagonClass:AddVehicleExtra(extra)
    Citizen.InvokeNative(0xBB6F89150BC9D16B, self.Wagon, tonumber(extra), 0)
  end

  function WagonClass:RemoveVehicleExtra(extra)
    Citizen.InvokeNative(0xBB6F89150BC9D16B, self.Wagon, tonumber(extra), 1)
  end

  function WagonClass:FixVehicle()
    SetVehicleFixed(self.Wagon)
  end

  function WagonClass:SetStrongAxels(state)
    Citizen.InvokeNative(0x252253C8A45AA1FC, self.Wagon, CheckVar(state, true))
  end

  function WagonClass:SetStrongVehicle(state)
    Citizen.InvokeNative(0xAB315515C9F8803D, self.Wagon, CheckVar(state, true))
  end

  function WagonClass:ExplodeVehicle(isAudible, isInvisible)
    Citizen.InvokeNative(0x75DCED9EEC5769D7, self.Wagon, CheckVar(isAudible, true), CheckVar(isInvisible, false))
  end

  function WagonClass:GetWheelsDestroyed()
    return Citizen.InvokeNative(0x18714953CCED17D3, self.Wagon)
  end

  function WagonClass:Remove()
    DeleteEntity(self.Wagon)
  end

  function WagonClass:GetWagon()
    return self.Wagon
  end

  return WagonClass
end
