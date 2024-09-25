local programInfo = {
    name = "fileOSUtil",
    version = "1.0.0",
    author = "ChefMooon"
}



local fileOSUtil = {}

-- Function to download a file from a URL
function fileOSUtil.downloadFile(url, destination)
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
function fileOSUtil.deleteFile(filePath)
    local msg = ""
    if fs.exists(filePath) then
        fs.delete(filePath)
        msg = "Deleted: "..filePath
        return true, msg
    else
        return false, msg
    end
end

return fileOSUtil