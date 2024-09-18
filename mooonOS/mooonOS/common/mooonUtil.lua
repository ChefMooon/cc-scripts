-- mooonOS/fileUtil V1.0.0
-- Created by: ChefMooon

----- PROGRAM TODO -----
--- file more util

local fileUtil = {}

function fileUtil.getBasalt(path)
    if not (fs.exists(path)) then
        shell.run("wget run https://basalt.madefor.cc/install.lua release basalt-1.7.1.lua " .. path)
    end
    return require(path:gsub(".lua",""))
end

function fileUtil.getFilenameFromPath(path)
    return path:gsub("^.*/", ""):gsub(".lua", "")
end

function fileUtil.getProgram(string)
    return require(string:gsub(".lua",""))
end

-- Function to download a file from a URL
function fileUtil.downloadFile(url, destination)
    local parent = fs.getDir(destination) -- Get the parent directory
    if not fs.exists(parent) then
        fs.makeDir(parent) -- Create the directory if it doesn't exist
    end

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

-- Function to delete a file
function fileUtil.deleteFile(filePath)
    local msg = ""
    if fs.exists(filePath) then
        fs.delete(filePath)
        msg = "Deleted: "..filePath
        return true, msg
    else
        return false, msg
    end
end

return fileUtil