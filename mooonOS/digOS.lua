local programInfo = {
    name = "digOS",
    version = "2.0.2",
    author = "ChefMooon"
}

-- BUILD TO SCALE --

--PROGRAM TODO--
-- Add nil checks handle errors
-- Bug Fix Bug Fix
-- Redo programs download
-- Send updates back to remote

-- improve log data structure
    -- add timestamp maybe more?

--- Bigger Ideas
--- implement theme usage and switching
--- add bimg images to the buttons for easier use
---     figure out how to make those images

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
    base = {
        mooonUtil = {
            path = "mooonOS/common/mooonUtil.lua",
            url = "https://raw.githubusercontent.com/ChefMooon/cc-scripts/mooonOS/mooonOS/common/mooonUtil.lua"
        }
    }
}

local digPrograms = {
    digOS_mid_out = {
        path = "mooonOS/digOS/digPrograms/digOS-clear-mid-out.lua",
        url = "https://raw.githubusercontent.com/ChefMooon/cc-scripts/mooonOS/mooonOS/digOS/digPrograms/digOS-clear-mid-out.lua"
    }
}

if not (fs.exists(lib.base.mooonUtil.path)) then
    shell.run("wget " .. lib.base.mooonUtil.url .. " " .. lib.base.mooonUtil.path)
end
local mooonUtil = require(lib.base.mooonUtil.path:gsub(".lua", ""))
local basalt = mooonUtil.getBasalt(mooonUtil.lib.base.basalt.path)

for _, program in pairs(mooonUtil.lib.digOS) do
    if not (fs.exists(program.path)) then
        mooonUtil.downloadFile(program.url, program.path)
    end
end

for _, program in pairs(mooonUtil.lib.common) do
    if not (fs.exists(program.path)) then
        mooonUtil.downloadFile(program.url, program.path)
    end
end

local settingsUtil = mooonUtil.getProgram(mooonUtil.lib.common.settingsUtil.path)
local rednetUtil = mooonUtil.getProgram(mooonUtil.lib.common.rednetUtil.path)
local digUtil = mooonUtil.getProgram(mooonUtil.lib.common.digUtil.path)

local digOSUtil = mooonUtil.getProgram(mooonUtil.lib.digOS.digOSUtil.path)

local viewHome = mooonUtil.getProgram(mooonUtil.lib.digOS.digOSViewHome.path)
local viewControl = mooonUtil.getProgram(mooonUtil.lib.digOS.digOSViewControl.path)
local viewSettings = mooonUtil.getProgram(mooonUtil.lib.digOS.digOSViewSettings.path)
local viewInfo = mooonUtil.getProgram(mooonUtil.lib.digOS.digOSViewInfo.path)

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
    idLabel = digUtil.getTurtleIDLabel(),
    fuelSlot = 1,
    fuel = 0,
    status = "",
    jobStatus = {
        working = false,
        moving = false
    }
}

local history = {
    lastUpdateMessage = {
        data = {}
    }
}

-- Dig Args
local digArgs = digOSUtil.createDigArgsTable("", "", 1, 1, 1, "r", false, digUtil.CONST.DEFAULT_TORCH_SPACING, digUtil.CONST.DEFAULT_TORCH_SLOT, false, digUtil.CONST.DEFAULT_CHEST_SLOT, false, false, false, false, "", "")

local log = {}
local programs = {}

-- Saved Data Options
local savedSelection = 0
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
    saved5 = settingsUtil.define(programName, "saved5", ""),
    moveCommand = settingsUtil.define(programName, "moveCommand", ""),
    moveAmount = settingsUtil.define(programName, "moveAmount", 1),
    moveDig = settingsUtil.define(programName, "moveDig", false)
}

-- local TURTLE_INFO = {
--     id = settingsUtil.define(programName, "id", os.getComputerID()),
--     label = settingsUtil.define(programName, "label", os.getComputerLabel()),
--     fuelSlot = settingsUtil.define(programName, "fuelSlot", 1),
--     fuel = settingsUtil.define(programName, "fuel", 0),
--     status = settingsUtil.define(programName, "status", ""),
--     jobStatus = {
--         working = settingsUtil.define(programName, "jobStatus.working", false),
--         moving = settingsUtil.define(programName, "jobStatus.moving", false)
--     }
-- }

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

    -- todo rework fuel slot, is it needed for dig programs or anything?
    turtleInfo.fuelSlot = turtle.getSelectedSlot()
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
local informationThread = sub[1]:addThread()
local keyboardInputThread = sub[1]:addThread()

local homeUIInfo = {
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
    if (type(newLog) == "number") then
        newLog = tostring(newLog)
    end
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
            addLog(log, refuelButton(1))
        elseif button == 2 then
            addLog(log, refuelButton("max"))
        end
        updateFuelLabel(turtle.getFuelLevel())
    end
end)

local function initializeProgramsDropdown()
    for i = 1, #programs do
        viewHome.getBasicDigSettingsGUI().programDropdown:addItem(programs[i])
    end
end

local function initializeProgramsInfo()
    for i = 1, #programs do
        viewInfo.get().programsInfoList:addItem(programs[i])
    end
end

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

local function sendJobUpdateToRemote(_message)
    if rednetInfo.rednetOpen then
        local updateMessage = {
            command = "update",
            data = {}
        }
        if _message == nil then
            updateMessage.data = digOSUtil.serializeJobInfoWithTurtleInfo(history.lastUpdateMessage.data, turtleInfo)
        elseif type(_message) == "table" then
            history.lastUpdateMessage.data = _message
            updateMessage.data = digOSUtil.serializeJobInfoWithTurtleInfo(_message, turtleInfo)
        else
            updateMessage.payload = _message
        end
        rednet.send(rednetInfo.remoteID, updateMessage, "digOS_update"..rednetInfo.rednetID)
    end
end

local function runDigOSMove()
    local distance = settingsUtil.get(PROG_SETTINGS.moveAmount)
    local command = settingsUtil.get(PROG_SETTINGS.moveCommand)
    local dig = settingsUtil.get(PROG_SETTINGS.moveDig)
    addLog(log, "Move Thread Started.")
    turtleInfo.jobStatus.moving = true
    if command == "forward" then
        digUtil.forward(distance, dig)
    elseif command == "up" then
        digUtil.up(distance, dig)
    elseif command == "down" then
        digUtil.down(distance, dig)
    elseif command == "back" then
        digUtil.back(distance, dig)
    elseif command == "turn_left" then
        digUtil.left(distance)
    elseif command == "turn_left_once" then
        turtle.turnLeft()
    elseif command == "turn_right" then
        digUtil.right(distance)
    elseif command == "turn_right_once" then
        turtle.turnRight()
    elseif command == "shift_left" then
        turtle.turnLeft()
        digUtil.forward(distance, dig)
        turtle.turnRight()
    elseif command == "shift_right" then
        turtle.turnRight()
        digUtil.forward(distance, dig)
        turtle.turnLeft()
    end
    settingsUtil.set(PROG_SETTINGS.moveCommand, "")
    moveThread:stop()
    turtleInfo.jobStatus.moving = false
    addLog(log, "Move Thread Stopped.")
    if rednetInfo.rednetOpen then
        sendJobUpdateToRemote("Move Completed.")
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

local function getRemoteTimeEstimate()
    local formattedDigArgs = digOSUtil.digArgsRun(digArgs)
    formattedDigArgs.command = "time"
    local testargs = digOSUtil.digArgsTableToString(formattedDigArgs)
    shell.run(testargs)
end

local function getRemoteTorchEstimate()
    local formattedDigArgs = digOSUtil.digArgsRun(digArgs)
    formattedDigArgs.command = "torch"
    local testargs = digOSUtil.digArgsTableToString(formattedDigArgs)
    shell.run(testargs)
end

local function getTimeEstimate()
    digArgs = viewHome.getDigArgsFromUI()
    local formattedDigArgs = digOSUtil.digArgsRun(digArgs)
    formattedDigArgs.command = "time"
    local testargs = digOSUtil.digArgsTableToString(formattedDigArgs)
    shell.run(testargs)
end

local function getTorchEstimate()
    digArgs = viewHome.getDigArgsFromUI()
    local formattedDigArgs = digOSUtil.digArgsRun(digArgs)
    formattedDigArgs.command = "torch"
    local testargs = digOSUtil.digArgsTableToString(formattedDigArgs)
    shell.run(testargs)
end

local function startProgram()
    local formattedDigArgs = digOSUtil.digArgsRun(digArgs)
    local testargs = digOSUtil.digArgsTableToString(formattedDigArgs)
    shell.run(testargs)
    os.sleep(1) -- allow final update to arrive
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
    parallel.waitForAny(startProgram, listenForInputs)
    digThread:stop()
    turtleInfo.jobStatus.working = false
    sendJobUpdateToRemote()
    addLog(log, "Dig Thread Stopped")
end

local function tryRunDig()
    if turtleInfo.jobStatus.working == false and turtleInfo.jobStatus.moving == false then -- maybe make a method to check for all threads/jobs
        digArgs = viewHome.getDigArgsFromUI()
        digThread:start(runDigProgram)
        return true
    else
        addLog(log, "Turtle Busy.")
        -- sendJobUpdateToRemote("Turtle Busy.")
        return false
    end
end

local function tryRemoteRunDig()
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

local function listenForUpdates()
    while true do
        local event, updates = os.pullEvent("digOS_job_update")
        local newLog = ""
        -- if updates[1] ~= nil and type(updates[1]) == "string" then
        if (type(updates) == "table") then
            turtleInfo.fuel = updates.turtleFuel
            newLog = updates.message
        elseif (type(updates) == "string") then
            addLog(log, updates)
        else
            newLog = "WARN: Invalid Update"
        end
        if rednetInfo.rednetOpen then
            sendJobUpdateToRemote(updates)
        end

        if updates.turtleFuel ~= nil and type(updates.turtleFuel) == "number" and turtleInfo.fuel ~= updates.turtleFuel then
            updateFuelLabel(updates.turtleFuel)
        end
    end
end

local function informationHandler()
    while true do
        local id, message = rednet.receive(rednetUtil.getProtocol(rednetInfo).."_info")
        if id and message then
            if message.command == "info" then
                addLog(log, "Info Request.")
                local info = {turtleInfo.idLabel, turtleInfo.fuel, turtleInfo.turtleStatus, programs}
                rednet.send(id, info, rednetUtil.getProtocol(rednetInfo))
            elseif message.command == "digOSRemote_startup_info" then
                addLog(log, "Remote Startup Info Request.")
                sendJobUpdateToRemote()
            else
                addLog(log, "Invalid Info Recieved.")
            end
        end
    end
end

local function startInformationThread()
    parallel.waitForAny(informationHandler, listenForUpdates)
end

local function receiveCommands()
    while true do
        local id, message = rednet.receive(rednetUtil.getProtocol(rednetInfo))
        if id and message then
            if message.command == "info" then
                addLog(log, "Info Request.")
                local info = {turtleInfo.idLabel, turtleInfo.fuel, turtleInfo.turtleStatus, programs}
                rednet.send(id, info, rednetUtil.getProtocol(rednetInfo))
            elseif message.command == "run" then
                addLog(log, "Remote Dig command recieved.")
                rednetInfo.remoteID = id
                digArgs = message
                tryRemoteRunDig()
            elseif message.command == "move" then
                addLog(log, "Remote Move command recieved.")
                -- TODO implement remote movements
                settingsUtil.set(PROG_SETTINGS.moveAmount, message.moveAmount)
                settingsUtil.set(PROG_SETTINGS.moveCommand, message.moveCommand)
                settingsUtil.set(PROG_SETTINGS.moveDig, message.moveDig)
                startMoveThread()
            elseif message.command == "time" then
                addLog(log, "Remote Time request recieved.")
                digArgs = message
                getRemoteTimeEstimate()
            elseif message.command == "torch" then
                addLog(log, "Remote Torch request recieved.")
                digArgs = message
                getRemoteTorchEstimate()
            else
                addLog(log, "Invalid Command Recieved.")
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
        informationThread:stop()
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
        informationThread:start(startInformationThread)
    end
end

local function startupRednet()
    rednetInfo.modem = peripheral.find("modem", rednet.open)
    addLog(log, "Rednet Opened. ID: "..rednetInfo.rednetID)
    rednetThread:start(receiveCommands)
    informationThread:start(startInformationThread)
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
-- todo update this to use digArgs data structure after digOSRemote is complete
local function clipboard(_function)
    if rednetInfo.rednetOpen then
        if _function == "copy" then
            digArgs = viewHome.getDigArgsFromUI()
            digArgs.command = "clipboard_copy"
            rednet.broadcast(digArgs, "digOS_update"..rednetInfo.rednetID)
            addLog(log, "Clipboard: Copy")
        elseif _function == "paste" then
            rednet.broadcast({ command = "clipboard_paste"}, "digOS_update"..rednetInfo.rednetID)
            -- get response and set ui
            local id, info = rednet.receive("digOS_clipboard_paste_info", 3)
            if info then
                if info.program ~= "" then
                    digArgs = info
                    viewHome.updateArgsUI(digArgs, defaultTheme)
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

viewHome.get().timeEstimateButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        getTimeEstimate()
    end
end)

viewHome.get().torchEstimateButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        getTorchEstimate()
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
        settingsUtil.set(PROG_SETTINGS.moveCommand, "")
        settingsUtil.set(PROG_SETTINGS.moveAmount, 1)
        settingsUtil.set(PROG_SETTINGS.moveDig, false)
    end
end)

local function setMoveAmount(_value)
    if _value <= 1000 and _value >= 1 then
        settingsUtil.set(PROG_SETTINGS.moveAmount, _value)
        viewControl.getMoveButtons().moveAmountInput:setValue(_value)
    end
end

viewControl.getMoveButtons().moveAmountAddButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") then
        if (button == 1) then
            setMoveAmount(settingsUtil.get(PROG_SETTINGS.moveAmount) + 1)
        elseif (button == 2) then
            setMoveAmount(settingsUtil.get(PROG_SETTINGS.moveAmount) + 5)
        end
    end
end)

viewControl.getMoveButtons().moveAmountSubButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") then
        if (button == 1) then
            setMoveAmount(settingsUtil.get(PROG_SETTINGS.moveAmount) - 1)
        elseif (button == 2) then
            setMoveAmount(settingsUtil.get(PROG_SETTINGS.moveAmount) - 5)
        end
    end
end)

local function doMove()
    moveAmount = viewControl.getMoveButtons().moveAmountInput:getValue()
    settingsUtil.set(PROG_SETTINGS.moveAmount, moveAmount)
    addLog(log, moveAmount)
    startMoveThread()
end

viewControl.getMoveButtons().forwardButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        settingsUtil.set(PROG_SETTINGS.moveCommand, "forward")
        doMove()
    end
end)

viewControl.getMoveButtons().backwardButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        settingsUtil.set(PROG_SETTINGS.moveCommand, "back")
        doMove()
    end
end)

viewControl.getMoveButtons().upButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        settingsUtil.set(PROG_SETTINGS.moveCommand, "up")
        doMove()
    end
end)

viewControl.getMoveButtons().downButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        settingsUtil.set(PROG_SETTINGS.moveCommand, "down")
        doMove()
    end
end)

viewControl.getMoveButtons().shiftLeftButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        settingsUtil.set(PROG_SETTINGS.moveCommand, "shift_left")
        doMove()
    end
end)

viewControl.getMoveButtons().shiftRightButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        settingsUtil.set(PROG_SETTINGS.moveCommand, "shift_right")
        doMove()
    end
end)

viewControl.getMoveButtons().turnLeftButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") then
        if (button == 1) then
            settingsUtil.set(PROG_SETTINGS.moveCommand, "turn_left")
        elseif (button == 2) then
            settingsUtil.set(PROG_SETTINGS.moveCommand, "turn_left_once")
        end
        doMove()
    end
end)

viewControl.getMoveButtons().turnRightButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") then
        if (button == 1) then
            settingsUtil.set(PROG_SETTINGS.moveCommand, "turn_right")
        elseif (button == 2) then
            settingsUtil.set(PROG_SETTINGS.moveCommand, "turn_right_once")
        end
        doMove()
    end
end)

----- MOVE MENU END -----

----- SETTINGS MENU START (backend) -----



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