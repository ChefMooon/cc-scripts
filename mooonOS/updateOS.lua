local programInfo = {
    name = "digOSUpdate",
    version = "0.1.0",
    author = "ChefMooon"
}

--PROGRAM TODO--
-- Change this back to one file? easier to download and delete
--
--Handle files not having .lua the the end?
-- Add Version of each Program
-- Implement "Update All"
-- refactor digOS to updateOS

-- what to display in the details frame
-- name, version, status

-- make a button that can check what the latest versions of each program are
    -- have a .txt file that contains the latest version of each program in the github repo
-- OR
-- make a button to check the selected programs current version against the latest version on github
    -- add sub button to check/update all programs

-- test Can-update functionality, test performance, maybe add a button to check instead of doing it automatically

-- add to advanced view to show all sub files of each program
-- also show the saved data of each program if they are in .txt format. allow for the deleteion of these files
    -- add button to remove all program saved data

-- check if startup program exists and is one of the mooonOS programs
-- add button to set the startup program
    -- check if the program is downloaded, if not download and set as startup program
    -- if downloaded, rename as startup program

local defaultTheme = {
    background = colors.gray,
    foreground = colors.yellow,
    rednetOn = colors.red,
    rednetOff = colors.black,
    networkTrue = colors.black,
    networkFalse = colors.lightGray,
    savedDataTrue = colors.yellow,
    savedDataFalse = colors.black,
    downloadStatusTrue = colors.green,
    downloadStatusFalse = colors.red
}

local lib = {
    base = {
        mooonUtil = {
            path = "mooonOS/common/mooonUtil.lua",
            url = "https://raw.githubusercontent.com/ChefMooon/cc-scripts/mooonOS/mooonOS/common/mooonUtil.lua"
        }
    }
}

if not (fs.exists(lib.base.mooonUtil.path)) then
    shell.run("wget " .. li.base.mooonUtil.url .. " " .. lib.base.mooonUtil.path)
end
local mooonUtil = require(lib.base.mooonUtil.path:gsub(".lua", ""))
local basalt = mooonUtil.getBasalt(mooonUtil.lib.base.basalt.path)

local fileOSUtil = mooonUtil.getProgram(mooonUtil.lib.common.fileOSUtil.path)
local basaltUtil = mooonUtil.getProgram(mooonUtil.lib.common.basaltUtil.path)

local updateOSUtil = mooonUtil.getProgram(mooonUtil.lib.updateOS.updateOSUtil.path)

local viewHome = mooonUtil.getProgram(mooonUtil.lib.updateOS.updateOSViewHome.path)
local viewAdvanced = mooonUtil.getProgram(mooonUtil.lib.updateOS.updateOSViewAdvanced.path)
local viewSettings = mooonUtil.getProgram(mooonUtil.lib.updateOS.updateOSViewSettings.path)

-- Need to import mooonUtil.lib programs, on startup while checking if each program is downloaded add a status to them if one does not exist 

-- Variables --
local searchPattern = "digOS.*"
local programSearchPattern = "digOSUpdate.*"

local workThreadStatus = false -- true:working/false:free

local digOSProgram = nil
local digOSProgramMetadata = nil

local args = { ... }

local digOSPrograms = mooonUtil.lib.main
for _, program in pairs(digOSPrograms) do
    program.status = false
end

for _, program in pairs(digOSPrograms) do
    digOSProgram = program
    break
end

local function findMatchingPrograms()
    local programs = updateOSUtil.mooonOSFiles()
    local matchingPrograms = {}

    for _, program in pairs(programs) do
        if not string.find(program:gsub(".lua",""), programSearchPattern) then
            table.insert(matchingPrograms, program)
            print("Found: ", program)
        end
    end

    return matchingPrograms
end

local function digOSDownload(program)
    if not digOSPrograms[program.filename].status then
        if fileOSUtil.downloadFile(digOSPrograms[program.filename].url, digOSPrograms[program.filename].path) then
            digOSPrograms[program.filename].status = true
        end
    end
end

local function digOSDelete(program)
    if fileOSUtil.deleteFile(program.path) and digOSPrograms[program.filename] then
        digOSPrograms[program.filename].status = false
    end
end

local function digOSUpdate(program)
    digOSDelete(program)
    digOSDownload(program)
end

local function digOSUpdateAll()
    local matchingPrograms = findMatchingPrograms()
    for _, program in ipairs(matchingPrograms) do
        digOSUpdate(program)
    end
end

local function updateProgramInfo()
    local programs = updateOSUtil.mooonOSFiles()

    for _, digOSProgram in pairs(digOSPrograms) do
        for _, program in pairs(programs) do
            if digOSProgram.filename == tostring(program.item:gsub(".lua","")) then
                digOSProgram.status = true
            end
        end
    end
end

local function getIDByFilename(filename)
    for i=1, #digOSPrograms do
        if filename == digOSPrograms[i].filename then
            return i
        end
    end
end

----- UTILITY -----

local function buttonClick(self)
    self:setBackground(colors.yellow)
end

local function buttonRelease(self)
    self:setBackground(colors.gray)
end

---------- **** FRONTEND START **** ----------

local w, h = term.getSize()
local main = basalt.createFrame():setTheme({ FrameBG = colors.lightGray, FrameFG = colors.black })

local workThread = main:addThread()

local sub = {
    main:addFrame():setPosition(1, 2):setSize("{parent.w}", "{parent.h - 1}"),
    main:addFrame():setPosition(1, 2):setSize("{parent.w}", "{parent.h - 1}"):hide(),
    main:addFrame():setPosition(1, 2):setSize("{parent.w}", "{parent.h - 1}"):hide()
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
    :addItem("Advanced")
    :addItem("Settings")

local menubarInfoFrame = main:addFrame():setPosition("{parent.w-11}", 1):setSize(11,1):setBackground(colors.gray)

local programLabel = menubarInfoFrame:addLabel():setText(programInfo.name:gsub(".lua", "")):setPosition(1,1):setForeground(colors.yellow)

viewHome.init(sub[1], defaultTheme)

viewAdvanced.init(sub[2], defaultTheme)

viewSettings.init(sub[3], defaultTheme)

---------- **** FRONTEND END **** ----------

---------- **** BACKEND START **** ----------

local function updateSelectedProgramInfo()
    digOSProgramMetadata = updateOSUtil.getAllProgramMetaData(digOSProgram)
    local upToDateStatus = updateOSUtil.compareVersions(digOSProgramMetadata.latestVersion, digOSProgramMetadata.version)
    wrappedDescription = mooonUtil.wrapLines(digOSProgram.description, 15) 
    viewHome.updateProgramDetails(digOSProgram, upToDateStatus, wrappedDescription, digOSProgramMetadata, defaultTheme)
end

local function initProgramsList()
    for _, program in pairs(digOSPrograms) do
        viewHome.main.programList:addItem(program.filename)
    end
    updateSelectedProgramInfo()
end

viewHome.main.programList:onSelect(function(self, event, item)
    digOSProgram = digOSPrograms[tostring(item.text)]
    updateSelectedProgramInfo()
end)

local function refreshUI()
    updateProgramInfo()
    updateSelectedProgramInfo()
end

--- I could turn these 4 functions into one function that takes a parameter to determine what to do, but I shall decide later
local function runDownloadButton()
    if not workThreadStatus then
        workThreadStatus = true
        digOSDownload(digOSProgram)
        refreshUI()
        workThreadStatus = false
    end
end

local function runUpdateButton()
    if not workThreadStatus then
        workThreadStatus = true
        digOSUpdate(digOSProgram)
        refreshUI()
        workThreadStatus = false
    end
end

local function runDeleteButton()
    if not workThreadStatus then
        workThreadStatus = true

        local userValidation = basaltUtil.initUserValidation(sub[1], w, h, defaultTheme)

        if userValidation then
            digOSDelete(digOSProgram)
            refreshUI()
        end
        workThreadStatus = false
    end
end

local function runUpdateAllButton()
    if not workThreadStatus then
        workThreadStatus = true
        digOSUpdateAll()
        refreshUI()
        workThreadStatus = false
    end
end

viewHome.main.downloadButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        if not workThreadStatus then
            workThread:start(runDownloadButton)
        end
    end
end)

viewHome.main.updateButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        if not workThreadStatus then
            workThread:start(runUpdateButton)
        end
    end
end)

viewHome.main.deleteButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        if not workThreadStatus then
            workThread:start(runDeleteButton)
        end
    end
end)

viewHome.main.updateAllButton:onClick(function(self, event, button, x, y)
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