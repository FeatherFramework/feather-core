MathI = {}

function MathI:instanced()
    local inst = {
        usedInts = {}
    }

    function inst:GetRandomInt(exclude)
        local rando = math.random(1, 2000)
    
        while self.usedInts[rando] and random >= 0 do
            rando = math.random(1, 2000)
            Citizen.Wait(1)
        end
    
        return rando
    end

    return inst
end
