-- Startup version checker: for every OTHER currently-loaded resource that
-- opts in via its fxmanifest (`github_version_check`), fetches the latest
-- GitHub release/version file and logs whether it's current, outdated, or
-- ahead of the published release. Purely informational (console logging),
-- never blocks startup. Driven by StartVersioner() at the bottom, called
-- once from RunCore().
VersionerAPI = {}

-- (CORE-25) Was a plain string comparison (current.version > latest.version)
-- in both checkRelease and checkFile below, which is a lexical compare, not
-- semver -- "0.9.0" > "0.10.0" is true lexically even though 0.10.0 is the
-- newer release. Compares dot-separated numeric segments left to right
-- instead; a missing/non-numeric segment is treated as 0 so uneven lengths
-- ("1.2" vs "1.2.1") and stray prefixes/suffixes ("v1.2.0", "1.2.0-beta")
-- degrade gracefully rather than erroring.
-- @return -1 if a < b, 0 if equal, 1 if a > b
local function CompareVersions(a, b)
    a, b = tostring(a or ''), tostring(b or '')
    local aParts, bParts = {}, {}
    for part in a:gmatch('%d+') do aParts[#aParts + 1] = tonumber(part) end
    for part in b:gmatch('%d+') do bParts[#bParts + 1] = tonumber(part) end

    for i = 1, math.max(#aParts, #bParts) do
        local av, bv = aParts[i] or 0, bParts[i] or 0
        if av ~= bv then return av < bv and -1 or 1 end
    end
    return 0
end

VersionerAPI.checkRelease = function(resourcename, repo)
    repo = repo:gsub("https://github.com/", "")

    local current = {
        version = GetResourceMetadata(resourcename, 'version')
    }

    PerformHttpRequest('https://api.github.com/repos/' .. repo .. '/releases/latest', function(err, text, headers)
        local response = json.decode(text)

        if err == 403 then
            print('^3⚠️ Version Check limit reached. This should resolve in a few minutes. You are safe to ignore this. ^5[' .. resourcename .. '] ^6(Version ' .. current.version .. ')^0')
            return
        end

        if response.html_url == nil then
            print('^3⚠️ No Release Found! ^5[' .. resourcename .. '] ^6(Version ' .. current.version .. ')^0')
        else
            local latest = {
                url = response.html_url,
                body = response.body,
                version = response.tag_name
            }
            local uptodate = false
            local overdate = false

            local cmp = CompareVersions(current.version, latest.version)
            if cmp > 0 then
                overdate = true
            elseif cmp < 0 then
                uptodate = false
            else
                uptodate = true
            end

            if uptodate then
                print('^2✅ Up to Date! ^5[' .. resourcename .. '] ^6(Current Version ' .. current.version .. ')^0')
            elseif overdate then
                print('^3⚠️ Unsupported! ^5[' .. resourcename .. '] ^6(Version ' .. current.version .. ')^0')
                print('^4Current Version ^2(' .. latest.version .. ') ^3<' .. latest.url .. '>^0')
            else
                print('^1❌ Outdated! ^5[' .. resourcename .. '] ^6(Version ' .. current.version .. ')^0')
                print('^4NEW VERSION ^2(' .. latest.version .. ') ^3<' .. latest.url .. '>^0')
                print('^4CHANGELOG ^0\r\n' .. latest.body)
            end
        end
    end, 'GET', json.encode({}), {
        ['Content-Type'] = 'application/json',
        ['User-Agent'] = 'request'
    })
end

VersionerAPI.checkFile = function(resourcename, repo)
    local cleanrepo = repo:gsub("https://github.com/", "")

    local current = {
        version = GetResourceMetadata(resourcename, 'version')
    }
    PerformHttpRequest('https://raw.githubusercontent.com/' .. cleanrepo .. '/main/version',
        function(err, response, headers)
            local v = response:match("<%d?%d.%d?%d.?%d?%d?>"):gsub("[<>]", "")
            local latest = {
                url = repo,
                body = response,
                version = v
            }
            local uptodate = false
            local overdate = false

            local cmp = CompareVersions(current.version, latest.version)
            if cmp > 0 then
                overdate = true
            elseif cmp < 0 then
                uptodate = false
            else
                uptodate = true
            end

            if uptodate then
                print('^2✅ Up to Date! ^5[' .. resourcename .. '] ^6(Current Version ' .. current.version .. ')^0')
            elseif overdate then
                print('^3⚠️ Unsupported! ^5[' .. resourcename .. '] ^6(Version ' .. current.version .. ')^0')
                print('^4Current Version ^2(' .. latest.version .. ') ^3<' .. latest.url .. '>^0')
            else
                print('^1❌ Outdated! ^5[' .. resourcename .. '] ^6(Version ' .. current.version .. ')^0')
                print('^4NEW VERSION ^2(' .. latest.version .. ') ^3<' .. latest.url .. '>^0')

                local cl = latest.body:gsub("<" .. current.version .. ">.*", "")
                print('^CHANGELOG ^0\r\n' .. cl)
            end
        end, 'GET', json.encode({}), {
        ['Content-Type'] = 'application/json'
    })
end

local function CheckForUpdate(resource)
    local ActiveCheck = GetResourceMetadata(resource, 'github_version_check', 0)

    if ActiveCheck == 'true' then
        local resourcename = GetResourceMetadata(resource, 'name', 0)
        local github = GetResourceMetadata(resource, 'github_link', 0)
        local githubtype = GetResourceMetadata(resource, 'github_version_type', 0)
        if not githubtype then
            githubtype = "release"
        end

        if githubtype == "release" then
            VersionerAPI.checkRelease(resourcename, github)
        elseif githubtype == "file" then
            VersionerAPI.checkFile(resourcename, github)
        end
    end
end

local function CheckForUIRelease(resource)
    local CheckUI = GetResourceMetadata(resource, 'github_ui_check', 0)

    if CheckUI == 'true' then
        local resourcename = GetResourceMetadata(resource, 'name', 0)
        local repo = GetResourceMetadata(resource, 'github_link', 0)

        local f = LoadResourceFile(resourcename, './ui/index.html')
        if not f then
            print("^1 INCORRECT DOWNLOAD!  ^0")
            print('^4 Please Download: ^2(' .. resourcename .. '.zip) ^4from ^3<' .. repo .. '/releases/latest>^0')
        end
    end
end

function StartVersioner()
    CreateThread(function()
        local ResourceCount = GetNumResources()
        for i = 1, ResourceCount - 1, 1 do
            local resource = GetResourceByFindIndex(i)
            CheckForUpdate(resource)
            CheckForUIRelease(resource)
        end
    end)
end
