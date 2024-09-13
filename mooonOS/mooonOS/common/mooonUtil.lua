-- mooonOS/fileUtil V1.0.0
-- Created by: ChefMooon

----- PROGRAM TODO -----
--- file more util

local fileUtil = {}

-- Function to download a file from a URL
function fileUtil.downloadFile(url, destination)
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