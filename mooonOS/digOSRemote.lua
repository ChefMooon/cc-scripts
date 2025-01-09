local programInfo = {
    name = "digOSRemote",
    version = "2.0.0",
    author = "ChefMooon"
}

-- digOSRemote V1.0.0
-- Created by: ChefMooon

--PROGRAM TODO--
-- 
-- 

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

if not (fs.exists(lib.base.mooonUtil.path)) then
    shell.run("wget " .. lib.base.mooonUtil.url .. " " .. lib.base.mooonUtil.path)
end
local mooonUtil = require(lib.base.mooonUtil.path:gsub(".lua", ""))
local basalt = mooonUtil.getBasalt(mooonUtil.lib.base.basalt.path)

for _, program in pairs(mooonUtil.lib.digOSRemote) do
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

local viewHome = mooonUtil.getProgram(mooonUtil.lib.digOSRemote.digOSRemoteViewHome.path)
-- local viewControl = mooonUtil.getProgram(mooonUtil.lib.digOSRemote.digOSRemoteViewControl.path)
local viewSettings = mooonUtil.getProgram(mooonUtil.lib.digOSRemote.digOSRemoteViewSettings.path)

----- REQUIRE END -----


--local programName = "digOSRemote"
--local programVersion = "1.0.0"

local broadcastFilter = "digOS"

-- local filePath = "basalt.lua"
-- if not (fs.exists(filePath)) then
--     shell.run("wget run https://basalt.madefor.cc/install.lua release basalt-1.7.1.lua " .. filePath)
-- end
-- local basalt = require(filePath:gsub(".lua", ""))

-- Selected Turtle Info
local selectedID = ""
local selectedFuel = ""
local selectedStatus = ""

local info = {
    id = "",
    label = "",
    idLabel = "",
    fuelSlot = 1,
    fuel = 0,
    status = "",
    jobStatus = {
        working = false,
        moving = false
    }
}

local computerInfo = {
    id = os.getComputerID(),
    label = os.getComputerLabel(),
    idLabel = digUtil.getTurtleIDLabel()
}

-- Dig Options
local selectedProgram = ""
local length, width, height = 1, 1, 1
local offsetDir = "r"
local torch, chest, rts = false, false, false

local digArgs = digUtil.createDigArgsTable("", "", 1, 1, 1, "r", false, 7, 16, false, 15, false, false, false, false, "", "")

local log = {}
local programs = { "clear-mid-out" }
local connectedTurtles = {}

-- Preset Options
-- local saved1, saved2, saved3, saved4, saved5
local savedSelection = 0

local clipboard = ""

-- Move Options
local moveCommand = ""
local moveAmount = 1
local moveDig = false

-- Rednet Info
local rednetInfo = {
    programName = broadcastFilter,
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
    rednetID = settingsUtil.define(programInfo.name, "rednetID", 0),
    rednetStatus = settingsUtil.define(programInfo.name, "rednetStatus", 0),
    clipboard = settingsUtil.define(programInfo.name, "clipboard", ""),
    saved1 = settingsUtil.define(programInfo.name, "saved1", ""),
    saved2 = settingsUtil.define(programInfo.name, "saved2", ""),
    saved3 = settingsUtil.define(programInfo.name, "saved3", ""),
    saved4 = settingsUtil.define(programInfo.name, "saved4", ""),
    saved5 = settingsUtil.define(programInfo.name, "saved5", "")
}

settings.load()

local currentSettings = {
    saved1 = settingsUtil.get(PROG_SETTINGS.saved1),
    saved2 = settingsUtil.get(PROG_SETTINGS.saved2),
    saved3 = settingsUtil.get(PROG_SETTINGS.saved3),
    saved4 = settingsUtil.get(PROG_SETTINGS.saved4),
    saved5 = settingsUtil.get(PROG_SETTINGS.saved5),
}

if currentSettings.saved1 == nil then settingsUtil.set(PROG_SETTINGS.saved1, "") end
if currentSettings.saved2 == nil then settingsUtil.set(PROG_SETTINGS.saved2, "") end
if currentSettings.saved3 == nil then settingsUtil.set(PROG_SETTINGS.saved3, "") end
if currentSettings.saved4 == nil then settingsUtil.set(PROG_SETTINGS.saved4, "") end
if currentSettings.saved5 == nil then settingsUtil.set(PROG_SETTINGS.saved5, "") end

clipboard = settingsUtil.get(PROG_SETTINGS.clipboard)

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

-- TODO: do something else if on a pc (use term or a monitor?)
local w,h = 0,0
if pocket then
    w, h = term.getSize()
end

local main = basalt.createFrame():setTheme({ FrameBG = colors.lightGray, FrameFG = colors.black })

local sub = {
    main:addFrame():setPosition(1, 2):setSize("{parent.w}", "{parent.h - 1}"),
    main:addFrame():setPosition(1, 2):setSize("{parent.w}", "{parent.h - 1}"):hide(),
    main:addFrame():setPosition(1, 2):setSize("{parent.w}", "{parent.h - 1}"):hide(),
    main:addFrame():setPosition(1, 2):setSize("{parent.w}", "{parent.h - 1}"):hide(),
}

local sendThread = sub[1]:addThread()

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
    :addItem("Move")
    :addItem("Adv")

local menubarInfoFrame = main:addFrame():setPosition("{parent.w-7}", 1):setSize(7,1):setBackground(colors.gray)

local menubarRednetStatusButton = menubarInfoFrame:addButton():setText(""):setPosition(1, 1):setSize(1,1):setBackground(digOSUtil.getMenubarRednetStatusButtonColor(rednetInfo, defaultTheme))

local programLabel = menubarInfoFrame:addLabel():setText(programInfo.name):setPosition(3, 1):setForeground(colors.yellow)

--local rednetThread = sub[1]:addThread()
local updateThread = sub[1]:addThread()

---------- **** FRONTEND START **** ----------
----- HOME MENU START (frontend) -----

local homeUIInfo = {
    saved1ButtonColor = digOSUtil.getSavedButtonColor(1, currentSettings, defaultTheme),
    saved2ButtonColor = digOSUtil.getSavedButtonColor(2, currentSettings, defaultTheme),
    saved3ButtonColor = digOSUtil.getSavedButtonColor(3, currentSettings, defaultTheme),
    saved4ButtonColor = digOSUtil.getSavedButtonColor(4, currentSettings, defaultTheme),
    saved5ButtonColor = digOSUtil.getSavedButtonColor(5, currentSettings, defaultTheme)
}

viewHome.init(sub[1], info, digArgs, homeUIInfo, rednetInfo, defaultTheme)

----- HOME MENU END (frontend) -----

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

--- LOG FRAME END ---

--- MOVE START ---

-- TODO implement move view
-- local moveInputFrame = sub[2]:addFrame():setPosition(1, 2):setSize("{parent.w}", 15)

-- local moveOptionFrame = moveInputFrame:addFrame():setPosition(2, 9):setSize(5, 1):setBackground(colors.gray):setForeground(colors.black)
-- local digCheckBoxLabel = moveOptionFrame:addLabel():setText("Dig"):setPosition(3, 1)
-- local digCheckbox = moveOptionFrame:addCheckbox():setPosition(1, 1):setBackground(colors.black):setForeground(colors.lightGray)

-- local moveAmountResetButton = moveInputFrame:addButton():setText("RESET"):setPosition(17,9):setSize(5,1)

-- local moveAmountInput = moveInputFrame:addInput():setPosition(10, 7):setSize(4, 1):setInputType("number"):setInputLimit(4):setValue("1")

-- local moveAmountResetButton = moveInputFrame:addButton():setText("RESET"):setPosition(34,7):setSize(5,1)

-- local moveAmountSub5Button = moveInputFrame:addButton():setText("-5"):setPosition(4, 7):setSize(2, 1)
-- local moveAmountSub1Button = moveInputFrame:addButton():setText("-1"):setPosition(7, 7):setSize(2, 1)
-- local moveAmountAdd1Button = moveInputFrame:addButton():setText("+1"):setPosition(15, 7):setSize(2, 1)
-- local moveAmountAdd5Button = moveInputFrame:addButton():setText("+5"):setPosition(18, 7):setSize(2, 1)

-- local forwardButton = moveInputFrame:addButton():setText("Fwd"):setPosition(9, 1):setSize(6, 1)
-- local backwardButton = moveInputFrame:addButton():setText("Back"):setPosition(9, 5):setSize(6, 1)
-- local upButton = moveInputFrame:addButton():setText("Up"):setPosition(16, 5):setSize(6, 1)
-- local downButton = moveInputFrame:addButton():setText("Down"):setPosition(2, 5):setSize(6, 1)
-- local turnLeftButton = moveInputFrame:addButton():setText("Left"):setPosition(2, 3):setSize(6, 1)
-- local turnRightButton = moveInputFrame:addButton():setText("Right"):setPosition(16, 3):setSize(6, 1)

-- local shiftLeftButton = moveInputFrame:addButton():setText("Shift-L"):setPosition(2, 11):setSize(7, 1)
-- local shiftRightButton = moveInputFrame:addButton():setText("Shift-R"):setPosition(10, 11):setSize(7, 1)

--- MOVE END ---
 
--- SETTINGS START ---

viewSettings.init(sub[3], computerInfo, rednetInfo, defaultTheme)

--- SETTINGS END ---

--- INPUT FRAME START ---

-- homeTurtleRefreshButton:onClick(function(self, event, button, x, y)
--     if (event == "mouse_click") and (button == 1) then
--         if rednetID ~= homeNetworkID:getValue() then
--             rednetID = homeNetworkID:getValue()
--             setSetting(settingRednetID, rednetID)
--             addLog(log, "Rednet Updated. ID: "..tostring(rednetID))
--         end
--         --updateConnectedTurtles()
--         --refreshConnectedTurtlesList()
--     end
-- end)


local function initializeProgramsDropdown()
    for i = 1, #programs do
        viewHome.getBasicDigSettingsGUI().programDropdown:addItem(programs[i])
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

local function sendCommand()
    local message = viewHome.getDigArgsFromUI()
    message.command = "run"
    rednet.broadcast(message, rednetUtil.getProtocol(rednetInfo))
    addLog(log, "Command Sent.")
    os.sleep(1) -- allow final update to arrive
end

local function listenForUpdates()
    while true do
        local event, update = os.pullEvent("digOS_job_update")
        local newLog = ""
        if type(update) == "string" then
            newLog = update
        else
            newLog = "WARN: Invalid Update"
        end
        addLog(log, newLog)
    end
end

local function sendDigProgram()
    parallel.waitForAny(sendCommand, listenForUpdates)
    sendThread:stop()
end

viewHome.getRunButton().runButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        sendThread:start(sendDigProgram)
    end
end)

viewHome.getResetButton().resetButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        viewHome.resetArgsUI()
        sendThread:stop()
    end
    
end)
--- INPUT FRAME END ---
--- 
--- Idea make a seperate screen to edit clipboard data

local function clipboardCopy(_info)
    clipboard = _info
    settingsUtil.set(PROG_SETTINGS.clipboard, _info)
    -- setSetting(settingClipboard, _info)
    addLog(log, "Clipboard: Info Saved")
end

local function clipboardPaste(_id)
    rednet.send(_id, clipboard, "digOS_clipboard_paste_info")
    addLog(log, "Clipboard: Info Requested")
end

local function runUpdateThread()
    while true do
        local id, update = rednet.receive("digOS_update"..rednetInfo.rednetID)
        if update.command == "update" then
            addLog(log, update.payload)
        elseif update.command == "clipboard_copy" then
            clipboardCopy(update)
        elseif update.command == "clipboard_paste" then
            clipboardPaste(id)
        else
            addLog(log, "Invalid Update Received.")
        end

    end
end

local function startUpdateThread()
    updateThread:start(runUpdateThread)
    addLog(log, "Update Thread Started.")
end

local function stopUpdateThread()
    updateThread:stop()
    addLog(log, "Update Thread Stopped.")
end

local function stopRednet()
    if rednetInfo.rednetOpen then
        rednetInfo.rednetOpen = false
        setRednetStatus(rednetInfo.rednetOpen)
        rednet.close()
        --rednetThread:stop()
        stopUpdateThread()
        addLog(log, "Rednet Closed")
    end
end

local function startRednet()
    if not rednetInfo.rednetOpen then
        rednetInfo.rednetOpen = true
        setRednetStatus(rednetInfo.rednetOpen)
        rednetInfo.modem = peripheral.find("modem", rednet.open)
        if rednetInfo.rednetID ~= viewSettings.get().homeNetworkID:getValue() then
            rednetInfo.rednetID = viewSettings.get().homeNetworkID:getValue()
        end
        settingsUtil.set(PROG_SETTINGS.rednetID, rednetInfo.rednetID)
        addLog(log, "Rednet Opened. ID: "..rednetInfo.rednetID)
        --rednetThread:start()
        startUpdateThread()
    end
end

local function startupRednet()
    rednetInfo.modem = peripheral.find("modem", rednet.open)
    addLog(log, "Rednet Opened. ID: "..rednetInfo.rednetID)
    --rednetThread:start()
    startUpdateThread()
end

local function toggleRednet()
    if rednetInfo.rednetOpen then
        stopRednet()
    else
        startRednet()
    end
    menubarRednetStatusButton:setBackground(digOSUtil.getMenubarRednetStatusButtonColor(rednetInfo, defaultTheme))
end

menubarRednetStatusButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        toggleRednet()
    end
end)

--- MOVE START (Backend) ---

local function sendMoveCommand()
    local message = { "move", moveAmount, moveCommand, moveDig }
    rednet.broadcast(message, getProtocol())
    addLog(log, "move command sent")
    os.sleep(1) -- allow final update to arrive
end

local function doMoveCommand()
    parallel.waitForAny(sendMoveCommand, listenForUpdates)
    sendThread:stop()
end

local function doMove()
    sendThread:start(doMoveCommand)
end

-- local function digCheckboxChange(self)
--     local checked = self:getValue()
--     if checked then
--         moveDig = false
--     else
--         moveDig = true
--     end
-- end
-- digCheckbox:onChange(digCheckboxChange)

-- moveAmountResetButton:onClick(function(self, event, button, x, y)
--     if (event == "mouse_click") and (button == 1) then
--         moveAmountInput:setValue("1")
--         digCheckbox:setValue(false)
--         moveCommand = ""
--         moveAmount = 1
--         moveDig = false
--     end
-- end)

-- local function setMoveAmount(_value)
--     moveAmount = _value
--     moveAmountInput:setValue(_value)
-- end

-- moveAmountAdd5Button:onClick(function(self, event, button, x, y)
--     if (event == "mouse_click") and (button == 1) then
--         local newValue = moveAmount + 5
--         if newValue <= 1000 then
--             setMoveAmount(newValue)
--         end
--     end
-- end)

-- moveAmountAdd1Button:onClick(function(self, event, button, x, y)
--     if (event == "mouse_click") and (button == 1) then
--         local newValue = moveAmount + 1
--         if newValue <= 1000 then
--             setMoveAmount(newValue)
--         end
--     end
-- end)

-- moveAmountSub1Button:onClick(function(self, event, button, x, y)
--     if (event == "mouse_click") and (button == 1) then
--         local newValue = moveAmount - 1
--         if newValue >= 1 then
--             setMoveAmount(newValue)
--         end
--     end
-- end)

-- moveAmountSub5Button:onClick(function(self, event, button, x, y)
--     if (event == "mouse_click") and (button == 1) then
--         local newValue = moveAmount - 5
--         if newValue >= 1 then
--             setMoveAmount(newValue)
--         end
--     end
-- end)

-- forwardButton:onClick(function(self, event, button, x, y)
--     if (event == "mouse_click") and (button == 1) then
--         moveCommand = "forward"
--         doMove()
--     end
-- end)

-- backwardButton:onClick(function(self, event, button, x, y)
--     if (event == "mouse_click") and (button == 1) then
--         moveCommand = "back"
--         doMove()
--     end
-- end)

-- upButton:onClick(function(self, event, button, x, y)
--     if (event == "mouse_click") and (button == 1) then
--         moveCommand = "up"
--         doMove()
--     end
-- end)

-- downButton:onClick(function(self, event, button, x, y)
--     if (event == "mouse_click") and (button == 1) then
--         moveCommand = "down"
--         doMove()
--     end
-- end)

-- shiftLeftButton:onClick(function(self, event, button, x, y)
--     if (event == "mouse_click") and (button == 1) then
--         moveCommand = "shift_left"
--         doMove()
--     end
-- end)

-- shiftRightButton:onClick(function(self, event, button, x, y)
--     if (event == "mouse_click") and (button == 1) then
--         moveCommand = "shift_right"
--         doMove()
--     end
-- end)

-- turnLeftButton:onClick(function(self, event, button, x, y)
--     if (event == "mouse_click") and (button == 1) then
--         moveCommand = "turn_left"
--         doMove()
--     end
-- end)

-- turnRightButton:onClick(function(self, event, button, x, y)
--     if (event == "mouse_click") and (button == 1) then
--         moveCommand = "turn_right"
--         doMove()
--     end
-- end)

--- MOVE END (Backend) ---

local function init()
    initRednetID()

    initializeProgramsDropdown()

    if rednetInfo.rednetOpen then
        startupRednet()
    else
        stopRednet()
    end
end

init()

basalt.autoUpdate()