-- digOS V2.0.0
-- Created by: ChefMooon

-- BUILD TO SCALE --

--PROGRAM TODO--
-- Add nil checks handle errors
-- Bug Fix Bug Fix
-- Redo programs download
-- Send updates back to remote

--- Bigger Ideas
--- 

-- this will help filter broadcast messages
local programName = "digOS"
--local programVersion = "2.0.0"

local defaultTheme = {
    background = colors.gray,
    foreground = colors.yellow,
    rednetOn = colors.red,
    rednetOff = colors.black,
    networkTrue = colors.black,
    networkFalse = colors.lightGray,
    savedDataTrue = colors.yellow,
    savedDataFalse = colors.black
}

----- REQUIRE START -----

local lib = {
    mooonUtil = {
        path = "mooonOS/common/mooonUtil.lua",
        url = "https://raw.githubusercontent.com/ChefMooon/cc-scripts/mooonOS/mooonOS/mooonOS/common/mooonUtil.lua"
    },
    basalt = {
        path = "basalt.lua",
        url = "wget run https://basalt.madefor.cc/install.lua release basalt-1.7.1.lua "
    }
}

local subPrograms = {
    digOSViewHome = {
        path = "mooonOS/digOS/digOSViewHome.lua",
        url = "https://raw.githubusercontent.com/ChefMooon/cc-scripts/mooonOS/mooonOS/mooonOS/digOS/digOSViewHome.lua"
    },
    digOSViewControl = {
        path = "mooonOS/digOS/digOSViewControl.lua",
        url = "https://raw.githubusercontent.com/ChefMooon/cc-scripts/mooonOS/mooonOS/mooonOS/digOS/digOSViewControl.lua"
    },
    digOSViewSettings = {
        path = "mooonOS/digOS/digOSViewSettings.lua",
        url = "https://raw.githubusercontent.com/ChefMooon/cc-scripts/mooonOS/mooonOS/mooonOS/digOS/digOSViewSettings.lua"
    },
    digOSViewInfo = {
        path = "mooonOS/digOS/digOSViewInfo.lua",
        url = "https://raw.githubusercontent.com/ChefMooon/cc-scripts/mooonOS/mooonOS/mooonOS/digOS/digOSViewInfo.lua"
    },
    digOSUtil = {
        path = "mooonOS/digOS/digOSUtil.lua",
        url = "https://raw.githubusercontent.com/ChefMooon/cc-scripts/mooonOS/mooonOS/mooonOS/digOS/digOSUtil.lua"
    },
    rednetUtil = {
        path = "mooonOS/common/rednetUtil.lua",
        url = "https://raw.githubusercontent.com/ChefMooon/cc-scripts/mooonOS/mooonOS/mooonOS/common/rednetUtil.lua"
    },
    settingsUtil = {
        path = "mooonOS/common/settingsUtil.lua",
        url = "https://raw.githubusercontent.com/ChefMooon/cc-scripts/mooonOS/mooonOS/mooonOS/common/settingsUtil.lua"
    },
    digUtil = {
        path = "mooonOS/common/digUtil.lua",
        url = "https://raw.githubusercontent.com/ChefMooon/cc-scripts/mooonOS/mooonOS/mooonOS/common/digUtil.lua"
    }
}

local digPrograms = {
    digOS_mid_out = {
        path = "mooonOS/digOS/digPrograms/digOS-mid-out.lua",
        url = "https://raw.githubusercontent.com/ChefMooon/cc-scripts/mooonOS/mooonOS/mooonOS/digOS/digPrograms/digOS-mid-out.lua"
    }
}

if not (fs.exists(lib.mooonUtil.path)) then
    shell.run("wget " .. lib.mooonUtil.url .. " " .. lib.mooonUtil.path)
end
local mooonUtil = require(lib.mooonUtil.path:gsub(".lua", ""))
local basalt = mooonUtil.getBasalt(lib.basalt.path)

for _, program in pairs(subPrograms) do
    if not (fs.exists(program.path)) then
        print(mooonUtil.getFilenameFromPath(program.path) .. " Not Found. Installing ...")
        mooonUtil.downloadFile(program.url, program.path)
    else
        print(mooonUtil.getFilenameFromPath(program.path) .. " Found!")
    end
end

local settingsUtil = mooonUtil.getProgram(subPrograms.settingsUtil.path)
local digOSUtil = mooonUtil.getProgram(subPrograms.digOSUtil.path)
local rednetUtil = mooonUtil.getProgram(subPrograms.rednetUtil.path)
local digUtil = mooonUtil.getProgram(subPrograms.digUtil.path)

local viewHome = mooonUtil.getProgram(subPrograms.digOSViewHome.path)
local viewControl = mooonUtil.getProgram(subPrograms.digOSViewControl.path)
local viewSettings = mooonUtil.getProgram(subPrograms.digOSViewSettings.path)
local viewInfo = mooonUtil.getProgram(subPrograms.digOSViewInfo.path)

----- REQUIRE END -----

for _, program in pairs(digPrograms) do
    if not (fs.exists(program.path)) then
        print(mooonUtil.getFilenameFromPath(program.path) .. " Not Found. Installing ...")
        mooonUtil.downloadFile(program.url, program.path)
    else
        print(mooonUtil.getFilenameFromPath(program.path) .. " Found!")
    end
end

--TODO: exit of not a turtle

-- Variables


local turtleStats = {
    yPos = 0,
    layersMined = 0,
    blocksMined = 0
}

local turtleInfo = {
    id = os.getComputerID(),
    label = os.getComputerLabel(),
    idLabel = digOSUtil.getTurtleIDLabel(),
    fuelSlot = 1,
    fuel = 0,
    status = "",
    jobStatus = {
        working = false,
        moving = false
    }
}

-- Dig Args
local digArgs = digOSUtil.createDigArgsTable("", "", 1, 1, 1, "r", false, 7, 16, false, 15, false, false, false, false, "", "")

local log = {}
local programs = {}

-- Saved Data Options
local savedSelection = 0

-- Move Options
local moveCommand = ""
local moveAmount = 1
local moveDig = false

-- Rednet Info
local rednetInfo = {
    programName = programName,
    modemChannel = 11,
    rednetOpen = false,
    modem = peripheral.find("modem"),
    networkOffButtonStatus = true,
    networkOnButtonStatus = false,
    rednetID = nil,
    remoteID = 0,
    rednetStatus = nil
}

-- SETTINGS --

local PROG_SETTINGS = {
    rednetID = settingsUtil.define(programName, "rednetID", 0),
    rednetStatus = settingsUtil.define(programName, "rednetStatus", 0),
    saved1 = settingsUtil.define(programName, "saved1", ""),
    saved2 = settingsUtil.define(programName, "saved2", ""),
    saved3 = settingsUtil.define(programName, "saved3", ""),
    saved4 = settingsUtil.define(programName, "saved4", ""),
    saved5 = settingsUtil.define(programName, "saved5", "")
}

settings.load()

local currentSettings = {
    saved1 = settingsUtil.get(PROG_SETTINGS.saved1),
    saved2 = settingsUtil.get(PROG_SETTINGS.saved2),
    saved3 = settingsUtil.get(PROG_SETTINGS.saved3),
    saved4 = settingsUtil.get(PROG_SETTINGS.saved4),
    saved5 = settingsUtil.get(PROG_SETTINGS.saved5)
}

if currentSettings.saved1 == nil then settingsUtil.set(PROG_SETTINGS.saved1, "") end
if currentSettings.saved2 == nil then settingsUtil.set(PROG_SETTINGS.saved2, "") end
if currentSettings.saved3 == nil then settingsUtil.set(PROG_SETTINGS.saved3, "") end
if currentSettings.saved4 == nil then settingsUtil.set(PROG_SETTINGS.saved4, "") end
if currentSettings.saved5 == nil then settingsUtil.set(PROG_SETTINGS.saved5, "") end

rednetInfo.rednetID = settingsUtil.get(PROG_SETTINGS.rednetID)
rednetInfo.rednetStatus = settingsUtil.get(PROG_SETTINGS.rednetStatus)
if rednetInfo.rednetStatus == 1 then
    rednetInfo.rednetOpen = true
    rednetInfo.networkOffButtonStatus = false
    rednetInfo.networkOnButtonStatus = true
elseif rednetInfo.rednetStatus == 0 then
    rednetInfo.rednetOpen = false
    rednetInfo.networkOffButtonStatus = true
    rednetInfo.networkOnButtonStatus = false
end

-- PROGRAMS START --

local function refuelButton(amount)
    local result, err
    local startFuel = turtle.getFuelLevel()
    if amount == "max" then
        result, err = turtle.refuel()
    elseif type(amount) == "number" then
        result, err = turtle.refuel(amount)
    else
        return "Invalid refuel amount."
    end

    turtle.select(turtleInfo.fuelSlot)
    if result then
        local newFuel = turtle.getFuelLevel()
        return "Succesful Refuel. " .. tostring(newFuel - startFuel) .. " Fuel added."
    else
        return "Unsuccessful Refuel. " .. err .. "."
    end
end

--- UTILITY ---


local function initRednetID()
    if rednetInfo.rednetID == 0 then
        local id = math.random(1, 99)
        rednetInfo.rednetID = id
        settingsUtil.set(PROG_SETTINGS.rednetID, id)
    else
        rednetInfo.rednetID = settingsUtil.get(PROG_SETTINGS.rednetID)
    end
    return rednetInfo.rednetID
end

local function setRednetStatus(_status)
    if _status then
        settingsUtil.set(PROG_SETTINGS.rednetStatus, 1)
    else
        settingsUtil.set(PROG_SETTINGS.rednetStatus, 0)
    end
end

-- PGROGRAMS END --

local w, h = term.getSize()
local main = basalt.createFrame():setTheme({ FrameBG = colors.lightGray, FrameFG = colors.black })

local sub = {
    main:addFrame():setPosition(1, 2):setSize("{parent.w}", "{parent.h - 1}"),
    main:addFrame():setPosition(1, 2):setSize("{parent.w}", "{parent.h - 1}"):hide(),
    main:addFrame():setPosition(1, 2):setSize("{parent.w}", "{parent.h - 1}"):hide(),
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
    :addItem("Control")
    :addItem("Settings")
    :addItem("Info")

local menubarInfoFrame = main:addFrame():setPosition("{parent.w-7}", 1):setSize(7,1):setBackground(colors.gray)

local menubarRednetStatusButton = menubarInfoFrame:addButton():setText(""):setPosition(1, 1):setSize(1,1):setBackground(digOSUtil.getMenubarRednetStatusButtonColor(rednetInfo, defaultTheme))

local programLabel = menubarInfoFrame:addLabel():setText("digOS"):setPosition(3, 1):setForeground(colors.yellow)

---------- **** FRONTEND START **** ----------
----- HOME MENU START (frontend) -----

local digThread = sub[1]:addThread()
local rednetThread = sub[1]:addThread()
local keyboardInputThread = sub[1]:addThread()

local homeUIInfo = {
    -- saved1ButtonColor = getSavedButtonColor(1),
    saved1ButtonColor = digOSUtil.getSavedButtonColor(1, currentSettings, defaultTheme),
    saved2ButtonColor = digOSUtil.getSavedButtonColor(2, currentSettings, defaultTheme),
    saved3ButtonColor = digOSUtil.getSavedButtonColor(3, currentSettings, defaultTheme),
    saved4ButtonColor = digOSUtil.getSavedButtonColor(4, currentSettings, defaultTheme),
    saved5ButtonColor = digOSUtil.getSavedButtonColor(5, currentSettings, defaultTheme)
}

viewHome.init(sub[1], turtleInfo, digArgs, homeUIInfo, rednetInfo, defaultTheme)

----- HOME MENU END (frontend) -----

----- MOVE MENU START (frontend) -----

local moveThread = sub[2]:addThread()
viewControl.init(sub[2], defaultTheme)

----- MOVE MENU END (frontend) -----

----- SETTINGS MENU START (frontend) -----

viewSettings.init(sub[3], turtleInfo, rednetInfo, defaultTheme)
viewSettings.initHomeNetworkOffOnButtons(digOSUtil.getNetworkOffButtonColor(rednetInfo, defaultTheme), digOSUtil.getNetworkOnButtonColor(rednetInfo, defaultTheme))

----- SETTINGS MENU END (frontend) -----

----- INFO MENU START (frontend) -----

viewInfo.init(sub[4], defaultTheme)

----- INFO MENU END (frontend) -----
---------- **** FRONTEND END **** ----------

--- HOME MENU START ---

viewHome.getLogList().logList:onSelect(function(self, event, item)
    -- basalt.debug("Selected item: ", item.text)
end)

local function wrapLog(log)
    local maxLength = 39
    local indent = " "
    local wrappedLog = {}
    local currentLine = ""
    local words = {}

    for word in log:gmatch("%S+") do
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

local function updateLog()
    viewHome.getLogList().logList:clear()
    for i = 1, #log do
        viewHome.getLogList().logList:addItem(log[i])
    end
end

local function addLog(log, newLog)
    local wrappedLog = wrapLog(newLog)
    for i = #wrappedLog, 1, -1 do
        table.insert(log, 1, wrappedLog[i])
    end
    -- table.insert(log, 1, newLog)
    updateLog()
end

local function deleteLog(log, logToRemove)
    for i, logEntry in ipairs(log) do
        if logEntry == logToRemove then
            table.remove(log, i)
            updateLog()
            return true
        else
            return false
        end
    end
end

local function updateFuelLabel(fuel)
    viewHome.getFuelGUI().fuelLevelLabel:setText(tostring(fuel))
end

viewHome.getFuelGUI().fuelButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") then
        if button == 1 then
            addLog(log, refuelButton("max"))
        elseif button == 2 then
            addLog(log, refuelButton(1))
        end
        updateFuelLabel(turtle.getFuelLevel())
    end
end)

local function initializeProgramsDropdown()
    for i = 1, #programs do
        viewHome.getBaseGUI().programDropdown:addItem(programs[i])
    end
end

viewHome.getBaseGUI().programDropdown:onChange(function(self, item)
    digArgs.program = tostring(item.text)
end)

local function initializeProgramsInfo()
    for i = 1, #programs do
        viewInfo.get().programsInfoList:addItem(programs[i])
    end
end

local function getNumberChange(_button)
    local result = 0
    if _button == 1 then
        result = 1
    elseif _button == 2 then
        result = 5
    end
    return result
end

viewHome.getDigArgs().lengthSubButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") then
        local newValue = viewHome.getDigArgs().lengthInput:getValue() - getNumberChange(button)
        if newValue > 0 then
            digArgs.length = newValue
            viewHome.getDigArgs().lengthInput:setValue(digArgs.length)
        end
    end
end)

viewHome.getDigArgs().lengthAddButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") then
        local newValue = viewHome.getDigArgs().lengthInput:getValue() + getNumberChange(button)
        if newValue < 1001 then
            digArgs.length = newValue
            viewHome.getDigArgs().lengthInput:setValue(digArgs.length)
        end
    end
end)

viewHome.getDigArgs().widthSubButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") then
        local newValue = viewHome.getDigArgs().widthInput:getValue() - getNumberChange(button)
        if newValue > 0 then
            digArgs.width = newValue
            viewHome.getDigArgs().widthInput:setValue(digArgs.width)
        end
    end
end)

viewHome.getDigArgs().widthAddButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") then
        local newValue = viewHome.getDigArgs().widthInput:getValue() + getNumberChange(button)
        if newValue < 1001 then
            digArgs.width = newValue
            viewHome.getDigArgs().widthInput:setValue(digArgs.width)
        end
    end
end)

viewHome.getDigArgs().heightSubButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") then
        local newValue = viewHome.getDigArgs().heightInput:getValue() - getNumberChange(button)
        if newValue > 0 then
            digArgs.height = newValue
            viewHome.getDigArgs().heightInput:setValue(digArgs.height)
        end
    end
end)

viewHome.getDigArgs().heightAddButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") then
        local newValue = viewHome.getDigArgs().heightInput:getValue() + getNumberChange(button)
        if newValue < 1001 then
            digArgs.height = newValue
            viewHome.getDigArgs().heightInput:setValue(digArgs.height)
        end
    end
end)

viewHome.getDigArgs().offsetLeftButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        self:setForeground(colors.black)
        viewHome.getDigArgs().offsetRightButton:setForeground(colors.lightGray)
        if digArgs.offsetDir ~= "l" then
            digArgs.offsetDir = "l"
        end
    end
end)

viewHome.getDigArgs().offsetRightButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        self:setForeground(colors.black)
        viewHome.getDigArgs().offsetLeftButton:setForeground(colors.lightGray)
        if digArgs.offsetDir ~= "r" then
            digArgs.offsetDir = "r"
        end
    end
end)

local function selectSaved(_select)
    local buttons = { 
        viewHome.getSavedDataButtons().saved1Button,
        viewHome.getSavedDataButtons().saved2Button,
        viewHome.getSavedDataButtons().saved3Button,
        viewHome.getSavedDataButtons().saved4Button,
        viewHome.getSavedDataButtons().saved5Button
    }

    for i = 1, #buttons do
        if i == _select then
            buttons[i]:setForeground(colors.lightGray)
        else
            buttons[i]:setForeground(digOSUtil.getSavedButtonColor(i, currentSettings, defaultTheme))
        end
    end
end

local function saveArgsUI(_saveSlot)
    digArgs = viewHome.getDigArgsFromUI()
    settingsUtil.set(_saveSlot, digArgs)
    addLog(log, "Preset Saved.")
    return savedArgsString
end

local function resetSaved(_saveSlot)
    settingsUtil.set(_saveSlot, "")
    addLog(log, "Preset Reset.")
    return ""
end

local function loadSelectedSaved()
    if savedSelection == 0 then
        addLog(log, "Select a Preset.")
    else
        local saved = ""

        if savedSelection == 1 then
            saved = settingsUtil.get(PROG_SETTINGS.saved1)
        elseif savedSelection == 2 then
            saved = settingsUtil.get(PROG_SETTINGS.saved2)
        elseif savedSelection == 3 then
            saved = settingsUtil.get(PROG_SETTINGS.saved3)
        elseif savedSelection == 4 then
            saved = settingsUtil.get(PROG_SETTINGS.saved4)
        elseif savedSelection == 5 then
            saved = settingsUtil.get(PROG_SETTINGS.saved5)
        end

        if saved ~= nil and saved ~= "" then
            digArgs = saved
            viewHome.updateArgsUI(digArgs, defaultTheme)
            local newLog = "Preset "..tostring(savedSelection).." Loaded."
            addLog(log, newLog)
        else
            addLog(log, "No Saved Data.")
        end
    end
end

viewHome.getSavedDataButtons().saved1Button:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        local savedNum = 1
        if savedSelection ~= savedNum then
            savedSelection = savedNum
            selectSaved(savedNum)
        else
            loadSelectedSaved()
        end
    end
end)

viewHome.getSavedDataButtons().saved2Button:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        local savedNum = 2
        if savedSelection ~= savedNum then
            savedSelection = savedNum
            selectSaved(savedNum)
        else
            loadSelectedSaved()
        end
    end
end)

viewHome.getSavedDataButtons().saved3Button:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        local savedNum = 3
        if savedSelection ~= savedNum then
            savedSelection = savedNum
            selectSaved(savedNum)
        else
            loadSelectedSaved()
        end
    end
end)

viewHome.getSavedDataButtons().saved4Button:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        local savedNum = 4
        if savedSelection ~= savedNum then
            savedSelection = savedNum
            selectSaved(savedNum)
        else
            loadSelectedSaved()
        end
    end
end)

viewHome.getSavedDataButtons().saved5Button:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        local savedNum = 5
        if savedSelection ~= savedNum then
            savedSelection = savedNum
            selectSaved(savedNum)
        else
            loadSelectedSaved()
        end
    end
end)

viewHome.getSavedDataButtons().loadSavedButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        loadSelectedSaved()
    end
end)

viewHome.getSavedDataButtons().saveSavedButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        if savedSelection == 0 then
            addLog(log, "Select a Preset.")
        elseif savedSelection == 1 then
            currentSettings.saved1 = saveArgsUI(PROG_SETTINGS.saved1)
        elseif savedSelection == 2 then
            currentSettings.saved2 = saveArgsUI(PROG_SETTINGS.saved2)
        elseif savedSelection == 3 then
            currentSettings.saved3 = saveArgsUI(PROG_SETTINGS.saved3)
        elseif savedSelection == 4 then
            currentSettings.saved4 = saveArgsUI(PROG_SETTINGS.saved4)
        elseif savedSelection == 5 then
            currentSettings.saved5 = saveArgsUI(PROG_SETTINGS.saved5)
        end
    end
end)

viewHome.getSavedDataButtons().resetSavedButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        if savedSelection == 0 then
            addLog(log, "Select a Preset.")
        elseif savedSelection == 1 then
            currentSettings.saved1 = resetSaved(PROG_SETTINGS.saved1)
        elseif savedSelection == 2 then
            currentSettings.saved2 = resetSaved(PROG_SETTINGS.saved2)
        elseif savedSelection == 3 then
            currentSettings.saved3 = resetSaved(PROG_SETTINGS.saved3)
        elseif savedSelection == 4 then
            currentSettings.saved4 = resetSaved(PROG_SETTINGS.saved4)
        elseif savedSelection == 5 then
            currentSettings.saved5 = resetSaved(PROG_SETTINGS.saved5)
        end
    end
end)

local function runDigOSMove()
    addLog(log, "Move Thread Started.")
    turtleInfo.jobStatus.moving = true
    if moveCommand == "forward" then
        digUtil.forward(moveAmount, moveDig)
    elseif moveCommand == "up" then
        digUtil.up(moveAmount, moveDig)
    elseif moveCommand == "down" then
        digUtil.down(moveAmount, moveDig)
    elseif moveCommand == "back" then
        digUtil.back(moveAmount, moveDig)
    elseif moveCommand == "turn_left" then
        -- turtle.turnLeft()
        digUtil.left(moveAmount)
    elseif moveCommand == "turn_right" then
        -- turtle.turnRight()
        digUtil.right(moveAmount)
    elseif moveCommand == "shift_left" then
        turtle.turnLeft()
        digUtil.forward(moveAmount, moveDig)
        turtle.turnRight()
    elseif moveCommand == "shift_right" then
        turtle.turnRight()
        digUtil.forward(moveAmount, moveDig)
        turtle.turnLeft()
    end
    moveCommand = ""
    moveThread:stop()
    turtleInfo.jobStatus.moving = false
    addLog(log, "Move Thread Stopped.")
end

local function sendJobUpdateToRemote(_message)
    if rednetInfo.rednetOpen then
        updateMessage = { "update", _message }
        rednet.send(rednetInfo.remoteID, updateMessage, "digOS_update"..rednetInfo.rednetID)
    end
end

local function startMoveThread()
    if turtleInfo.jobStatus.working == false and turtleInfo.jobStatus.moving == false then
        moveThread:start(runDigOSMove)
        sendJobUpdateToRemote("Move Started.")
        return true
    else
        sendJobUpdateToRemote("Turtle Busy.")
        addLog(log, "Turtle Busy.")
        return false
    end
end

local function startProgram()
    local viewDigArgs = viewHome.getDigArgsFromUI()
    local formattedDigArgs = digOSUtil.digArgsRun(viewDigArgs)
    local testargs = digOSUtil.digArgsTableToString(formattedDigArgs)
    shell.run(testargs)
    os.sleep(1) -- allow final update to arrive
end

-- Maybe seperate function for non log updates? (fuel?)
local function listenForUpdates()
    while true do
        local event, updates = os.pullEvent("digOS_job_update")
        local newLog = ""
        if updates[1] ~= nil and type(updates[1]) == "string" then
            newLog = updates[1]
        else
            newLog = "WARN: Invalid Update"
        end
        if rednetInfo.rednetOpen then
            rednet.send(rednetInfo.remoteID, updates, "digOS_job_update")
        end
        addLog(log, newLog)

        if updates[2] ~= nil and type(updates[2]) == "number" and turtleInfo.fuel ~= updates[2] then
            updateFuelLabel(updates[2])
        end
    end
end

local function listenForInputs()
    while true do
        local inputEvent, update = os.pullEvent("digOS_job_input")
        -- output to log that operating program requires input
        if type(update) == "string" then
            addLog(log, update)
        else
            addLog(log, "WARN: Invalid Input")
        end
        while true do
            local keyEvent, keyNum, is_held = os.pullEvent("key")
            local key = keys.getName(keyNum)
            if key ~= "leftShift" then
                os.queueEvent("digOS_job_input_result", key)

                local validEvent, isValid = os.pullEvent("digOS_job_input_valid")
                if isValid then
                    break
                else
                    addLog(log, "Invalid Key")
                end
            end
        end
    end
end

local function runDigProgram()
    addLog(log, "Dig Thread Started.")
    turtleInfo.jobStatus.working = true
    parallel.waitForAny(startProgram, listenForUpdates, listenForInputs)
    digThread:stop()
    turtleInfo.jobStatus.working = false
    addLog(log, "Dig Thread Stopped")
end

local function tryRunDig()
    if turtleInfo.jobStatus.working == false and turtleInfo.jobStatus.moving == false then -- maybe make a method to check for all threads/jobs
        digThread:start(runDigProgram)
        sendJobUpdateToRemote("Dig Started.")
        return true
    else
        addLog(log, "Turtle Busy.")
        sendJobUpdateToRemote("Turtle Busy.")
        return false
    end
end

local function receiveCommands()
    while true do
        local id, message = rednet.receive(rednetUtil.getProtocol(rednetInfo))
        if id and message then
            if message[1] == "info" then
                addLog(log, "Info Request.")
                local info = {digOSUtil.getTurtleIDLabel(), turtleInfo.fuel, turtleInfo.turtleStatus, programs}
                rednet.send(id, info, rednetUtil.getProtocol(rednetInfo))
            elseif message[1] == "run" then
                addLog(log, "Remote Dig command recieved.")
                rednetInfo.remoteID = id
                digArgs.program = message[2]
                digArgs.length = tonumber(message[3]) or 0
                digArgs.width = tonumber(message[4]) or 0
                digArgs.height = tonumber(message[5]) or 0
                digArgs.offsetDir = message[6]
                digArgs.torch = message[7]
                digArgs.chest = message[8]
                digArgs.rts = message[9]
                tryRunDig()
            elseif message[1] == "move" then
                addLog(log, "Remote Move command recieved.")
                moveAmount = tonumber(message[2]) --reset back to ui number?
                moveCommand = message[3]
                moveDig = message[4]
                startMoveThread()
                moveAmount = viewControl.getMoveButtons().moveAmountInput:getValue()
            end
        end

        if message ~= nil and message[1] == "terminate" then
            addLog(log, "broke")
            break
        end
    end
    viewSettings.get().homeNetworkOffButton:setForeground(colors.black)
    viewSettings.get().homeNetworkOnButton:setForeground(colors.lightGray)
    rednetInfo.rednetOpen = false
    setRednetStatus(rednetInfo.rednetOpen)
    rednet.close()
    rednetThread:stop()
end

local function stopRednet()
    if rednetInfo.rednetOpen then
        viewSettings.get().homeNetworkOffButton:setForeground(colors.black)
        viewSettings.get().homeNetworkOnButton:setForeground(colors.lightGray)
        rednetInfo.rednetOpen = false
        setRednetStatus(rednetInfo.rednetOpen)
        rednet.close()
        rednetThread:stop()
        addLog(log, "Rednet Closed")
    end
end

local function startRednet()
    if not rednetInfo.rednetOpen then
        viewSettings.get().homeNetworkOffButton:setForeground(colors.lightGray)
        viewSettings.get().homeNetworkOnButton:setForeground(colors.black)
        rednetInfo.rednetOpen = true
        setRednetStatus(rednetInfo.rednetOpen)
        rednetInfo.modem = peripheral.find("modem", rednet.open)
        if rednetInfo.rednetID ~= viewSettings.get().homeNetworkID:getValue() then
            rednetInfo.rednetID = viewSettings.get().homeNetworkID:getValue()
        end
        settingsUtil.set(PROG_SETTINGS.rednetID, viewSettings.get().homeNetworkID:getValue())
        addLog(log, "Rednet Opened. ID: "..rednetInfo.rednetID)
        rednetThread:start(receiveCommands)
    end
end

local function startupRednet()
    rednetInfo.modem = peripheral.find("modem", rednet.open)
    addLog(log, "Rednet Opened. ID: "..rednetInfo.rednetID)
    rednetThread:start(receiveCommands)
end

local function toggleRednet()
    if rednetInfo.rednetOpen then
        stopRednet()
    else
        startRednet()
    end
    menubarRednetStatusButton:setBackground(digOSUtil.getMenubarRednetStatusButtonColor(rednetInfo, defaultTheme))
end

viewSettings.get().homeNetworkOffButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        stopRednet()
        menubarRednetStatusButton:setBackground(digOSUtil.getMenubarRednetStatusButtonColor(rednetInfo, defaultTheme))
    end
end)

viewSettings.get().homeNetworkOnButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        startRednet()
        menubarRednetStatusButton:setBackground(digOSUtil.getMenubarRednetStatusButtonColor(rednetInfo, defaultTheme))
    end
end)

menubarRednetStatusButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        toggleRednet()
    end
end)

-- TODO: Create ClipboardThread so the program does not hang while waiting
local function clipboard(_function)
    if rednetInfo.rednetOpen then
        if _function == "copy" then
            local copyArgs = {
                "digOS-" .. digArgs.program .. ".lua",
                tostring(digArgs.length), tostring(digArgs.width), tostring(digArgs.height),
                tostring(digArgs.offsetDir), tostring(digArgs.torch.torch), tostring(digArgs.chest.chest), tostring(digArgs.rts) }
            local copyMessage = { "clipboard", "copy", table.concat(copyArgs, " ")}
            rednet.broadcast(copyMessage, "digOS_update"..rednetInfo.rednetID)
            addLog(log, "Clipboard: Copy")
        elseif _function == "paste" then
            local pasteMessage = { "clipboard", "paste" }
            rednet.broadcast(pasteMessage, "digOS_update"..rednetInfo.rednetID)
            -- get response and set ui
            local id, info = rednet.receive("digOS_clipboard_paste_info", 3)
            -- info format: _program, _length, _width, _height, _offsetDir, _torch, _chest, _rts
            if info then
                if info ~= "" then 
                    pasteInfo = digOSUtil.splitString(info)
                    updateArgsUI(pasteInfo[1], pasteInfo[2], pasteInfo[3], pasteInfo[4], pasteInfo[5], pasteInfo[6], pasteInfo[7], pasteInfo[8])
                    addLog(log, "Clipboard: Paste Success")
                else
                    addLog(log, "Clipboard: No Save Data")
                end
            else
                addLog(log, "Clipboard: Paste Failure")
            end
        else
            addLog("Clipboard Error")
        end
    else
        addLog(log, "Clipboard requires Rednet.")
    end
end

viewHome.getClipboardGUI().copyButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        clipboard("copy")
    end
end)

viewHome.getClipboardGUI().pasteButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        clipboard("paste")
    end
end)

local function runDig()
    digArgs.program = viewHome.getBaseGUI().programDropdown:getItem(viewHome.getBaseGUI().programDropdown:getItemIndex()).text
    digArgs.length = tonumber(viewHome.getDigArgs().lengthInput:getValue()) or 0
    digArgs.width = tonumber(viewHome.getDigArgs().widthInput:getValue()) or 0
    digArgs.height = tonumber(viewHome.getDigArgs().heightInput:getValue()) or 0
    tryRunDig()
    updateFuelLabel(turtle.getFuelLevel())
end

viewHome.getRunButton().runButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        runDig()
    end
end)

local function resetInput()
    viewHome.resetArgsUI()
    if turtleInfo.jobStatus.working == true then
        digThread:stop()
        addLog(log, "Dig Thread Reset.")
    else
        addLog(log, "Input Reset.")
    end
    turtle.select(1)
end

viewHome.getResetButton().resetButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        resetInput()
    end
end)

--- HOME MENU START END ---

----- MOVE MENU START -----

local function digCheckboxChange(self)
    if self:getValue() then
        moveDig = false
    else
        moveDig = true
    end
end
viewControl.getMoveButtons().digCheckbox:onChange(digCheckboxChange)

viewControl.getMoveButtons().moveAmountResetButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        viewControl.getMoveButtons().moveAmountInput:setValue("1")
        viewControl.getMoveButtons().digCheckbox:setValue(false)
        moveCommand = ""
        moveAmount = 1
        moveDig = false
    end
end)

local function setMoveAmount(_value)
    if _value <= 1000 and _value >= 1 then
        moveAmount = _value
        viewControl.getMoveButtons().moveAmountInput:setValue(_value)
    end
end

viewControl.getMoveButtons().moveAmountAdd5Button:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        setMoveAmount(moveAmount + 5)
    end
end)

viewControl.getMoveButtons().moveAmountAdd1Button:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        setMoveAmount(moveAmount + 1)
    end
end)

viewControl.getMoveButtons().moveAmountSub1Button:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        setMoveAmount(moveAmount - 1)
    end
end)

viewControl.getMoveButtons().moveAmountSub5Button:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        setMoveAmount(moveAmount - 5)
    end
end)

local function doMove()
    moveAmount = viewControl.getMoveButtons().moveAmountInput:getValue()
    addLog(log, moveAmount)
    startMoveThread()
end

viewControl.getMoveButtons().forwardButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        moveCommand = "forward"
        doMove()
    end
end)

viewControl.getMoveButtons().backwardButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        moveCommand = "back"
        doMove()
    end
end)

viewControl.getMoveButtons().upButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        moveCommand = "up"
        addLog(log, "up")
        doMove()
    end
end)

viewControl.getMoveButtons().downButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        moveCommand = "down"
        doMove()
    end
end)

viewControl.getMoveButtons().shiftLeftButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        moveCommand = "shift_left"
        doMove()
    end
end)

viewControl.getMoveButtons().shiftRightButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        moveCommand = "shift_right"
        doMove()
    end
end)

viewControl.getMoveButtons().turnLeftButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        moveCommand = "turn_left"
        doMove()
    end
end)

viewControl.getMoveButtons().turnRightButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        moveCommand = "turn_right"
        doMove()
    end
end)

----- MOVE MENU END -----

----- SETTINGS MENU START (backend) -----

local function chestCheckboxChange(self)
    if self:getValue() then
        digArgs.chest.chest = false
    else
        digArgs.chest.chest = true
    end
end
viewHome.getDigArgs().chestCheckbox:onChange(chestCheckboxChange)

local function torchCheckboxChange(self)
    if self:getValue() then
        digArgs.torch.torch = false
    else
        digArgs.torch.torch = true
    end
end
viewHome.getDigArgs().torchCheckbox:onChange(torchCheckboxChange)

local function rtsCheckboxChange(self)
    if self:getValue() then
        digArgs.rts = false
    else
        digArgs.rts = true
    end
end
viewHome.getDigArgs().rtsCheckbox:onChange(rtsCheckboxChange)

local function ignoreInvCheckboxChange(self)
    if self:getValue() then
        digArgs.ignoreInventory = false
    else
        digArgs.ignoreInventory = true
    end
end
viewHome.getDigArgs().ignoreInvCheckbox:onChange(ignoreInvCheckboxChange)

local function ignoreFuelCheckboxChange(self)
    if self:getValue() then
        digArgs.ignoreFuel = false
    else
        digArgs.ignoreFuel = true
    end
end
viewHome.getDigArgs().ignoreFuelCheckbox:onChange(ignoreFuelCheckboxChange)

local function noPickupCheckboxChange(self)
    if self:getValue() then
        digArgs.noPickup = false
    else
        digArgs.noPickup = true
    end
end
viewHome.getDigArgs().noPickupCheckbox:onChange(noPickupCheckboxChange)

----- SETTINGS MENU END -----

----- INFO MENU START (backend) -----

----- INFO MENU END -----

local function keyboardInput()
    while true do
        local event, key, is_held = os.pullEvent("key")
        if key ~= 340 then
            if key == 257 then
                runDig()
            elseif key == 82 then
                resetInput()
            elseif key == 87 then
                toggleRednet()
            end
        end
      end
end

local function init()
    initRednetID()

    turtleInfo.fuel = turtle.getFuelLevel()
    updateFuelLabel(turtleInfo.fuel)

    programs = digOSUtil.getDigOSPrograms()
    initializeProgramsDropdown()
    initializeProgramsInfo()

    if rednetInfo.modem == nil then
        viewSettings.get().homeNetworkFrame:hide()
        viewHome.getClipboardGUI().frame:hide()
    end

    if #programs > 0 then
        digArgs.program = programs[1]
    end

    keyboardInputThread:start(keyboardInput)

    if rednetInfo.rednetOpen then
        startupRednet()
    else
        stopRednet()
    end
end

init()

basalt.autoUpdate()