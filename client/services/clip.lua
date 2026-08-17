-- Sends clipboard requests through the Core NUI. Clipboard access belongs to
-- the embedded browser and is not exposed as a RedM game native.
ClipAPI = {}

function ClipAPI.CopyToClipboard(text)
    text = tostring(text or '')
    if text == '' then return false end

    SendNUIMessage({
        type = 'clipboard',
        text = text
    })
    return true
end
