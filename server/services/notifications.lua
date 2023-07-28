SNotifyAPI = {}

function SNotifyAPI.ToolTip(src, text, duration)
    TriggerClientEvent("bcc:notify", src, text, duration)
end

function SNotifyAPI.AdvancedNotify(src, title, text, dict, icon, duration, color)
    TriggerClientEvent("bcc:notify", src, title, text, dict, icon, duration, color)
end

function SNotifyAPI.LocationNotify(src, text, location, duration)
    TriggerClientEvent("bcc:notify", src, text, location, duration)
end

function SNotifyAPI.RightNotify(src, text, duration)
    TriggerClientEvent("bcc:notify", src, text, duration)
end

function SNotifyAPI.LeftNotify(src, text, duration)
    TriggerClientEvent("bcc:notify", src, text, duration)
end

function SNotifyAPI.TopBanner(src, title, text, duration)
    TriggerClientEvent("bcc:notify", src, title, text, duration)
end

function SNotifyAPI.AdvancedRightNotify(src, text, dict, icon, color, duration, quality)
    TriggerClientEvent("bcc:notify", src, text, dict, icon, color, duration, quality)
end

function SNotifyAPI.TopNotify(src, text, duration)
    TriggerClientEvent("bcc:notify", src, text, duration)
end

function SNotifyAPI.CenterNotify(src, text, duration, color)
    TriggerClientEvent("bcc:notify", src, text, duration, color)
end

function SNotifyAPI.Notify(src, text, duration)
    TriggerClientEvent("bcc:notify", src, text, duration)
end

function SNotifyAPI.BottomRightNotify(src, text, duration)
    TriggerClientEvent("bcc:notify", src, text, duration)
end

function SNotifyAPI.MissionFailed(src, title, text, duration)
    TriggerClientEvent("bcc:notify", src, title, text, duration)
end

function SNotifyAPI.DeadPlayer(src, text, audiosource, audioname, duration)
    TriggerClientEvent("bcc:notify", src, text, audiosource, audioname, duration)
end

function SNotifyAPI.WarnNotify(src, title, text, audiosource, audioname, duration)
    TriggerClientEvent("bcc:notify", src, title, text, audiosource, audioname, duration)
end
