-- Thin wrapper over LoadResourceFile/SaveResourceFile for reading/writing a
-- resource's own files (JSON or raw text, per the `mode` param).
FilesAPI = {}

-- (CORE-12) `IsEmpty`/`CheckMode` were referenced below but never defined
-- anywhere in the repo -- every FilesAPI function errored at runtime.
-- `mode == 'json'` is the only mode this file's callers were ever written
-- against (json.encode/decode below), so that's the contract made explicit
-- here. (`MiscAPI`, the other half of CORE-12, is defined in
-- shared/services/api.lua so it exists on both client and server.)
function IsEmpty(str)
    return str == nil or str == ""
end

function CheckMode(mode)
    return mode == "json"
end

-- Returns a FileClass bound to a specific resource+path, with Read/Save/
-- Update methods (see below) so repeated operations on the same file don't
-- need to re-pass resourcename/filepath every time.
function FilesAPI:Open(resourcename, filepath)
    if IsEmpty(resourcename) or IsEmpty(filepath) then
        print("You must have a resource name and filepath defined!")
        return {}
    end
    
    
    local FileClass = {}
    FileClass.ResourceName = resourcename
    FileClass.FilePath = filepath

    function FileClass:Read(mode)
        local filedata = LoadResourceFile(self.ResourceName, self.FilePath)

        if CheckMode(mode) then
            filedata = json.decode(filedata)
        end

        return filedata
    end

    function FileClass:Save(content, mode, dataLenght)
        if CheckMode(mode) then
            content = json.encode(content)
        end

        SaveResourceFile(self.ResourceName, self.FilePath, content,dataLenght)
    end

    function FileClass:Update(content, mode, dataLenght)
        local filedata =  LoadResourceFile(self.ResourceName, self.FilePath)

        if CheckMode(mode) then
            local table = json.decode(filedata)
            table[#table+1] = content
            filedata = json.encode(table)
        else
            filedata = filedata .. content
        end

        SaveResourceFile(self.ResourceName, self.FilePath, filedata,dataLenght )
    end

    return FileClass
end

-- Lazy functions, not as optimized
function FilesAPI:Load(resourcename, filepath, mode)
    local file = FilesAPI:Open(resourcename, filepath)
    return file:Read(mode)
end

function FilesAPI:Save(resourcename, filepath, content, mode)
    local file = FilesAPI:Open(resourcename, filepath)
    file:Save(content, mode)
end

function FilesAPI:Update(resourcename, filepath, content, mode)
    local file = FilesAPI:Open(resourcename, filepath)
    file:Update(content, mode)
end