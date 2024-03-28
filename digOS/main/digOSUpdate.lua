-- digOSUpdate V0.1.0
-- Created by: ChefMooon

--PROGRAM TODO--
-- Handle files not having .lua the the end?
-- Add Version of each Program
-- Implement "Update All"

local filePath = "basalt.lua"
if not (fs.exists(filePath)) then
    shell.run("wget run https://basalt.madefor.cc/install.lua release basalt-1.7.1.lua " .. filePath)
end
local basalt = require(filePath:gsub(".lua", ""))

-- Variables --
local programName = "digOSUpdate.lua"
local programVersion = "1.0.0"

local searchPattern = "digOS.*"
local programSearchPattern = "digOSUpdate.*"

local workThreadStatus = false -- true:working/false:free

local args = { ... }

local digOSPrograms = {
    {filename = "digOS.lua", url = "https://raw.githubusercontent.com/ChefMooon/cc-scripts/main/digOS/main/digOS.lua", status = "none" },
    {filename = "digOSRemote.lua", url = "https://raw.githubusercontent.com/ChefMooon/cc-scripts/main/digOS/main/digOSRemote.lua", status = "none" },
    {filename = "digOS-mid-out.lua", url = "https://raw.githubusercontent.com/ChefMooon/cc-scripts/main/digOS/digPrograms/digOS-mid-out.lua", status = "none" }
}
local digOSProgram = digOSPrograms[1]

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

local function findMatchingPrograms()
    local programs = listFiles()
    local matchingPrograms = {}

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

    return matchingPrograms
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

local function digOSDownload(_filename)
    for _, digOSProgram in ipairs(digOSPrograms) do
        if _filename == digOSProgram.filename then
            if digOSProgram.status ~= "downloaded" then
                downloadFile(digOSProgram.url, digOSProgram.filename)
            end
        end
    end
end

local function digOSDelete(_filename)
    deleteFile(_filename)
    for _, digOSProgram in ipairs(digOSPrograms) do
        if _filename == digOSProgram.filename then
            digOSProgram.status = "none"
        end
    end
end

local function digOSUpdate(_filename)
    digOSDelete(_filename)
    digOSDownload(_filename)
end

local function digOSUpdateAll()
    local matchingPrograms = findMatchingPrograms()
    for _, program in ipairs(matchingPrograms) do
        digOSUpdate(program)
    end
end

local function updateProgramInfo()
    local programs = listFiles()

    for i=1, #digOSPrograms do
        for _, program in ipairs(programs) do
            if digOSPrograms[i].filename == program then
                digOSPrograms[i].status = "downloaded"
            end
        end
    end
end

local function getIDByFilename(_filename)
    for i=1, #digOSPrograms do
        if _filename == digOSPrograms[i].filename then
            return i
        end
    end
end

----- UTILITY -----

local function buttonClick(_self)
    _self:setBackground(colors.yellow)
end

local function buttonRelease(_self)
    _self:setBackground(colors.gray)
end

---------- **** FRONTEND START **** ----------

local w, h = term.getSize()
local main = basalt.createFrame():setTheme({ FrameBG = colors.lightGray, FrameFG = colors.black })

local workThread = main:addThread()

local sub = {
    main:addFrame():setPosition(1, 2):setSize("{parent.w}", "{parent.h - 1}"),
    main:addFrame():setPosition(1, 2):setSize("{parent.w}", "{parent.h - 1}"):hide(),
}

local function openSubFrame(id)
    if (sub[id] ~= nil) then
        for k, v in pairs(sub) do
            v:hide()
        end
        sub[id]:show()
    end
end

local menubar = main:addMenubar():setScrollable()
    :setSize("{parent.w-8}", 1)
    :onSelect(function(self, event, item)
        openSubFrame(self:getItemIndex())
    end)
    :addItem("Home")
    :addItem("Settings")

local menubarInfoFrame = main:addFrame():setPosition("{parent.w-11}", 1):setSize(11,1):setBackground(colors.gray)

local programLabel = menubarInfoFrame:addLabel():setText(programName:gsub(".lua", "")):setPosition(1,1):setForeground(colors.yellow)

local programsDetailsFrame = sub[1]:addFrame():setPosition(2,2):setSize("{parent.w-2}",8)
local programsLabel = programsDetailsFrame:addLabel():setText("Programs:"):setPosition(1,1)
local programsFrame = programsDetailsFrame:addScrollableFrame():setPosition(1,2):setSize(20,"{parent.h-1}")
local programsList = programsFrame:addList():setPosition(1, 1):setSize("{parent.w}","{parent.h}")

local detailsLabel = programsDetailsFrame:addLabel():setText("Details:"):setPosition("{parent.w-17}",1)
local detailsFrame = programsDetailsFrame:addFrame():setPosition("{parent.w-17}",2):setSize(15,"{parent.h-1}"):setBackground(colors.gray)

local detailsDownloadStatusLabel = detailsFrame:addLabel():setText("n/a"):setPosition(1,1):setSize("{parent.w}",1)

local buttonFrame = sub[1]:addFrame():setPosition(2,11):setSize("{parent.w-4}",1)

local downloadButton = buttonFrame:addButton():setText("Download"):setPosition(2,1):setSize(8,1):onClick(function(self)buttonClick(self)end):onRelease(function(self)buttonRelease(self)end)
local updateButton = buttonFrame:addButton():setText("Update"):setPosition(11,1):setSize(6,1):onClick(function(self)buttonClick(self)end):onRelease(function(self)buttonRelease(self)end)
local deleteButton = buttonFrame:addButton():setText("Delete"):setPosition(18,1):setSize(6,1):onClick(function(self)buttonClick(self)end):onRelease(function(self)buttonRelease(self)end)
local updateAllButton = buttonFrame:addButton():setText("Update All"):setPosition(25,1):setSize(10,1):onClick(function(self)buttonClick(self)end):onRelease(function(self)buttonRelease(self)end)-- TODO: Add a confirm for this?

---------- **** FRONTEND END **** ----------

---------- **** BACKEND START **** ----------

local function updateDetails()
    detailsDownloadStatusLabel:setText(digOSProgram.status)
end

local function initProgramsList()
    for i=1, #digOSPrograms do
        programsList:addItem(digOSPrograms[i].filename)
    end
    updateDetails(digOSPrograms[1].status)
end

programsList:onSelect(function(self, event, item)
    digOSProgram = digOSPrograms[getIDByFilename(tostring(item.text))]
    updateDetails()
end)

local function refreshUI()
    updateProgramInfo()
    updateDetails()
end

local function runDownloadButton()
    workThreadStatus = true
    digOSDownload(digOSProgram.filename)
    refreshUI()
    workThreadStatus = false
end

local function runUpdateButton()
    workThreadStatus = true
    digOSUpdate(digOSProgram.filename)
    refreshUI()
    workThreadStatus = false
end

local function runDeleteButton()
    workThreadStatus = true
    digOSDelete(digOSProgram.filename)
    refreshUI()
    workThreadStatus = false
end

local function runUpdateAllButton()
    workThreadStatus = true
    digOSUpdateAll()
    refreshUI()
    workThreadStatus = false
end

downloadButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        if not workThreadStatus then
            workThread:start(runDownloadButton)
        end
    end
end)

updateButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        if not workThreadStatus then
            workThread:start(runUpdateButton)
        end
    end
end)

deleteButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        if not workThreadStatus then
            workThread:start(runDeleteButton)
        end
    end
end)

updateAllButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        if not workThreadStatus then
            workThread:start(runUpdateAllButton)
        end
    end
end)

---------- **** BACKEND END **** ----------

local function init()
    -- Check to see what is downloaded
    updateProgramInfo()

    initProgramsList()
end

init()

basalt.autoUpdate()