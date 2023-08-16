BlipAPI = {}

function BlipAPI:SetBlip(name, sprite, scale, x, y, z)
    local BlipClass = {}

    BlipClass.rawblip =  Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, vector3(x, y, z))
    BlipClass.x = x
    BlipClass.y = y
    BlipClass.z = z
    BlipClass.RadiusBlip = nil
    
    if type(sprite) == "string" then
        sprite = joaat(sprite)
    end
    SetBlipSprite(BlipClass.rawblip, sprite, true)
    SetBlipScale(BlipClass.rawblip, scale)
    Citizen.InvokeNative(0x9CB1A1623062F402, BlipClass.rawblip, name)

    function BlipClass:Get()
        return self.rawblip
    end

    function BlipClass:Remove()
        RemoveBlip(self.rawblip)
        self.rawblip = nil
        if self.RadiusBlip then
            RemoveBlip(self.RadiusBlip)
            self.RadiusBlip = nil
        end
    end

    function BlipClass:AddRadius(radius, hash)
        self.RadiusBlip = Citizen.InvokeNative(0x45f13b7e0a15c880, -1282792512, self.x, self.y, self.z, radius)
        if hash then
         Citizen.InvokeNative(0x74F74D3207ED525C, self.RadiusBlip, hash, true)
        end
    end

    return BlipClass
end

function BlipAPI:RemoveBlip(blip)
    RemoveBlip(blip)
end

function BlipAPI:AddRadius(radius, x, y, z, hash)
    return Citizen.InvokeNative(0x45f13b7e0a15c880, hash or -1282792512, x, y, z, radius)
end
