local programInfo = {
    name = "digOSRemote",
    version = "2.0.2",
    author = "ChefMooon"
}

--PROGRAM TODO--
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
local viewControl = mooonUtil.getProgram(mooonUtil.lib.digOSRemote.digOSRemoteViewControl.path)
local viewInfo = mooonUtil.getProgram(mooonUtil.lib.digOSRemote.digOSRemoteViewInfo.path)
local viewSettings = mooonUtil.getProgram(mooonUtil.lib.digOSRemote.digOSRemoteViewSettings.path)

----- REQUIRE END -----

local broadcastFilter = "digOS"

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

local digArgs = digUtil.createDigArgsTable("", "", 1, 1, 1, "r", false, digUtil.CONST.DEFAULT_TORCH_SPACING, digUtil.CONST.DEFAULT_TORCH_SLOT, false, digUtil.CONST.DEFAULT_CHEST_SLOT, false, false, false, false, "", "")

local log = {}
local programs = { "clear-mid-out" }
local connectedTurtles = {}

-- Preset Options
-- local saved1, saved2, saved3, saved4, saved5
local savedSelection = 0

local clipboard = ""

-- Move Options
-- TODO: Refactor me to currentSettings.*
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

local connectedTurtleInfo = {}

-- SETTINGS --

local PROG_SETTINGS = {
    rednetID = settingsUtil.define(programInfo.name, "rednetID", 0),
    rednetStatus = settingsUtil.define(programInfo.name, "rednetStatus", 0),
    clipboard = settingsUtil.define(programInfo.name, "clipboard", ""),
    saved1 = settingsUtil.define(programInfo.name, "saved1", ""),
    saved2 = settingsUtil.define(programInfo.name, "saved2", ""),
    saved3 = settingsUtil.define(programInfo.name, "saved3", ""),
    saved4 = settingsUtil.define(programInfo.name, "saved4", ""),
    saved5 = settingsUtil.define(programInfo.name, "saved5", ""),
    moveCommand = settingsUtil.define(programInfo.name, "moveCommand", ""),
    moveAmount = settingsUtil.define(programInfo.name, "moveAmount", 1),
    moveDig = settingsUtil.define(programInfo.name, "moveDig", false)
}

settings.load()

local moveDefaultSettings = {
    moveCommand = "",
    moveAmount = 1,
    moveDig = false
}

local currentSettings = {
    saved1 = settingsUtil.get(PROG_SETTINGS.saved1),
    saved2 = settingsUtil.get(PROG_SETTINGS.saved2),
    saved3 = settingsUtil.get(PROG_SETTINGS.saved3),
    saved4 = settingsUtil.get(PROG_SETTINGS.saved4),
    saved5 = settingsUtil.get(PROG_SETTINGS.saved5),
    moveCommand = moveDefaultSettings.moveCommand,
    moveAmount = moveDefaultSettings.moveAmount,
    moveDig = moveDefaultSettings.moveDig
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

local function initConnectedTurtleInfo()
    rednet.broadcast({ command = "digOSRemote_startup_info" }, rednetUtil.getProtocol(rednetInfo).."_info")
end

-- local function updateConnectedTurtles()
--     connectedTurtleInfo = settingsUtil.get(PROG_SETTINGS.connectedTurtleInfo)
-- end

local function addConnectedTurtleInfo(_id, _info)
    connectedTurtleInfo[_id] = _info
    -- settingsUtil.set(PROG_SETTINGS.connectedTurtleInfo, connectedTurtleInfo)
end

-- PGROGRAMS END --

-- TODO: do something else if on a pc (use term or a monitor?)
local w,h = 0,0
if pocket then
    w, h = term.getSize()
end

local main = basalt.createFrame():setTheme({ FrameBG = colors.lightGray, FrameFG = colors.black })

-- local sub = {
--     main:addFrame():setPosition(1, 3):setSize("{parent.w}", "{parent.h - 2}"),
--     main:addFrame():setPosition(1, 3):setSize("{parent.w}", "{parent.h - 2}"):hide(),
--     main:addFrame():setPosition(1, 3):setSize("{parent.w}", "{parent.h - 2}"):hide(),
--     main:addFrame():setPosition(1, 3):setSize("{parent.w}", "{parent.h - 2}"):hide(),
-- }

local sub = {}
sub["Home"] = main:addFrame():setPosition(1, 2):setSize("{parent.w}", "{parent.h - 1}")
sub["Move"] = main:addFrame():setPosition(1, 2):setSize("{parent.w}", "{parent.h - 1}"):hide()
sub["Info"] = main:addFrame():setPosition(1, 2):setSize("{parent.w}", "{parent.h - 1}"):hide()

sub["Adv"] = main:addFrame():setPosition(1, 2):setSize("{parent.w}", "{parent.h - 1}"):hide()

local sendThread = sub["Home"]:addThread()

local function openSubFrame(id)
    if (sub[id] ~= nil) then
        for k, v in pairs(sub) do
            v:hide()
        end
        sub[id]:show()
    end
end

local menubar = main:addMenubar()
    :setSize("{parent.w-8}", 1)
    :onSelect(function(self, event, item)
        openSubFrame(self:getItem(self:getItemIndex()).text)
    end)
    :addItem("Home")
    :addItem("Move")
    :addItem("Info")
    :addItem("Adv")

-- local menubar2 = main:addMenubar()
--     :setPosition(1, 2)
--     :setSize("{parent.w-1}", 1)
--         :onSelect(function(self, event, item)
--             openSubFrame(self:getItem(self:getItemIndex()).text)
--         end)
--         :addItem("Adv")

local menubarInfoFrame = main:addFrame():setPosition("{parent.w-7}", 1):setSize(7,1):setBackground(colors.gray)

local menubarRednetStatusButton = menubarInfoFrame:addButton():setText(""):setPosition(1, 1):setSize(1,1):setBackground(digOSUtil.getMenubarRednetStatusButtonColor(rednetInfo, defaultTheme))

local programLabel = menubarInfoFrame:addLabel():setText(programInfo.name):setPosition(3, 1):setForeground(colors.yellow)

--local rednetThread = sub[1]:addThread()
local updateThread = sub["Home"]:addThread()

---------- **** FRONTEND START **** ----------
----- HOME MENU START (frontend) -----

local homeUIInfo = {
    saved1ButtonColor = digOSUtil.getSavedButtonColor(1, currentSettings, defaultTheme),
    saved2ButtonColor = digOSUtil.getSavedButtonColor(2, currentSettings, defaultTheme),
    saved3ButtonColor = digOSUtil.getSavedButtonColor(3, currentSettings, defaultTheme),
    saved4ButtonColor = digOSUtil.getSavedButtonColor(4, currentSettings, defaultTheme),
    saved5ButtonColor = digOSUtil.getSavedButtonColor(5, currentSettings, defaultTheme)
}

viewHome.init(sub["Home"], info, digArgs, homeUIInfo, rednetInfo, defaultTheme)

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

--- LOG FRAME END ---

--- MOVE START ---

viewControl.init(sub["Move"], currentSettings, defaultTheme)

--- MOVE END ---

--- INFO START ---

viewInfo.init(sub["Info"], computerInfo, rednetInfo, defaultTheme)

--- INFO END ---

--- SETTINGS START ---

viewSettings.init(sub["Adv"], computerInfo, rednetInfo, defaultTheme)

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

local function sendGetTimeEsitmateCommand()
    local message = viewHome.getDigArgsFromUI()
    message.command = "time"
    for k, v in pairs(connectedTurtleInfo) do
        rednet.send(k, message, rednetUtil.getProtocol(rednetInfo))
        break
    end
    addLog(log, "Time request Sent.")
end

local function sendGetTorchEsitmateCommand()
    local message = viewHome.getDigArgsFromUI()
    message.command = "torch"
    -- rednet.broadcast(message, rednetUtil.getProtocol(rednetInfo))
    for k, v in pairs(connectedTurtleInfo) do
        rednet.send(k, message, rednetUtil.getProtocol(rednetInfo))
        break
    end
    addLog(log, "Torch request Sent.")
end

local function sendCommand()
    local message = viewHome.getDigArgsFromUI()
    message.command = "run"
    rednet.broadcast(message, rednetUtil.getProtocol(rednetInfo))
    addLog(log, "Command Sent.")
end

local function sendDigProgram()
    parallel.waitForAny(sendCommand)
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

viewHome.get().timeEstimateButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        sendGetTimeEsitmateCommand()
    end
end)

viewHome.get().torchEstimateButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        sendGetTorchEsitmateCommand()
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

local function initUpdateThread()
    while true do
        local id, update = rednet.receive("digOS_update"..rednetInfo.rednetID)
        if update.command == "update" then
            if update.payload then
                addLog(log, update.payload)
            elseif update.data then
                connectedTurtleInfo[id] = update.data
                viewInfo.updateConectedTurtleInfoGUI(connectedTurtleInfo, defaultTheme)
            end
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
    updateThread:start(initUpdateThread)
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
    initConnectedTurtleInfo()
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
    currentSettings.moveCommand = settingsUtil.get(PROG_SETTINGS.moveCommand)
    local message = { command = "move", moveAmount = currentSettings.moveAmount, moveCommand = currentSettings.moveCommand, moveDig = currentSettings.moveDig }
    rednet.broadcast(message, rednetUtil.getProtocol(rednetInfo))
    addLog(log, tostring(currentSettings.moveAmount))
    addLog(log, "move command sent")
    os.sleep(1) -- allow final update to arrive
end

local function doMoveCommand()
    parallel.waitForAny(sendMoveCommand)
    sendThread:stop()
end

local function doMove()
    sendThread:start(doMoveCommand)
end

local function digCheckboxChange(self)
    if self:getValue() then
        currentSettings.moveDig = false
    else
        currentSettings.moveDig = true
    end
    settingsUtil.set(PROG_SETTINGS.moveDig, currentSettings.moveDig)
end
viewControl.getMoveButtons().digCheckbox:onChange(digCheckboxChange)

viewControl.getMoveButtons().moveAmountResetButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        viewControl.getMoveButtons().moveAmountInput:setValue("1")
        viewControl.getMoveButtons().digCheckbox:setValue(false)
        moveCommand = ""
        currentSettings.moveAmount = 1
        moveDig = false
    end
end)

local function setMoveAmount(_value)
    if _value <= 1000 and _value >= 1 then
        currentSettings.moveAmount = _value
        settingsUtil.set(PROG_SETTINGS.moveAmount, _value)
        viewControl.getMoveButtons().moveAmountInput:setValue(_value)
    end
end

viewControl.getMoveButtons().moveAmountAddButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") then
        if (button == 1) then
            setMoveAmount(math.min(currentSettings.moveAmount + 1, digUtil.CONST.DIG_MAX))
        elseif (button == 2) then
            setMoveAmount(math.min(currentSettings.moveAmount + 5, digUtil.CONST.DIG_MAX))
        end
    end
end)

viewControl.getMoveButtons().moveAmountSubButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") then
        if (button == 1) then
            setMoveAmount(math.max(currentSettings.moveAmount - 1, digUtil.CONST.DIG_MIN))
        elseif (button == 2) then
            setMoveAmount(math.max(currentSettings.moveAmount - 5, digUtil.CONST.DIG_MIN))
        end
    end
end)

viewControl.getMoveButtons().forwardButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") then
        if (button == 1) then
            settingsUtil.set(PROG_SETTINGS.moveCommand, "forward")
        elseif (button == 2) then
            settingsUtil.set(PROG_SETTINGS.moveCommand, "forward_once")
        end
        doMove()
    end
end)

viewControl.getMoveButtons().backwardButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") then
        if (button == 1) then
            settingsUtil.set(PROG_SETTINGS.moveCommand, "back")
        elseif (button == 2) then
            settingsUtil.set(PROG_SETTINGS.moveCommand, "back_once")
        end
        doMove()
    end
end)

viewControl.getMoveButtons().upButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") then
        if (button == 1) then
            settingsUtil.set(PROG_SETTINGS.moveCommand, "up")
        elseif (button == 2) then
            settingsUtil.set(PROG_SETTINGS.moveCommand, "up_once")
        end
        doMove()
    end
end)

viewControl.getMoveButtons().downButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") then
        if (button == 1) then
            settingsUtil.set(PROG_SETTINGS.moveCommand, "down")
        elseif (button == 2) then
            settingsUtil.set(PROG_SETTINGS.moveCommand, "down_once")
        end
        doMove()
    end
end)

viewControl.getMoveButtons().shiftLeftButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") then
        if (button == 1) then
            settingsUtil.set(PROG_SETTINGS.moveCommand, "shift_left")
        elseif (button == 2) then
            settingsUtil.set(PROG_SETTINGS.moveCommand, "shift_left_once")
        end
        doMove()
    end
end)

viewControl.getMoveButtons().shiftRightButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") then
        if (button == 1) then
            settingsUtil.set(PROG_SETTINGS.moveCommand, "shift_right")
        elseif (button == 2) then
            settingsUtil.set(PROG_SETTINGS.moveCommand, "shift_right_once")
        end
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