MathI = {}

function MathI:instanced()
    local inst = {
        usedInts = {}
    }

    -- (CORE-18) `usedInts` was never written to, so the collision-avoidance
    -- loop below checked an always-empty table -- two concurrent
    -- InstanceAPI.create(nil) calls could land on the same id and corrupt
    -- each other's membership tracking. Now marks the id used before
    -- returning it; callers that free an id (InstanceAPI.leave, once its
    -- instance is torn down) should call inst:ReleaseInt(id) so the 1-2000
    -- range doesn't slowly exhaust.
    function inst:GetRandomInt()
        local rando = math.random(1, 2000)

        while self.usedInts[rando] do
            rando = math.random(1, 2000)
            Wait(1)
        end

        self.usedInts[rando] = true
        return rando
    end

    function inst:ReleaseInt(value)
        self.usedInts[value] = nil
    end

    return inst
end