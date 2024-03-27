-- digOS V2.0.0
-- Created by: ChefMooon

--PROGRAM TODO--
-- Add nil checks handle errors
-- Bug Fix Bug Fix
-- Redo programs download
-- Send updates back to remote

-- this will help filter broadcast messages
local programName = "digOS"
--local programVersion = "2.0.0"

local filePath = "basalt.lua"
if not (fs.exists(filePath)) then
    shell.run("wget run https://basalt.madefor.cc/install.lua release basalt-1.7.1.lua " .. filePath)
end
local basalt = require(filePath:gsub(".lua", ""))

local defaultPrograms = { "digOS-mid-out" }
if not (fs.exists(defaultPrograms[1]..".lua")) then
    shell.run("pastebin get X1m1iG4H digOS-mid-out"..".lua")
end

--TODO: exit of not a turtle

-- Variables
local  yPos, layersMined, blocksMined, turtleFuel = 0, 0, 0, 0
local turtleFuelSlot = 1
--local turtleOptimalFuel = 50
local turtleID = os.getComputerID()
local turtleLabel = os.getComputerLabel()
local turtleStatus = ""
local working, moving = false, false

-- Dig Options
local selectedProgram = ""
local length, width, height = 1, 1, 1
local offsetDir = "r"
local torch, chest, rts = false, false, false

local log = {}
local programs = {}

-- Preset Options
local saved1, saved2, saved3, saved4, saved5
local savedSelection = 0

-- Move Options
local moveCommand = ""
local moveAmount = 1
local moveDig = false

-- Rednet
local modemChannel = 11
local rednetOpen = false
local modem = peripheral.find("modem")
local rednetID
local remoteID = 0
local rednetStatus

-- Settings Definition
local settingRednetID = programName ..".rednetID"
settings.define(settingRednetID, {
    description = programName .. " - Rednet ID",
    default = 0,
    type = number
})

local settingRednetStatus = programName ..".rednetStatus"
settings.define(settingRednetStatus, { -- 0 off - 1 on
    description = programName .. " - Rednet Status",
    default = 0,
    type = number
})

local settingSaved1 = programName ..".saved1"
settings.define(settingSaved1, {
    description = programName .. " - Saved 1",
    default = ""
})

local settingSaved2 = programName ..".saved2"
settings.define(settingSaved2, {
    description = programName .. " - Saved 2",
    default = ""
})

local settingSaved3 = programName ..".saved3"
settings.define(settingSaved3, {
    description = programName .. " - Saved 3",
    default = ""
})

local settingSaved4 = programName ..".saved4"
settings.define(settingSaved4, {
    description = programName .. " - Saved 4",
    default = ""
})

local settingSaved5 = programName ..".saved5"
settings.define(settingSaved5, {
    description = programName .. " - Saved 5",
    default = ""
})

-- Settings Functions
local function setSetting(_name, _value)
    settings.set(_name, _value)
    settings.save()
end

local function getSetting(_name)
    return settings.get(_name)
end

settings.load()
saved1 = getSetting(settingSaved1)
saved2 = getSetting(settingSaved2)
saved3 = getSetting(settingSaved3)
saved4 = getSetting(settingSaved4)
saved5 = getSetting(settingSaved5)
rednetID = getSetting(settingRednetID)
rednetStatus = getSetting(settingRednetStatus)
if rednetStatus == 1 then
    rednetOpen = true
elseif rednetStatus == 0 then
    rednetOpen = false
end

-- PROGRAMS START --

local function refuelButton()
    -- TODO: give more information back on error?
    -- change to use shell.run() command?
    local currentFuel = turtle.getFuelLevel()
    turtle.select(turtleFuelSlot)
    if turtle.refuel() then
        local newFuel = turtle.getFuelLevel()
        return "Succesful Refuel. " .. tostring(newFuel - currentFuel) .. " Fuel added."
    else
        return "Unsuccessful Refuel."
    end
end

--- UTILITY ---
local function splitString(inputString)
    local words = {}
    for word in inputString:gmatch("%S+") do
        table.insert(words, word)
    end
    return words
end

-- TODO: upgrade also look in a directory /digOSprograms for any files
local function getTurtlePrograms()
    local programs = fs.find("digOS-*.lua")
    local programNames = {}
    for i = 1, #programs do
        local name = programs[i]:gsub("^.*/", ""):gsub("digOS%-", ""):gsub(".lua", "")
        table.insert(programNames, name)
    end
    return programNames
end

local function getTurtleIDLabel()
    local result = tostring(turtleID)
    if turtleLabel ~= nil then
        return result.."-"..turtleLabel
    end
    return result
end

local function getRednetID()
    if rednetID == 0 then
        local id = math.random(1, 99)
        rednetID = id
        setSetting(settingRednetID, id)
        return rednetID
    else
        rednetID = getSetting(settingRednetID)
        return rednetID
    end
end

local function setRednetStatus(_status)
    if _status then
        setSetting(settingRednetStatus, 1)
    else
        setSetting(settingRednetStatus, 0)
    end
end

local function getProtocol()
    return programName..":"..tostring(getRednetID())
end

local function getSavedButtonColor(_slot)
    local color = colors.black
    if _slot == 1 then
        if saved1 ~= "" then
            color = colors.yellow
        end
    elseif _slot == 2 then
        if saved2 ~= "" then
            color = colors.yellow
        end
    elseif _slot == 3 then
        if saved3 ~= "" then
            color = colors.yellow
        end
    elseif _slot == 4 then
        if saved4 ~= "" then
            color = colors.yellow
        end
    elseif _slot == 5 then
        if saved5 ~= "" then
            color = colors.yellow
        end
    end
    return color
end

local function getMenubarRednetStatusButtonColor()
    local onColor = colors.red
    local offColor = colors.black
    if rednetOpen then
        return onColor
    else
        return offColor
    end
end

local function getNetworkOffButtonColor()
    if rednetOpen then
        return colors.lightGray
    else
        return colors.black
    end
end

local function getNetworkOnButtonColor()
    if rednetOpen then
        return colors.black
    else
        return colors.lightGray
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
    :addItem("Basic")
    :addItem("Move")
    :addItem("Settings")
    :addItem("Info")

local menubarInfoFrame = main:addFrame():setPosition("{parent.w-7}", 1):setSize(7,1):setBackground(colors.gray)

local menubarRednetStatusButton = menubarInfoFrame:addButton():setText(""):setPosition(1, 1):setSize(1,1):setBackground(getMenubarRednetStatusButtonColor())

local programLabel = menubarInfoFrame:addLabel():setText("digOS"):setPosition(3, 1):setForeground(colors.yellow)

---------- **** FRONTEND START **** ----------
----- HOME MENU START (frontend) -----

local digThread = sub[1]:addThread()
local rednetThread = sub[1]:addThread()
local keyboardInputThread = sub[1]:addThread()

local logFrame = sub[1]:addFrame():setPosition(1, 9):setSize("{parent.w}", 4)
local logLabel = logFrame:addLabel():setText("Log:"):setPosition(1, 1)
local logList = logFrame:addList():setPosition(1, 2):setSize("{parent.w}", 3)

local homeFuelFrame = sub[1]:addFrame():setPosition(28, 7):setSize(11, 3)

local fuelLabel = homeFuelFrame:addLabel():setText("Fuel:"):setPosition(1, 1)
local fuelLevelLabel = homeFuelFrame:addLabel():setText(tostring(turtleFuel)):setPosition(6, 1)

local fuelButton = homeFuelFrame:addButton():setText("REFUEL"):setSize("{parent.w-1}", 1):setPosition(1, 2)

local inputFrame = sub[1]:addFrame():setPosition(1, 2):setSize(22, 4)

local programDropdownLabel = inputFrame:addLabel():setText("Program:"):setPosition(1, 1)

local programDropdown = inputFrame:addDropdown():setPosition(9, 1):setSize(14,1)

local lengthInputLabel = inputFrame:addLabel():setText("L:"):setPosition(1, 2)
local lengthInput = inputFrame:addInput():setPosition(3, 2):setSize(5, 1):setInputType("number"):setInputLimit(4):setValue(length)
local lengthSubButton = inputFrame:addButton():setText("<-"):setPosition(9, 2):setSize(2, 1)
local lengthAddButton = inputFrame:addButton():setText("->"):setPosition(11, 2):setSize(2, 1)

local widthInputLabel = inputFrame:addLabel():setText("W:"):setPosition(1, 3)
local widthInput = inputFrame:addInput():setPosition(3, 3):setSize(5, 1):setInputType("number"):setInputLimit(4):setValue(width)
local widthSubButton = inputFrame:addButton():setText("<-"):setPosition(9, 3):setSize(2, 1)
local widthAddButton = inputFrame:addButton():setText("->"):setPosition(11, 3):setSize(2, 1)

local heightInputLabel = inputFrame:addLabel():setText("H:"):setPosition(1, 4)
local heightInput = inputFrame:addInput():setPosition(3, 4):setSize(5, 1):setInputType("number"):setInputLimit(4):setValue(height)
local heightSubButton = inputFrame:addButton():setText("<-"):setPosition(9, 4):setSize(2, 1)
local heightAddButton = inputFrame:addButton():setText("->"):setPosition(11, 4):setSize(2, 1)

local offsetLeftButton = inputFrame:addButton():setText("L"):setPosition(14,2):setSize(1,1):setForeground(colors.lightGray)
local offsetRightButton = inputFrame:addButton():setText("R"):setPosition(15,2):setSize(1,1)

local torchCheckBoxLabel = inputFrame:addLabel():setText("Torch"):setPosition(18,2):setBackground(colors.gray):setForeground(colors.black)
local torchCheckbox = inputFrame:addCheckbox():setPosition(17,2):setBackground(colors.black):setForeground(colors.lightGray)

local chestCheckBoxLabel = inputFrame:addLabel():setText("Chest"):setPosition(18,3):setBackground(colors.gray):setForeground(colors.black)
local chestCheckbox = inputFrame:addCheckbox():setPosition(17,3):setBackground(colors.black):setForeground(colors.lightGray)

local rtsCheckBoxLabel = inputFrame:addLabel():setText("RTS"):setPosition(18,4):setSize(5,1):setBackground(colors.gray):setForeground(colors.black)
local rtsCheckbox = inputFrame:addCheckbox():setPosition(17,4):setBackground(colors.black):setForeground(colors.lightGray)

local savedFrame = sub[1]:addFrame():setPosition(28,2):setSize(11,4):setBackground(colors.gray)

local savedTitleFrame = savedFrame:addFrame():setPosition(1,1):setSize("{parent.w}",1):setBackground(colors.lightGray)
local savedLabel = savedTitleFrame:addLabel():setText("Presets"):setPosition(3,1)

local saved1Button = savedFrame:addButton():setText("1"):setPosition(2,2):setSize(1,1):setForeground(getSavedButtonColor(1))
local saved2Button = savedFrame:addButton():setText("2"):setPosition(4,2):setSize(1,1):setForeground(getSavedButtonColor(2))
local saved3Button = savedFrame:addButton():setText("3"):setPosition(6,2):setSize(1,1):setForeground(getSavedButtonColor(3))
local saved4Button = savedFrame:addButton():setText("4"):setPosition(8,2):setSize(1,1):setForeground(getSavedButtonColor(4))
local saved5Button = savedFrame:addButton():setText("5"):setPosition(10,2):setSize(1,1):setForeground(getSavedButtonColor(5))

local loadSavedButton = savedFrame:addButton():setText("LOAD"):setPosition(2,3):setSize(4,1)
local saveSavedButton = savedFrame:addButton():setText("SAVE"):setPosition(7,3):setSize(4,1)
local resetSavedButton = savedFrame:addButton():setText("RESET"):setPosition(4,4):setSize(5,1)

local clipboardFrame = sub[1]:addFrame():setPosition(15,7):setSize(7,2)

local copyButton = clipboardFrame:addButton():setText("COPY"):setSize(5,1):setPosition(1, 1)
local pasteButton = clipboardFrame:addButton():setText("PASTE"):setSize(5,1):setPosition(1, 2)

local buttonFrame = sub[1]:addFrame():setPosition(2,7):setSize(12,1)

local runButton = buttonFrame:addButton():setText("RUN"):setSize(5, 1):setPosition(1, 1)
local resetButton = buttonFrame:addButton():setText("RESET"):setSize(5, 1):setPosition(7, 1)

----- HOME MENU END (frontend) -----

----- MOVE MENU START (frontend) -----

local moveThread = sub[2]:addThread()
local moveInputFrame = sub[2]:addFrame():setPosition(1, 2):setSize("{parent.w}", 7)

local moveOptionFrame = moveInputFrame:addFrame():setPosition(23, 7):setSize(7, 3):setBackground(colors.gray):setForeground(colors.black)
local digCheckBoxLabel = moveOptionFrame:addLabel():setText("Dig"):setPosition(4, 1)
local digCheckbox = moveOptionFrame:addCheckbox():setPosition(2, 1):setBackground(colors.black):setForeground(colors.lightGray)

local moveAmountInput = moveInputFrame:addInput():setPosition(10, 7):setSize(4, 1):setInputType("number"):setInputLimit(4):setValue("1")

local moveAmountResetButton = moveInputFrame:addButton():setText("RESET"):setPosition(34,7):setSize(5,1)

local moveAmountSub5Button = moveInputFrame:addButton():setText("-5"):setPosition(4, 7):setSize(2, 1)
local moveAmountSub1Button = moveInputFrame:addButton():setText("-1"):setPosition(7, 7):setSize(2, 1)
local moveAmountAdd1Button = moveInputFrame:addButton():setText("+1"):setPosition(15, 7):setSize(2, 1)
local moveAmountAdd5Button = moveInputFrame:addButton():setText("+5"):setPosition(18, 7):setSize(2, 1)

local forwardButton = moveInputFrame:addButton():setText("Fwd"):setPosition(9, 1):setSize(6, 1)
local backwardButton = moveInputFrame:addButton():setText("Back"):setPosition(9, 5):setSize(6, 1)
local upButton = moveInputFrame:addButton():setText("Up"):setPosition(16, 5):setSize(6, 1)
local downButton = moveInputFrame:addButton():setText("Down"):setPosition(2, 5):setSize(6, 1)
local shiftLeftButton = moveInputFrame:addButton():setText("Shift-L"):setPosition(23, 1):setSize(7, 1)
local shiftRightButton = moveInputFrame:addButton():setText("Shift-R"):setPosition(31, 1):setSize(7, 1)
local turnLeftButton = moveInputFrame:addButton():setText("Left"):setPosition(2, 3):setSize(6, 1)
local turnRightButton = moveInputFrame:addButton():setText("Right"):setPosition(16, 3):setSize(6, 1)

----- MOVE MENU END (frontend) -----

----- SETTINGS MENU START (frontend) -----

local settingsFrame = sub[3]:addFrame():setPosition(1,2):setSize("{parent.w}", "{parent.h}")

local settingsFrameTitle = settingsFrame:addLabel():setText("Rednet Settings"):setPosition(2, 1)
local homeNetworkFrame = settingsFrame:addFrame():setPosition(2,3):setSize(20,3)

local homeTurtleIDLabel = homeNetworkFrame:addLabel():setText("ID:"):setPosition(1,1):setSize(3,1)
local homeTurtleIDFrame = homeNetworkFrame:addScrollableFrame():setPosition(4,1):setSize("{parent.w-3}",1):setDirection("horizontal")
local homeTurtleID = homeTurtleIDFrame:addLabel():setText(getTurtleIDLabel())

local homeNetworkLabel = homeNetworkFrame:addLabel():setText("Rednet:"):setPosition(1,2):setSize(7,1)
local homeNetworkID = homeNetworkFrame:addInput():setPosition(8,2):setSize(3,1):setInputType("number"):setValue(getRednetID()):setInputLimit(2)

local homeNetworkOffButton = homeNetworkFrame:addButton():setText("off"):setPosition(1,3):setSize(5,1):setForeground(getNetworkOffButtonColor())
local homeNetworkOnButton = homeNetworkFrame:addButton():setText("on"):setPosition(6,3):setSize(5,1):setForeground(getNetworkOnButtonColor())

----- SETTINGS MENU END (frontend) -----

----- INFO MENU START (frontend) -----

local programsInfoFrame = sub[4]:addFrame():setPosition(1,2):setSize("{parent.w}","{parent.h-2}")
local programsInfoTitle = programsInfoFrame:addLabel():setText("Programs"):setPosition(2,1)

local programsInfoList = programsInfoFrame:addList():setPosition(2,2):setSize(15,8)

local programDetailsFrame = programsInfoFrame:addFrame():setPosition(18,2)
local programDetailsLabel = programDetailsFrame:addLabel():setText("Details:"):setPosition(1,1)

----- INFO MENU END (frontend) -----
---------- **** FRONTEND END **** ----------

--- HOME MENU START ---

logList:onSelect(function(self, event, item)
    basalt.debug("Selected item: ", item.text)
end)

local function updateLog()
    logList:clear()
    for i = 1, #log do
        logList:addItem(log[i])
    end
end

local function addLog(log, newLog)
    table.insert(log, 1, newLog)
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
    fuelLevelLabel:setText(tostring(fuel))
end

fuelButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        addLog(log, refuelButton())
        updateFuelLabel(turtle.getFuelLevel())
    end
end)

local function initializeProgramsDropdown()
    for i = 1, #programs do
        programDropdown:addItem(programs[i])
    end
end

programDropdown:onChange(function(self, item)
    selectedProgram = tostring(item.text)
end)

local function initializeProgramsInfo()
    for i = 1, #programs do
        programsInfoList:addItem(programs[i])
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

lengthSubButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") then
        local newValue = lengthInput:getValue() - getNumberChange(button)
        if newValue > 0 then
            length = newValue
            lengthInput:setValue(length)
        end
    end
end)

lengthAddButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") then
        local newValue = lengthInput:getValue() + getNumberChange(button)
        if newValue < 1001 then
            length = newValue
            lengthInput:setValue(length)
        end
    end
end)

widthSubButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") then
        local newValue = widthInput:getValue() - getNumberChange(button)
        if newValue > 0 then
            width = newValue
            widthInput:setValue(width)
        end
    end
end)

widthAddButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") then
        local newValue = widthInput:getValue() + getNumberChange(button)
        if newValue < 1001 then
            width = newValue
            widthInput:setValue(width)
        end
    end
end)

heightSubButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") then
        local newValue = heightInput:getValue() - getNumberChange(button)
        if newValue > 0 then
            height = newValue
            heightInput:setValue(height)
        end
    end
end)

heightAddButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") then
        local newValue = heightInput:getValue() + getNumberChange(button)
        if newValue < 1001 then
            height = newValue
            heightInput:setValue(height)
        end
    end
end)

offsetLeftButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        self:setForeground(colors.black)
        offsetRightButton:setForeground(colors.lightGray)
        if offsetDir ~= "l" then
            offsetDir = "l"
        end
    end
end)

offsetRightButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        self:setForeground(colors.black)
        offsetLeftButton:setForeground(colors.lightGray)
        if offsetDir ~= "r" then
            offsetDir = "r"
        end
    end
end)

local function selectSaved(_select)
    if _select == 1 then
        saved1Button:setForeground(colors.lightGray)
        saved2Button:setForeground(getSavedButtonColor(2))
        saved3Button:setForeground(getSavedButtonColor(3))
        saved4Button:setForeground(getSavedButtonColor(4))
        saved5Button:setForeground(getSavedButtonColor(5))
    elseif _select == 2 then
        saved1Button:setForeground(getSavedButtonColor(1))
        saved2Button:setForeground(colors.lightGray)
        saved3Button:setForeground(getSavedButtonColor(3))
        saved4Button:setForeground(getSavedButtonColor(4))
        saved5Button:setForeground(getSavedButtonColor(5))
    elseif _select == 3 then
        saved1Button:setForeground(getSavedButtonColor(1))
        saved2Button:setForeground(getSavedButtonColor(2))
        saved3Button:setForeground(colors.lightGray)
        saved4Button:setForeground(getSavedButtonColor(4))
        saved5Button:setForeground(getSavedButtonColor(5))
    elseif _select == 4 then
        saved1Button:setForeground(getSavedButtonColor(1))
        saved2Button:setForeground(getSavedButtonColor(2))
        saved3Button:setForeground(getSavedButtonColor(3))
        saved4Button:setForeground(colors.lightGray)
        saved5Button:setForeground(getSavedButtonColor(5))
    elseif _select == 5 then
        saved1Button:setForeground(getSavedButtonColor(1))
        saved2Button:setForeground(getSavedButtonColor(2))
        saved3Button:setForeground(getSavedButtonColor(3))
        saved4Button:setForeground(getSavedButtonColor(4))
        saved5Button:setForeground(colors.lightGray)
    end
end

local function updateArgsUI(_program, _length, _width, _height, _offsetDir, _torch, _chest, _rts)
    --TODO: set program?
    length = _length
    width = _width
    height = _height
    offsetDir = _offsetDir
    if _torch == "true" then
        torch = true
    elseif _torch == "false" then
        torch = false
    end
    if _chest == "true" then
        chest = true
    elseif _chest == "false" then
        chest = false
    end
    if _rts == "true" then
        rts = true
    elseif _rts == "false" then
        rts = false
    end

    lengthInput:setValue(_length)
    widthInput:setValue(_width)
    heightInput:setValue(_height)

    if offsetDir == "l" then
        offsetLeftButton:setForeground(colors.black)
        offsetRightButton:setForeground(colors.lightGray)
    else
        offsetLeftButton:setForeground(colors.lightGray)
        offsetRightButton:setForeground(colors.black)
    end

    torchCheckbox:setValue(torch)
    chestCheckbox:setValue(chest)
    rtsCheckbox:setValue(rts)
end

local function saveArgsUI(_saveSlot)
    local saveArgs = { "digOS-" .. selectedProgram .. ".lua", tostring(length), tostring(width), tostring(height),
    tostring(offsetDir), tostring(torch), tostring(chest), tostring(rts) }
    local savedArgsString = table.concat(saveArgs, " ")

    setSetting(_saveSlot, savedArgsString)
    addLog(log, "Preset Saved.")
    return savedArgsString
end

local function resetSaved(_saveSlot)
    setSetting(_saveSlot, "")
    addLog(log, "Preset Reset.")
    return ""
end

local function loadSelectedSaved()
    if savedSelection == 0 then
        addLog(log, "Select a Preset.")
    else
        local saved = ""

        if savedSelection == 1 then
            saved = getSetting(settingSaved1)
        elseif savedSelection == 2 then
            saved = getSetting(settingSaved2)
        elseif savedSelection == 3 then
            saved = getSetting(settingSaved3)
        elseif savedSelection == 4 then
            saved = getSetting(settingSaved4)
        elseif savedSelection == 5 then
            saved = getSetting(settingSaved5)
        end

        if saved ~= nil and saved ~= "" then
            local savedArgs = splitString(saved)
            updateArgsUI(savedArgs[1], savedArgs[2], savedArgs[3], savedArgs[4], savedArgs[5], savedArgs[6], savedArgs[7], savedArgs[8])
            local newLog = "Preset "..tostring(savedSelection).." Loaded."
            addLog(log, newLog)
        else
            addLog(log, "No Saved Data.")
        end
    end
end

saved1Button:onClick(function(self, event, button, x, y)
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

saved2Button:onClick(function(self, event, button, x, y)
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

saved3Button:onClick(function(self, event, button, x, y)
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

saved4Button:onClick(function(self, event, button, x, y)
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

saved5Button:onClick(function(self, event, button, x, y)
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

loadSavedButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        loadSelectedSaved()
    end
end)

saveSavedButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        if savedSelection == 0 then
            addLog(log, "Select a Preset.")
        elseif savedSelection == 1 then
            saved1 = saveArgsUI(settingSaved1)
        elseif savedSelection == 2 then
            saved2 = saveArgsUI(settingSaved2)
        elseif savedSelection == 3 then
            saved3 = saveArgsUI(settingSaved3)
        elseif savedSelection == 4 then
            saved4 = saveArgsUI(settingSaved4)
        elseif savedSelection == 5 then
            saved5 = saveArgsUI(settingSaved5)
        end
    end
end)

resetSavedButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        if savedSelection == 0 then
            addLog(log, "Select a Preset.")
        elseif savedSelection == 1 then
            saved1 = resetSaved(settingSaved1)
        elseif savedSelection == 2 then
            saved2 = resetSaved(settingSaved2)
        elseif savedSelection == 3 then
            saved3 = resetSaved(settingSaved3)
        elseif savedSelection == 4 then
            saved4 = resetSaved(settingSaved4)
        elseif savedSelection == 5 then
            saved5 = resetSaved(settingSaved5)
        end
    end
end)

local function digOSForward(_count, _dig)
    for i = 1, _count do
        if _dig then
            while turtle.detect() do
                turtle.dig()
            end
        end
        turtle.forward()
    end
end

local function digOSBack(_count)
    for i = 1, _count do
        turtle.back()
    end
end

local function digOSUp(_count, _dig)
    for i = 1, _count do
        if _dig then
            while turtle.detectUp() do
                turtle.digUp()
            end
        end
        turtle.up()
    end
end

-- This could be used to pass the error information back, not needed for the move screen
local function digOSDown(_count, _dig)
    for i = 1, _count do
        if _dig then
            while turtle.detectDown() do
                turtle.digDown()
            end
        end
        local result, err = turtle.down()
        if not result then
            return result, err
        end
    end
    return true
end

local function runDigOSMove()
    addLog(log, "Move Thread Started.")
    moving = true
    if moveCommand == "forward" then
        digOSForward(moveAmount, moveDig)
    elseif moveCommand == "up" then
        digOSUp(moveAmount, moveDig)
    elseif moveCommand == "down" then
        digOSDown(moveAmount, moveDig)
    elseif moveCommand == "back" then
        digOSBack(moveAmount, moveDig)
    elseif moveCommand == "turn_left" then
        turtle.turnLeft()
    elseif moveCommand == "turn_right" then
        turtle.turnRight()
    elseif moveCommand == "shift_left" then
        turtle.turnLeft()
        digOSForward(moveAmount, moveDig)
        turtle.turnRight()
    elseif moveCommand == "shift_right" then
        turtle.turnRight()
        digOSForward(moveAmount, moveDig)
        turtle.turnLeft()
    end
    moveCommand = ""
    moveThread:stop()
    moving = false
    addLog(log, "Move Thread Stopped.")
end

local function sendJobUpdateToRemote(_message)
    if rednetOpen then
        updateMessage = { "update", _message }
        rednet.send(remoteID, updateMessage, "digOS_update"..rednetID)
    end
end

local function startMoveThread()
    if working == false and moving == false then
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
    local programArgs = { "digOS-" .. selectedProgram .. ".lua", "run", tostring(length), tostring(width), tostring(height),
        tostring(offsetDir), tostring(torch), tostring(chest), tostring(rts) }
    shell.run(table.concat(programArgs, " "))
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
        if rednetOpen then
            rednet.send(remoteID, updates, "digOS_job_update")
        end
        addLog(log, newLog)

        if updates[2] ~= nil and type(updates[2]) == "number" and turtleFuel ~= updates[2] then
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
    working = true
    parallel.waitForAny(startProgram, listenForUpdates, listenForInputs)
    digThread:stop()
    working = false
    addLog(log, "Dig Thread Stopped")
end

local function tryRunDig()
    if working == false and moving == false then -- maybe make a method to check for all threads/jobs
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
        local id, message = rednet.receive(getProtocol())
        if id and message then
            if message[1] == "info" then
                addLog(log, "Info Request.")
                local info = {getTurtleIDLabel(), turtleFuel, turtleStatus, programs}
                rednet.send(id, info, getProtocol())
            elseif message[1] == "run" then
                addLog(log, "Remote Dig command recieved.")
                remoteID = id
                selectedProgram = message[2]
                length = tonumber(message[3]) or 0
                width = tonumber(message[4]) or 0
                height = tonumber(message[5]) or 0
                offsetDir = message[6]
                torch = message[7]
                chest = message[8]
                rts = message[9]
                tryRunDig()
            elseif message[1] == "move" then
                addLog(log, "Remote Move command recieved.")
                moveAmount = tonumber(message[2]) --reset back to ui number?
                moveCommand = message[3]
                moveDig = message[4]
                startMoveThread()
                moveAmount = moveAmountInput:getValue()
            end
        end

        if message ~= nil and message[1] == "terminate" then
            addLog(log, "broke")
            break
        end
    end
    homeNetworkOffButton:setForeground(colors.black)
    homeNetworkOnButton:setForeground(colors.lightGray)
    rednetOpen = false
    setRednetStatus(rednetOpen)
    rednet.close()
    rednetThread:stop()
end

local function stopRednet()
    if rednetOpen then
        homeNetworkOffButton:setForeground(colors.black)
        homeNetworkOnButton:setForeground(colors.lightGray)
        rednetOpen = false
        setRednetStatus(rednetOpen)
        rednet.close()
        rednetThread:stop()
        addLog(log, "Rednet Closed")
    end
end

local function startRednet()
    if not rednetOpen then
        homeNetworkOffButton:setForeground(colors.lightGray)
        homeNetworkOnButton:setForeground(colors.black)
        rednetOpen = true
        setRednetStatus(rednetOpen)
        modem = peripheral.find("modem", rednet.open)
        if rednetID ~= homeNetworkID:getValue() then
            rednetID = homeNetworkID:getValue()
        end
        setSetting(settingRednetID, homeNetworkID:getValue())
        addLog(log, "Rednet Opened. ID: "..rednetID)
        rednetThread:start(receiveCommands)
    end
end

local function startupRednet()
    modem = peripheral.find("modem", rednet.open)
    addLog(log, "Rednet Opened. ID: "..rednetID)
    rednetThread:start(receiveCommands)
end

local function toggleRednet()
    if rednetOpen then
        stopRednet()
    else
        startRednet()
    end
    menubarRednetStatusButton:setBackground(getMenubarRednetStatusButtonColor())
end

homeNetworkOffButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        stopRednet()
        menubarRednetStatusButton:setBackground(getMenubarRednetStatusButtonColor())
    end
end)

homeNetworkOnButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        startRednet()
        menubarRednetStatusButton:setBackground(getMenubarRednetStatusButtonColor())
    end
end)

menubarRednetStatusButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        toggleRednet()
    end
end)

-- TODO: Create ClipboardThread so the program does not hang while waiting
local function clipboard(_function)
    if rednetOpen then
        if _function == "copy" then
            local copyArgs = { "digOS-" .. selectedProgram .. ".lua", tostring(length), tostring(width), tostring(height),
                tostring(offsetDir), tostring(torch), tostring(chest), tostring(rts) }
            local copyMessage = { "clipboard", "copy", table.concat(copyArgs, " ")}
            rednet.broadcast(copyMessage, "digOS_update"..rednetID)
            addLog(log, "Clipboard: Copy")
        elseif _function == "paste" then
            local pasteMessage = { "clipboard", "paste" }
            rednet.broadcast(pasteMessage, "digOS_update"..rednetID)
            -- get response and set ui
            local id, info = rednet.receive("digOS_clipboard_paste_info", 3)
            -- info format: _program, _length, _width, _height, _offsetDir, _torch, _chest, _rts
            if info then
                if info ~= "" then 
                    pasteInfo = splitString(info)
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

copyButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        clipboard("copy")
    end
end)

pasteButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        clipboard("paste")
    end
end)

local function runDig()
    selectedProgram = programDropdown:getItem(programDropdown:getItemIndex()).text
    length = tonumber(lengthInput:getValue()) or 0
    width = tonumber(widthInput:getValue()) or 0
    height = tonumber(heightInput:getValue()) or 0
    tryRunDig()
    updateFuelLabel(turtle.getFuelLevel())
end

runButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        runDig()
    end
end)

local function resetInput()
    programDropdown:selectItem(1)
    lengthInput:setValue("1")
    widthInput:setValue("1")
    heightInput:setValue("1")

    offsetDir = "r"
    offsetLeftButton:setForeground(colors.lightGray)
    offsetRightButton:setForeground(colors.black)

    torchCheckbox:setValue(false)
    chestCheckbox:setValue(false)
    rtsCheckbox:setValue(false)

    if working == true then
        digThread:stop()
        addLog(log, "Dig Thread Reset.")
    end
    turtle.select(1)
end

resetButton:onClick(function(self, event, button, x, y)
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
digCheckbox:onChange(digCheckboxChange)

moveAmountResetButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        moveAmountInput:setValue("1")
        digCheckbox:setValue(false)
        moveCommand = ""
        moveAmount = 1
        moveDig = false
    end
end)

local function setMoveAmount(_value)
    if _value <= 1000 and _value >= 1 then
        moveAmount = _value
        moveAmountInput:setValue(_value)
    end
end

moveAmountAdd5Button:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        setMoveAmount(moveAmount + 5)
    end
end)

moveAmountAdd1Button:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        setMoveAmount(moveAmount + 1)
    end
end)

moveAmountSub1Button:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        setMoveAmount(moveAmount - 1)
    end
end)

moveAmountSub5Button:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        setMoveAmount(moveAmount - 5)
    end
end)

local function doMove()
    moveAmount = moveAmountInput:getValue()
    startMoveThread()
end

forwardButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        moveCommand = "forward"
        doMove()
    end
end)

backwardButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        moveCommand = "back"
        doMove()
    end
end)

upButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        moveCommand = "up"
        doMove()
    end
end)

downButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        moveCommand = "down"
        doMove()
    end
end)

shiftLeftButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        moveCommand = "shift_left"
        doMove()
    end
end)

shiftRightButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        moveCommand = "shift_right"
        doMove()
    end
end)

turnLeftButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        moveCommand = "turn_left"
        doMove()
    end
end)

turnRightButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        moveCommand = "turn_right"
        doMove()
    end
end)

----- MOVE MENU END -----

----- SETTINGS MENU START (backend) -----

local function chestCheckboxChange(self)
    if self:getValue() then
        chest = false
    else
        chest = true
    end
end
chestCheckbox:onChange(chestCheckboxChange)

local function torchCheckboxChange(self)
    if self:getValue() then
        torch = false
    else
        torch = true
    end
end
torchCheckbox:onChange(torchCheckboxChange)

local function rtsCheckboxChange(self)
    if self:getValue() then
        rts = false
    else
        rts = true
    end
end
rtsCheckbox:onChange(rtsCheckboxChange)

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
    turtleFuel = turtle.getFuelLevel()
    updateFuelLabel(turtleFuel)

    programs = getTurtlePrograms()
    initializeProgramsDropdown()
    initializeProgramsInfo()

    if modem == nil then
        homeNetworkFrame:hide()
    end

    if #programs > 0 then
        selectedProgram = programs[1]
    end

    keyboardInputThread:start(keyboardInput)

    if rednetOpen then
        startupRednet()
    else
        stopRednet()
    end
end

init()

basalt.autoUpdate()