-- Single-purpose wrapper: writes text to the OS clipboard via the native
-- clipboard hook.
ClipAPI = {}

function ClipAPI.CopyToClipboard(text)
    Citizen.InvokeNative(0x6A1738B4323FE2D9, "CLIPBOARD", text)
end