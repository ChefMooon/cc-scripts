local programInfo = {
    name = "mooonOSUtil",
    version = "1.0.0",
    author = "ChefMooon"
}

----- PROGRAM TODO -----
--- mooon more util

local mooonOSUtil = {}

mooonOSUtil.lib = {
    base = {
        mooonUtil = {
            filename = "mooonUtil",
            path = "mooonOS/common/mooonUtil.lua",
            url = "https://raw.githubusercontent.com/ChefMooon/cc-scripts/mooonOS/mooonOS/common/mooonUtil.lua",
            description = "Base utility library"
        },
        basalt = {
            filename = "basalt",
            path = "basalt.lua",
            url = "wget run https://basalt.madefor.cc/install.lua release basalt-1.7.1.lua ",
            description = "Basalt library"
        }
    },
    common = {
        fileOSUtil = {
            filename = "fileOSUtil",
            path = "mooonOS/common/fileOSUtil.lua",
            url = "https://raw.githubusercontent.com/ChefMooon/cc-scripts/mooonOS/mooonOS/common/fileOSUtil.lua",
            description = "File utility library"
        },
        rednetUtil = {
            filename = "rednetUtil",
            path = "mooonOS/common/rednetUtil.lua",
            url = "https://raw.githubusercontent.com/ChefMooon/cc-scripts/mooonOS/mooonOS/common/rednetUtil.lua",
            description = "Rednet utility library"
        },
        settingsUtil = {
            filename = "settingsUtil",
            path = "mooonOS/common/settingsUtil.lua",
            url = "https://raw.githubusercontent.com/ChefMooon/cc-scripts/mooonOS/mooonOS/common/settingsUtil.lua",
            description = "Settings utility library"
        },
        basaltUtil = {
            filename = "basaltUtil",
            path = "mooonOS/common/basaltUtil.lua",
            url = "https://raw.githubusercontent.com/ChefMooon/cc-scripts/mooonOS/mooonOS/common/basaltUtil.lua",
            description = "Basalt utility library"
        }
    },
    main = {
        digOS = {
            filename = "digOS",
            path = "digOS.lua",
            url = "https://raw.githubusercontent.com/ChefMooon/cc-scripts/mooonOS/mooonOS/digOS.lua",
            description = "A program meant to make digging with Turtles easier"
        },
        todoOS = {
            filename = "todoOS",
            path = "todoOS.lua",
            url = "https://raw.githubusercontent.com/ChefMooon/cc-scripts/mooonOS/mooonOS/todoOS.lua",
            description = "A simple Todo List program"
        },
        updateOS = {
            filename = "updateOS",
            path = "updateOS.lua",
            url = "https://raw.githubusercontent.com/ChefMooon/cc-scripts/mooonOS/mooonOS/updateOS.lua",
            description = "Designed to manage all mooonOS files and programs"
        }
    },
    updateOS = {
        updateOSViewHome = {
            filename = "updateOSViewHome",
            path = "mooonOS/updateOS/updateOSViewHome.lua",
            url = "https://raw.githubusercontent.com/ChefMooon/cc-scripts/mooonOS/mooonOS/updateOS/updateOSViewHome.lua",
            description = "Home view for updateOS"
        },
        updateOSViewAdvanced = {
            filename = "updateOSViewAdvanced",
            path = "mooonOS/updateOS/updateOSViewAdvanced.lua",
            url = "https://raw.githubusercontent.com/ChefMooon/cc-scripts/mooonOS/mooonOS/updateOS/updateOSViewAdvanced.lua",
            description = "Advanced view for updateOS"
        },
        updateOSViewSettings = {
            filename = "updateOSViewSettings",
            path = "mooonOS/updateOS/updateOSViewSettings.lua",
            url = "https://raw.githubusercontent.com/ChefMooon/cc-scripts/mooonOS/mooonOS/updateOS/updateOSViewSettings.lua",
            description = "Settings view for updateOS"
        },
        updateOSUtil = {
            filename = "updateOSUtil",
            path = "mooonOS/updateOS/updateOSUtil.lua",
            url = "https://raw.githubusercontent.com/ChefMooon/cc-scripts/mooonOS/mooonOS/updateOS/updateOSUtil.lua",
            description = "Base utility library for updateOS"
        }
    },
    digOS = {
        digOSViewHome = {
            filename = "digOSViewHome",
            path = "mooonOS/digOS/digOSViewHome.lua",
            url = "https://raw.githubusercontent.com/ChefMooon/cc-scripts/mooonOS/mooonOS/digOS/digOSViewHome.lua",
            description = "Home view for digOS"
        },
        digOSViewControl = {
            filename = "digOSViewControl",
            path = "mooonOS/digOS/digOSViewControl.lua",
            url = "https://raw.githubusercontent.com/ChefMooon/cc-scripts/mooonOS/mooonOS/digOS/digOSViewControl.lua",
            description = "Control view for digOS"
        },
        digOSViewSettings = {
            filename = "digOSViewSettings",
            path = "mooonOS/digOS/digOSViewSettings.lua",
            url = "https://raw.githubusercontent.com/ChefMooon/cc-scripts/mooonOS/mooonOS/digOS/digOSViewSettings.lua",
            description = "Settings view for digOS"
        },
        digOSViewInfo = {
            filename = "digOSViewInfo",
            path = "mooonOS/digOS/digOSViewInfo.lua",
            url = "https://raw.githubusercontent.com/ChefMooon/cc-scripts/mooonOS/mooonOS/digOS/digOSViewInfo.lua",
            description = "Info view for digOS"
        },
        digOSUtil = {
            filename = "digOSUtil",
            path = "mooonOS/digOS/digOSUtil.lua",
            url = "https://raw.githubusercontent.com/ChefMooon/cc-scripts/mooonOS/mooonOS/digOS/digOSUtil.lua",
            description = "Base utility library for digOS"
        },
        digUtil = {
            filename = "digUtil",
            path = "mooonOS/common/digUtil.lua",
            url = "https://raw.githubusercontent.com/ChefMooon/cc-scripts/mooonOS/mooonOS/common/digUtil.lua",
            description = "Common dig utility library"
        }
    },
    todoOS = {
        todoOSView = {
            filename = "todoOSView",
            path = "mooonOS/todoOS/todoOSView.lua",
            url = "https://raw.githubusercontent.com/ChefMooon/cc-scripts/mooonOS/mooonOS/todoOS/todoOSView.lua",
            description = "Home view for todoOS"
        },
        todoOSViewInfo = {
            filename = "todoOSViewInfo",
            path = "mooonOS/todoOS/todoOSViewInfo.lua",
            url = "https://raw.githubusercontent.com/ChefMooon/cc-scripts/mooonOS/mooonOS/todoOS/todoOSViewInfo.lua",
            description = "Info view for todoOS"
        },
        todoOSUtil = {
            filename = "todoOSUtil",
            path = "mooonOS/todoOS/todoOSUtil.lua",
            url = "https://raw.githubusercontent.com/ChefMooon/cc-scripts/mooonOS/mooonOS/todoOS/todoOSUtil.lua",
            description = "Base utility library for todoOS"
        }
    }
}

function mooonOSUtil.getBasalt(path)
    if not (fs.exists(path)) then
        shell.run("wget run https://basalt.madefor.cc/install.lua release basalt-1.7.1.lua " .. path)
    end
    return require(path:gsub(".lua",""))
end

function mooonOSUtil.getFilenameFromPath(path)
    return path:gsub("^.*/", ""):gsub(".lua", "")
end

function mooonOSUtil.getProgram(string)
    return require(string:gsub(".lua",""))
end

-- Function to download a file from a URL
function mooonOSUtil.downloadFile(url, destination)
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
function mooonOSUtil.deleteFile(filePath)
    local msg = ""
    if fs.exists(filePath) then
        fs.delete(filePath)
        msg = "Deleted: "..filePath
        return true, msg
    else
        return false, msg
    end
end

function mooonOSUtil.wrapLines(line, maxLength)
    local wrappedLog = {}
    local currentLine = ""
    local words = {}

    for word in line:gmatch("%S+") do
        table.insert(words, word)
    end

    for i = 1, #words do
        local word = words[i]

        if #currentLine + #word + 1 > maxLength then
            table.insert(wrappedLog, currentLine)
            currentLine = word
        else
            if #currentLine > 0 then
                currentLine = currentLine .. " " .. word
            else
                currentLine = word
            end
        end
    end

    if #currentLine > 0 then
        table.insert(wrappedLog, currentLine)
    end

    return wrappedLog
end

function mooonOSUtil.wrapLinesWithIndent(line, maxLength)
    local indent = " "
    local wrappedLog = {}
    local currentLine = ""
    local words = {}

    for word in line:gmatch("%S+") do
        table.insert(words, word)
    end

    for i = 1, #words do
        local word = words[i]

        local currentMaxLength = #wrappedLog > 0 and (maxLength - #indent) or maxLength

        if #currentLine + #word + 1 > currentMaxLength then
            if #wrappedLog > 0 then
                table.insert(wrappedLog, indent .. currentLine)
            else
                table.insert(wrappedLog, currentLine)
            end
            currentLine = word
        else
            if #currentLine > 0 then
                currentLine = currentLine .. " " .. word
            else
                currentLine = word
            end
        end
    end

    if #currentLine > 0 then
        if #wrappedLog > 0 then
            table.insert(wrappedLog, indent .. currentLine)
        else
            table.insert(wrappedLog, currentLine)
        end
    end

    return wrappedLog
end

return mooonOSUtil