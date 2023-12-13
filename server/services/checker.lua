VersionerAPI = {}

VersionerAPI.checkRelease = function(resourcename, repo)
    repo = repo:gsub("https://github.com/", "")

    local current = {
        version = GetResourceMetadata(resourcename, 'version')
    }

    PerformHttpRequest('https://api.github.com/repos/' .. repo .. '/releases/latest', function(err, text, headers)
        local response = json.decode(text)

        if response.html_url == nil then
            print('^3⚠️No Release Found! ^5[' .. resourcename .. '] ^6(Version ' .. current.version .. ')^0')
        else
            local latest = {
                url = response.html_url,
                body = response.body,
                version = response.tag_name
            }
            local uptodate = false
            local overdate = false

            if current.version > latest.version then
                overdate = true
            elseif current.version < latest.version then
                uptodate = false
            else
                uptodate = true
            end

            if uptodate then
                print('^2✅Up to Date! ^5[' .. resourcename .. '] ^6(Current Version ' .. current.version .. ')^0')
            elseif overdate then
                print('^3⚠️Unsupported! ^5[' .. resourcename .. '] ^6(Version ' .. current.version .. ')^0')
                print('^4Current Version ^2(' .. latest.version .. ') ^3<' .. latest.url .. '>^0')
            else
                print('^1❌Outdated! ^5[' .. resourcename .. '] ^6(Version ' .. current.version .. ')^0')
                print('^4NEW VERSION ^2(' .. latest.version .. ') ^3<' .. latest.url .. '>^0')
                print('^4CHANGELOG ^0\r\n' .. latest.body)
            end
        end
    end, 'GET', json.encode(payload), {
        ['Content-Type'] = 'application/json'
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

            if current.version > latest.version then
                overdate = true
            elseif current.version < latest.version then
                uptodate = false
            else
                uptodate = true
            end

            if uptodate then
                print('^2✅Up to Date! ^5[' .. resourcename .. '] ^6(Current Version ' .. current.version .. ')^0')
            elseif overdate then
                print('^3⚠️Unsupported! ^5[' .. resourcename .. '] ^6(Version ' .. current.version .. ')^0')
                print('^4Current Version ^2(' .. latest.version .. ') ^3<' .. latest.url .. '>^0')
            else
                print('^1❌Outdated! ^5[' .. resourcename .. '] ^6(Version ' .. current.version .. ')^0')
                print('^4NEW VERSION ^2(' .. latest.version .. ') ^3<' .. latest.url .. '>^0')

                local cl = latest.body:gsub("<" .. current.version .. ">.*", "")
                print('^CHANGELOG ^0\r\n' .. cl)
            end
        end, 'GET', json.encode(payload), {
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
    Citizen.CreateThread(function()
        local ResourceCount = GetNumResources()
        for i = 1, ResourceCount - 1, 1 do
            local resource = GetResourceByFindIndex(i)
            CheckForUpdate(resource)
            CheckForUIRelease(resource)
        end
    end)
end
