------- File Information --------
-- inspired by popdensity by kibook
-- OG Script: https://github.com/kibook/popdensity
-----------------------------------

RPCAPI.Register("popdensity:sync", function (coords, res, player)
    return res(Config.densityMultipliers)
end)