NotifyAPI = {}

RegisterNetEvent("Feather:Notify")
AddEventHandler("Feather:Notify", function(type, ...)
    NotifyAPI[type](...)
end)

function NotifyAPI.ToolTip(text, duration)
    local vartext = Citizen.InvokeNative(0xFA925AC00EB830B9, 10, "LITERAL_STRING", text, Citizen.ResultAsLong())
    local optionscontent = DataView.ArrayBuffer(8 * 7)
    local inputtext = DataView.ArrayBuffer(8 * 3)

    optionscontent:SetUint32(8 * 0, duration)
    optionscontent:SetInt32(8 * 1, 0)
    optionscontent:SetInt32(8 * 2, 0)
    optionscontent:SetInt32(8 * 3, 0)
    inputtext:SetUint64(8 * 1, DataView.BigInt(vartext))

    Citizen.InvokeNative(0x049D5C615BD38BAD, optionscontent:Buffer(), inputtext:Buffer(), 1)
end

function NotifyAPI.AdvancedNotify(title, text, dict, icon, duration, color)
    local optionscontent = DataView.ArrayBuffer(8 * 7)
    optionscontent:SetInt32(8 * 0, duration)

    local maincontent = DataView.ArrayBuffer(8 * 8)

    local vartitle = Citizen.InvokeNative(0xFA925AC00EB830B9, 10, "LITERAL_STRING", title, Citizen.ResultAsLong())
    local vartext = Citizen.InvokeNative(0xFA925AC00EB830B9, 10, "LITERAL_STRING", text, Citizen.ResultAsLong())

    maincontent:SetInt64(8 * 1, DataView.BigInt(vartitle))
    maincontent:SetInt64(8 * 2, DataView.BigInt(vartext))
    maincontent:SetInt32(8 * 3, 0)
    maincontent:SetInt64(8 * 4, DataView.BigInt(GetHashKey(dict)))
    maincontent:SetInt64(8 * 5, DataView.BigInt(GetHashKey(icon)))
    maincontent:SetInt64(8 * 6, DataView.BigInt(GetHashKey(color or "COLOR_WHITE")))

    Citizen.InvokeNative(0x26E87218390E6729, optionscontent:Buffer(), maincontent:Buffer(), 1, 1)
end

function NotifyAPI.LocationNotify(text, location, duration)
    local varloc = Citizen.InvokeNative(0xFA925AC00EB830B9, 10, "LITERAL_STRING", location, Citizen.ResultAsLong())

    local vartext = Citizen.InvokeNative(0xFA925AC00EB830B9, 10, "LITERAL_STRING", text, Citizen.ResultAsLong())

    local optionscontent = DataView.ArrayBuffer(8 * 7)
    optionscontent:SetInt32(8 * 0, duration)

    local maincontent = DataView.ArrayBuffer(8 * 5)
    maincontent:SetInt64(8 * 1, DataView.BigInt(varloc))
    maincontent:SetInt64(8 * 2, DataView.BigInt(vartext))

    Citizen.InvokeNative(0xD05590C1AB38F068, optionscontent:Buffer(), maincontent:Buffer(), 0, 1)
end

function NotifyAPI.RightNotify(text, duration)
    local vartext = Citizen.InvokeNative(0xFA925AC00EB830B9, 10, "LITERAL_STRING", text, Citizen.ResultAsLong())

    local optionscontent = DataView.ArrayBuffer(8 * 7)
    optionscontent:SetInt32(8 * 0, duration)

    local maincontent = DataView.ArrayBuffer(8 * 3)
    maincontent:SetInt64(8 * 1, DataView.BigInt(vartext))

    Citizen.InvokeNative(0xB2920B9760F0F36B, optionscontent:Buffer(), maincontent:Buffer(), 1)
end

function NotifyAPI.LeftNotify(text, duration)
    Citizen.InvokeNative("0xDD1232B332CBB9E7", 3, 1, 0)
    local vartext = Citizen.InvokeNative(0xFA925AC00EB830B9, 10, "LITERAL_STRING", text, Citizen.ResultAsLong())

    local optionscontent = DataView.ArrayBuffer(8 * 7)
    optionscontent:SetInt32(8 * 0, duration)

    local maincontent = DataView.ArrayBuffer(8 * 3)
    maincontent:SetInt64(8 * 1, DataView.BigInt(vartext))

    Citizen.InvokeNative(0xCEDBF17EFCC0E4A4, optionscontent:Buffer(), maincontent:Buffer(), 1)
end

function NotifyAPI.TopBanner(title, text, duration)
    local optionscontent = DataView.ArrayBuffer(8 * 7)
    optionscontent:SetInt32(8 * 0, duration)

    local vartitle = Citizen.InvokeNative(0xFA925AC00EB830B9, 10, "LITERAL_STRING", title, Citizen.ResultAsLong())
    local vartext = Citizen.InvokeNative(0xFA925AC00EB830B9, 10, "LITERAL_STRING", text, Citizen.ResultAsLong())

    local maincontent = DataView.ArrayBuffer(8 * 7)
    maincontent:SetInt64(8 * 1, DataView.BigInt(vartitle))
    maincontent:SetInt64(8 * 2, DataView.BigInt(vartext))
    Citizen.InvokeNative(0xA6F4216AB10EB08E, optionscontent:Buffer(), maincontent:Buffer(), 1, 1)
end

function NotifyAPI.AdvancedRightNotify(text, dict, icon, color, duration, quality)
    local vartext = Citizen.InvokeNative(0xFA925AC00EB830B9, 10, "LITERAL_STRING", text, Citizen.ResultAsLong())
    local vardict = Citizen.InvokeNative(0xFA925AC00EB830B9, 10, "LITERAL_STRING", dict, Citizen.ResultAsLong())

    local varsounddict = Citizen.InvokeNative(0xFA925AC00EB830B9, 10, "LITERAL_STRING", "Transaction_Feed_Sounds",
        Citizen.ResultAsLong())
    local varsound = Citizen.InvokeNative(0xFA925AC00EB830B9, 10, "LITERAL_STRING", "Transaction_Positive",
        Citizen.ResultAsLong())

    local optionscontent = DataView.ArrayBuffer(8 * 7)
    optionscontent:SetInt32(8 * 0, duration)
    optionscontent:SetInt64(8 * 1, DataView.BigInt(varsounddict))
    optionscontent:SetInt64(8 * 2, DataView.BigInt(varsound))

    local maincontent = DataView.ArrayBuffer(8 * 10)
    maincontent:SetInt64(8 * 1, DataView.BigInt(vartext))
    maincontent:SetInt64(8 * 2, DataView.BigInt(vardict))
    maincontent:SetInt64(8 * 3, DataView.BigInt(GetHashKey(icon)))
    maincontent:SetInt64(8 * 5, DataView.BigInt(GetHashKey(color or "COLOR_WHITE")))
    maincontent:SetInt32(8 * 6, quality or 1)

    Citizen.InvokeNative(0xB249EBCB30DD88E0, optionscontent:Buffer(), maincontent:Buffer(), 1)
end

function NotifyAPI.TopNotify(text, duration)
    local optionscontent = DataView.ArrayBuffer(8 * 7)
    optionscontent:SetInt32(8 * 0, duration)

    local vartext = Citizen.InvokeNative(0xFA925AC00EB830B9, 10, "LITERAL_STRING", text, Citizen.ResultAsLong())

    local maincontent = DataView.ArrayBuffer(8 * 7)
    maincontent:SetInt64(8 * 1, DataView.BigInt(vartext))

    Citizen.InvokeNative(0x860DDFE97CC94DF0, optionscontent:Buffer(), maincontent:Buffer(), 1)
end

function NotifyAPI.CenterNotify(text, duration, color)
    local optionscontent = DataView.ArrayBuffer(8 * 7)
    optionscontent:SetInt32(8 * 0, duration)

    local vartext = Citizen.InvokeNative(0xFA925AC00EB830B9, 10, "LITERAL_STRING", text, Citizen.ResultAsLong())

    local maincontent = DataView.ArrayBuffer(8 * 4)
    maincontent:SetInt64(8 * 1, DataView.BigInt(vartext))
    maincontent:SetInt64(8 * 2, DataView.BigInt(GetHashKey(color or "COLOR_PURE_WHITE"))) --TODO: Check if this can be used in all the basic notifies, if so add color
    Citizen.InvokeNative(0x893128CDB4B81FBB, optionscontent:Buffer(), maincontent:Buffer(), 1)
end

function NotifyAPI.Notify(text, duration)
    local optionscontent = DataView.ArrayBuffer(8 * 3)
    optionscontent:SetInt32(8 * 0, duration)

    local vartext = Citizen.InvokeNative(0xFA925AC00EB830B9, 10, "LITERAL_STRING", text, Citizen.ResultAsLong())

    local maincontent = DataView.ArrayBuffer(8 * 6)
    maincontent:SetInt64(8 * 1, DataView.BigInt(vartext))
    maincontent:SetInt64(8 * 2, DataView.BigInt(vartext))

    Citizen.InvokeNative(0xC927890AA64E9661, optionscontent:Buffer(), maincontent:Buffer(), 1, 1)
end

function NotifyAPI.BottomRightNotify(text, duration)
    local optionscontent = DataView.ArrayBuffer(8 * 7)
    optionscontent:SetInt32(8 * 0, duration)

    local vartext = Citizen.InvokeNative(0xFA925AC00EB830B9, 10, "LITERAL_STRING", text, Citizen.ResultAsLong())

    local maincontent = DataView.ArrayBuffer(8 * 5)
    maincontent:SetInt64(8 * 1, DataView.BigInt(vartext))

    Citizen.InvokeNative(0x2024F4F333095FB1, optionscontent:Buffer(), maincontent:Buffer(), 1)
end

function NotifyAPI.MissionFailed(title, text, duration)
    local vartitle = Citizen.InvokeNative(0xFA925AC00EB830B9, 10, "LITERAL_STRING", title, Citizen.ResultAsLong())
    local vartext = Citizen.InvokeNative(0xFA925AC00EB830B9, 10, "LITERAL_STRING", text, Citizen.ResultAsLong())
    
    local optionscontent = DataView.ArrayBuffer(8 * 5)

    local maincontent = DataView.ArrayBuffer(8 * 9)
    maincontent:SetInt64(8 * 1, DataView.BigInt(vartitle))
    maincontent:SetInt64(8 * 2, DataView.BigInt(vartext))
    
    local notify = Citizen.InvokeNative(0x9F2CC2439A04E7BA, optionscontent:Buffer(), maincontent:Buffer(), 1)
    
    Wait(tonumber(duration) or 3000)
    
    Citizen.InvokeNative(0x00A15B94CBA4F76F, notify)
end

function NotifyAPI.DeadPlayer(text, audiosource, audioname, duration)
    local vartext = Citizen.InvokeNative(0xFA925AC00EB830B9, 10, "LITERAL_STRING", text, Citizen.ResultAsLong())
    local varaudiosource = Citizen.InvokeNative(0xFA925AC00EB830B9, 10, "LITERAL_STRING", audiosource, Citizen.ResultAsLong())
    local varaudioname = Citizen.InvokeNative(0xFA925AC00EB830B9, 10, "LITERAL_STRING", audioname, Citizen.ResultAsLong())

    local optionscontent = DataView.ArrayBuffer(8 * 5)
    optionscontent:SetInt64(8 * 0, DataView.BigInt(varaudiosource))
    optionscontent:SetInt64(8 * 1, DataView.BigInt(varaudioname))
    optionscontent:SetInt16(8 * 2, 4)

    local maincontent = DataView.ArrayBuffer(8 * 9)
    maincontent:SetInt64(8 * 1, DataView.BigInt(vartext))

    local notify = Citizen.InvokeNative(0x815C4065AE6E6071, optionscontent:Buffer(), maincontent:Buffer(), 1)
    
    Wait(tonumber(duration) or 3000)
    
    Citizen.InvokeNative(0x00A15B94CBA4F76F, notify)
end

function NotifyAPI.WarnNotify(title, text, audiosource, audioname, duration)
    local vartitle = Citizen.InvokeNative(0xFA925AC00EB830B9, 10, "LITERAL_STRING", title, Citizen.ResultAsLong())
    local vartext = Citizen.InvokeNative(0xFA925AC00EB830B9, 10, "LITERAL_STRING", text, Citizen.ResultAsLong())
    local varaudiosource = Citizen.InvokeNative(0xFA925AC00EB830B9, 10, "LITERAL_STRING", audiosource, Citizen.ResultAsLong())
    local varaudioname = Citizen.InvokeNative(0xFA925AC00EB830B9, 10, "LITERAL_STRING", audioname, Citizen.ResultAsLong())

    local optionscontent = DataView.ArrayBuffer(8 * 5)
    optionscontent:SetInt64(8 * 0, DataView.BigInt(varaudiosource))
    optionscontent:SetInt64(8 * 1, DataView.BigInt(varaudioname))
    optionscontent:SetInt16(8 * 2, 4)

    local maincontent = DataView.ArrayBuffer(8 * 9)
    maincontent:SetInt64(8 * 2, DataView.BigInt(vartitle))
    maincontent:SetInt64(8 * 3, DataView.BigInt(vartext))

    local notify = Citizen.InvokeNative(0x339E16B41780FC35, optionscontent:Buffer(), maincontent:Buffer(), 1)

    Wait(tonumber(duration) or 3000)

    Citizen.InvokeNative(0x00A15B94CBA4F76F, notify)
end
