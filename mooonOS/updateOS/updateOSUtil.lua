local programInfo = {
    name = "updateOSUtil",
    version = "1.0.0",
    author = "ChefMooon"
}



local util = {}



function util.listFiles(directory)
    if directory == nil then
        directory = ""
    end
    local files = fs.list(directory)
    local programs = {}

    for _, file in ipairs(files) do
        local filePath = fs.combine(directory, file)
        if fs.isDir(filePath) then
            local subFiles = fs.list(filePath)
            for _, subFile in ipairs(subFiles) do
                table.insert(programs, subFile)
            end
        else
            table.insert(programs, file)
        end
    end


    return programs
end


function util.mooonOSFiles()
    local files = {}    -- List to store files
    local folders = {}  -- List to store folders to check

    -- Add the starting directory to the folders list
    -- table.insert(folders, "mooonOS/")
    table.insert(folders, "")

    -- While there are still folders to check
    while #folders > 0 do
        -- Remove the first folder from the list and process it
        local currentFolder = table.remove(folders, 1)

        -- Get the list of items (files and folders) in the current folder
        local items = fs.list(currentFolder)

        -- Loop through each item in the directory
        for _, item in ipairs(items) do
            local itemPath = fs.combine(currentFolder, item) -- Get the full path of the item

            if fs.isDir(itemPath) then
                -- If it's a directory, add it to the folders list for later checking
                table.insert(folders, itemPath)
            else
                -- If it's a file, add it to the files list
                table.insert(files, {item = item, itemPath = itemPath})
            end
        end
    end

    -- Return the list of files
    return files
end

function util.getKeysFromFile(file)
    local keyValuePairs = {}
    local line

    if not file then
        return nil
    end
    -- Limit the number of lines to read with maxLines
    for i = 1, 5 do
        line = file.readLine()
        
        -- Break if we've reached the end of the file
        if line == nil then
            break
        end
        
        -- Try to find a key-value pair (format: key = "value")
        local key, value = string.match(line, '(%S+)%s*=%s*"(.-)"')

        -- If a valid pair is found, insert it into the table
        if key and value then
            keyValuePairs[key] = value
        end
    end

    return keyValuePairs
end

function util.getProgramMetadata(program)
    local file = fs.open(program.path, "r")

    local keyValuePairs = util.getKeysFromFile(file)

    file.close()
    return keyValuePairs



    -- if not file then
    --     return nil
    -- end
    -- -- Limit the number of lines to read with maxLines
    -- for i = 1, 5 do
    --     line = file.readLine()
        
    --     -- Break if we've reached the end of the file
    --     if line == nil then
    --         break
    --     end
        
    --     -- Try to find a key-value pair (format: key = "value")
    --     local key, value = string.match(line, '(%S+)%s*=%s*"(.-)"')

    --     -- If a valid pair is found, insert it into the table
    --     if key and value then
    --         keyValuePairs[key] = value
    --     end
    -- end
    
    -- file.close()
    -- return keyValuePairs
end

function util.getLatestProgramMetaData(program, data)
    local latestMetaData = http.get(program.url)
    if latestMetaData then
        local latestData = util.getKeysFromFile(latestMetaData)
        latestMetaData.close()

        if latestData.version then
            if data.version then
                if latestData.version > data.version then
                    data.latestVersion = latestData.version
                end
            end
        end
    end

    return data
end

function util.getAllProgramMetaData(program)
    local data = util.getProgramMetadata(program)
    data = util.getLatestProgramMetaData(program, data)
    return data
end

function util.splitVersion(version)
    local major, minor, patch = string.match(version, "(%d+)%.(%d+)%.(%d+)")
    return tonumber(major), tonumber(minor), tonumber(patch)
end

function util.compareVersions(v1, v2)
    if v1 == nil or v2 == nil then
        return 404
    end
    local major1, minor1, patch1 = util.splitVersion(v1)
    local major2, minor2, patch2 = util.splitVersion(v2)

    -- Compare major version
    if major1 > major2 then
        return 1
    elseif major1 < major2 then
        return -1
    end

    -- Compare minor version
    if minor1 > minor2 then
        return 1
    elseif minor1 < minor2 then
        return -1
    end

    -- Compare patch version
    if patch1 > patch2 then
        return 1
    elseif patch1 < patch2 then
        return -1
    end

    -- Versions are equal
    return 0
end

return util