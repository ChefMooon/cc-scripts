-- digOSUpdate V0.1.0
-- Created by: ChefMooon

--PROGRAM TODO--
-- 

-- Variables --
local programName = "digOSUpdate.lua"
local programVersion = "1.0.0"

local searchPattern = "digOS.*"
local programSearchPattern = "digOSUpdate.*"

local digOSPrograms = {
    {filename = "digOS.lua", url = "https://raw.githubusercontent.com/ChefMooon/cc-scripts/main/digOS/main/digOS.lua" },
    {filename = "digOS-mid-out.lua", url = "https://raw.githubusercontent.com/ChefMooon/cc-scripts/main/digOS/digPrograms/digOS-mid-out.lua" },
    {filename = "digOSRemote.lua", url = "https://raw.githubusercontent.com/ChefMooon/cc-scripts/main/digOS/main/digOSRemote.lua" }
}

-- Function to list all files in a directory
local function listFiles(directory)
    if directory == nil then
        directory = ""
    end
    local files = fs.list(directory)
    local programs = {}

    for _, file in ipairs(files) do
        if not fs.isDir(fs.combine(directory, file)) then
            table.insert(programs, file)
        end
    end

    return programs
end

-- Function to delete a file
local function deleteFile(filePath)
    local msg = ""
    if fs.exists(filePath) then
        fs.delete(filePath)
        msg = "Deleted: "..filePath
        return true, msg
    else
        return false, msg
    end
end

-- Function to download a file from a URL
local function downloadFile(url, destination)
    local msg = ""
    local response = http.get(url)
    if response then
        local file = fs.open(destination, "w")
        file.write(response.readAll())
        file.close()
        response.close()
        msg = "Downloaded: "..destination
        return true, msg
    else
        msg = "Failed to download: "..url
        return false, msg
    end
end

-- Main function to find and delete programs containing "digOS" and re-download them
local function digOSUpdate()
    term.clear()
    print("Initializing DigOSUpdate...\n")

    -- List all files in the programs directory
    local programs = listFiles()
    local matchingPrograms = {}

    print("Searching for DigOS programs...")
    -- Iterate through the list of programs
    for _, program in ipairs(programs) do
        if string.find(program, searchPattern) then
            if not string.find(program, programSearchPattern) then
                -- Delete programs containing "digOS"
                table.insert(matchingPrograms, program)
                print("Found: ", program)
                --local programPath = fs.combine(program)
            end
        end
    end

    if #matchingPrograms > 0 then
        print("\nUpdating digOS Programs")
    end
    for _, program in ipairs(matchingPrograms) do
        for _, digOSProgram in ipairs(digOSPrograms) do
            if (program == digOSProgram.filename) then
                local deleteResult, deleteMsg = deleteFile(program)
                if deleteResult then
                    local downloadResult, downloadMsg = downloadFile(digOSProgram.url, digOSProgram.filename)
                    if downloadResult then
                        print(program, "... Update Complete.")
                    end
                end
            end
        end
    end
end

digOSUpdate()