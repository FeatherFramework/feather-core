MathI = {}

function MathI:instanced()
    local inst = {
        usedInts = {}
    }

    function inst:GetRandomInt()
        local rando = math.random(1, 2000)

        while self.usedInts[rando] do
            rando = math.random(1, 2000)
            Wait(1)
        end

        return rando
    end

    return inst
end