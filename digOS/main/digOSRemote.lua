-- digOSRemote V1.0.0
-- Created by: ChefMooon

--PROGRAM TODO--
-- 
-- 

local programName = "digOSRemote"
local programVersion = "1.0.0"

local broadcastFilter = "digOS"

local filePath = "basalt.lua"
if not (fs.exists(filePath)) then
    shell.run("wget run https://basalt.madefor.cc/install.lua release latest.lua " .. filePath)
end
local basalt = require(filePath:gsub(".lua", ""))

-- Selected Turtle Info
local selectedID = ""
local selectedFuel = ""
local selectedStatus = ""

-- Dig Options
local selectedProgram = ""
local length, width, height = 1, 1, 1
local offsetDir = "r"
local torch, chest, rts = false, false, false

local log = {}
local programs = { "mid-out" }
local connectedTurtles = {}

-- Preset Options
local saved1, saved2, saved3, saved4, saved5
local savedSelection = 0

local clipboard = ""

-- Move Options
local moveCommand = ""
local moveAmount = 1
local moveDig = false

-- Rednet
local modemChannel = 11
local rednetOpen = false
local modem = peripheral.find("modem", rednet.open)
local rednetID
local remoteID = 0
local rednetStatus

-- Settings Definition
local settingRednetID = programName ..".rednetID"
local settingRednetIDDefault = 0
settings.define(settingRednetID, {
    description = programName .. " - Rednet ID",
    default = settingRednetIDDefault,
    type = number
})

local settingRednetStatus = programName ..".rednetStatus"
local settingRednetStatusDefault = 0 -- 0 off - 1 on
settings.define(settingRednetStatus, {
    description = programName .. " - Rednet Status",
    default = settingRednetStatusDefault,
    type = number
})

local settingSaved1 = programName ..".saved1"
local settingSaved1Default = ""
settings.define(settingSaved1, {
    description = programName .. " - Saved 1",
    default = settingSaved1Default
})

local settingSaved2 = programName ..".saved2"
local settingSaved2Default = ""
settings.define(settingSaved2, {
    description = programName .. " - Saved 2",
    default = settingSaved2Default
})

local settingSaved3 = programName ..".saved3"
local settingSaved3Default = ""
settings.define(settingSaved3, {
    description = programName .. " - Saved 3",
    default = settingSaved3Default
})

local settingSaved4 = programName ..".saved4"
local settingSaved4Default = ""
settings.define(settingSaved4, {
    description = programName .. " - Saved 4",
    default = settingSaved4Default
})

local settingSaved5 = programName ..".saved5"
local settingSaved5Default = ""
settings.define(settingSaved5, {
    description = programName .. " - Saved 5",
    default = settingSaved5Default
})

local settingClipboard = programName ..".clipboard"
local settingClipboardDefault = ""
settings.define(settingClipboard, {
    description = programName .. " - Clipboard",
    default = settingClipboardDefault
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
clipboard = getSetting(settingClipboard)
rednetID = getSetting(settingRednetID)
rednetStatus = getSetting(settingRednetStatus)
if rednetStatus == 1 then
    rednetOpen = true
elseif rednetStatus == 0 then
    rednetOpen = false
end

--- UTILITY ---
local function splitString(inputString)
    local words = {}
    for word in inputString:gmatch("%S+") do
        table.insert(words, word)
    end
    return words
end

local function getProtocol()
    return broadcastFilter..":"..tostring(rednetID)
end

local function updateConnectedTurtles()
    rednet.broadcast({"info", tostring(remoteID)}, getProtocol())

    while true do
        local id, message = rednet.receive(getProtocol())
        if id then
            table.insert(connectedTurtles, message)
        else
            break
        end
    end
end

local function connectedTurtleToString(connectedTurtle)
    return connectedTurtle[1].." "..connectedTurtle[2].." "..connectedTurtle[3]
end

local function getRednetID()
    --TODO: check for saved if not create a new one
    if rednetID == settingRednetIDDefault then
        local id = math.random(1, 99)
        rednetID = id
        setSetting(settingRednetID, id)
        return rednetID
    else
        rednetID = getSetting(settingRednetID)
        return rednetID--rednetID
    end
end

local function setRednetStatus(_status)
    if _status then
        setSetting(settingRednetStatus, 1)
    else
        setSetting(settingRednetStatus, 0)
    end
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

local menubarRednetStatusButton = menubarInfoFrame:addButton():setText(""):setPosition(1, 1):setSize(1,1):setBackground(getMenubarRednetStatusButtonColor())

local programLabel = menubarInfoFrame:addLabel():setText(broadcastFilter):setPosition(3, 1):setForeground(colors.yellow)

--local rednetThread = sub[1]:addThread()
local updateThread = sub[1]:addThread()

---------- **** FRONTEND START **** ----------
----- HOME MENU START (frontend) -----

local homeTitleFrame = sub[1]:addFrame():setPosition(1, 1):setSize("{parent.w}", 4)

local homeNetworkLabel = homeTitleFrame:addLabel():setText("Rednet"):setPosition(2,2)
local homeTurtleLabel = homeTitleFrame:addLabel():setText("ID:"):setPosition(2,3)
local homeNetworkID = homeTitleFrame:addInput():setPosition(5,3):setSize(3,1):setInputType("number"):setValue(getRednetID()):setInputLimit(3) -- TODO: use saved first or create a random one

local homeTurtleRefreshButton = homeTitleFrame:addButton():setText("Update"):setPosition(2,4):setSize(6,1)
 --- INPUT START ---
 local inputFrame = sub[1]:addFrame():setPosition(1, 7):setSize("{parent.w}", 6)

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

local buttonFrame = inputFrame:addFrame():setPosition(2,6):setSize(12,1)

local runButton = buttonFrame:addButton():setText("RUN"):setSize(5, 1):setPosition(1, 1)
local resetButton = buttonFrame:addButton():setText("RESET"):setSize(5, 1):setPosition(7, 1)

--- INPUT END ---

local savedFrame = sub[1]:addFrame():setPosition(12,2):setSize(11,4):setBackground(colors.gray)

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

--- TURTLE FRAME START ---
local homeTurtleFrame = sub[1]:addFrame():setPosition(1,5):setSize("{parent.w}", 4):hide()
--local homeTurtleLabel = homeTurtleFrame:addLabel():setText("Connected Turtles"):setPosition(1,1)
local homeConnectedTurtleFrame = homeTurtleFrame:addScrollableFrame():setPosition(1,1):setSize(10,4):setBackground(colors.gray)
--list of turtles on the same frequency
local connectedTurtlesList = homeConnectedTurtleFrame:addList():setPosition(1,1):setSize("{parent.w}", 4)
local function refreshConnectedTurtlesList()
    connectedTurtlesList:clear()
    for i = 1, #connectedTurtles do
        connectedTurtlesList:addItem(connectedTurtleToString(connectedTurtles[i]))
    end
end

local homeTurtleInfoFrame = homeTurtleFrame:addFrame():setPosition(12,2):setSize(14,3):hide()
local homeTurtleInfoIDLabel = homeTurtleInfoFrame:addLabel():setText("ID:"):setPosition(1,1)
local homeTurtleInfoIDFrame = homeTurtleInfoFrame:addScrollableFrame():setPosition(4,1):setSize(10, 1):setDirection("horizontal")
local homeTurtleInfoID = homeTurtleInfoIDFrame:addLabel():setText(selectedID):setPosition(1,1)

local homeTurtleInfoFuelLabel = homeTurtleInfoFrame:addLabel():setText("Fuel:"):setPosition(1,2)
local homeTurtleInfoFuelFrame = homeTurtleInfoFrame:addScrollableFrame():setPosition(6,2):setSize(8, 1):setDirection("horizontal")
local homeTurtleInfoFuel = homeTurtleInfoFuelFrame:addLabel():setText(selectedFuel):setPosition(1,1)

local homeTurtleInfoFuelLabel = homeTurtleInfoFrame:addLabel():setText("Status:"):setPosition(1,3)
local homeTurtleInfoFuelFrame = homeTurtleInfoFrame:addScrollableFrame():setPosition(8,3):setSize(6, 1):setDirection("horizontal")
local homeTurtleInfoFuel = homeTurtleInfoFuelFrame:addLabel():setText(selectedStatus):setPosition(1,1)

local function updateHomeTurtleInfoFrame(info)
    local info = splitString(info)
    homeTurtleInfoID:setText(info[1])
    homeTurtleInfoFuel:setText(info[2])
    homeTurtleInfoFuel:setText(info[3])
end

connectedTurtlesList:onSelect(function(self, event, item)
    updateHomeTurtleInfoFrame(item.text)
end)



--- TURTLE FRAME END ---

--- LOG FRAME START ---
local logFrame = sub[1]:addFrame():setPosition(1, 14):setSize("{parent.w}", 7)
local logLabel = logFrame:addLabel():setText("Log:"):setPosition(1, 1)
local logList = logFrame:addList():setPosition(1, 2):setSize("{parent.w}", 6)
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
--- LOG FRAME END ---

--- MOVE START ---

local moveInputFrame = sub[2]:addFrame():setPosition(1, 2):setSize("{parent.w}", 15)

local moveOptionFrame = moveInputFrame:addFrame():setPosition(2, 9):setSize(5, 1):setBackground(colors.gray):setForeground(colors.black)
local digCheckBoxLabel = moveOptionFrame:addLabel():setText("Dig"):setPosition(3, 1)
local digCheckbox = moveOptionFrame:addCheckbox():setPosition(1, 1):setBackground(colors.black):setForeground(colors.lightGray)

local moveAmountResetButton = moveInputFrame:addButton():setText("RESET"):setPosition(17,9):setSize(5,1)

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
local turnLeftButton = moveInputFrame:addButton():setText("Left"):setPosition(2, 3):setSize(6, 1)
local turnRightButton = moveInputFrame:addButton():setText("Right"):setPosition(16, 3):setSize(6, 1)

local shiftLeftButton = moveInputFrame:addButton():setText("Shift-L"):setPosition(2, 11):setSize(7, 1)
local shiftRightButton = moveInputFrame:addButton():setText("Shift-R"):setPosition(10, 11):setSize(7, 1)

--- MOVE END ---

--- INPUT FRAME START ---

homeTurtleRefreshButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        if rednetID ~= homeNetworkID:getValue() then
            rednetID = homeNetworkID:getValue()
            setSetting(settingRednetID, rednetID)
            addLog(log, "Rednet Updated. ID: "..tostring(rednetID))
        end
        --updateConnectedTurtles()
        --refreshConnectedTurtlesList()
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

local function chestCheckboxChange(self)
    local checked = self:getValue()
    if checked then
        chest = false
    else
        chest = true
    end
end
chestCheckbox:onChange(chestCheckboxChange)

local function torchCheckboxChange(self)
    local checked = self:getValue()
    if checked then
        torch = false
    else
        torch = true
    end
end
torchCheckbox:onChange(torchCheckboxChange)

local function rtsCheckboxChange(self)
    local checked = self:getValue()
    if checked then
        rts = false
    else
        rts = true
    end
end
rtsCheckbox:onChange(rtsCheckboxChange)

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
    torchCheckbox:setValue(torch)
    chestCheckbox:setValue(chest)
    rtsCheckbox:setValue(rts)
end

local function saveArgsUI(_saveSlot)
    saveArgs = { "digOS-" .. selectedProgram .. ".lua", tostring(length), tostring(width), tostring(height),
    tostring(offsetDir), tostring(torch), tostring(chest), tostring(rts) }
    savedArgsString = table.concat(saveArgs, " ")

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
            saved1 =  saveArgsUI(settingSaved1)
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



local function sendCommand()
    local message = { "run", selectedProgram, tostring(length), tostring(width), tostring(height),
        tostring(offsetDir), tostring(torch), tostring(chest), tostring(rts) }
    rednet.broadcast(message, getProtocol())
    addLog(log, "command sent")
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

runButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        selectedProgram = programDropdown:getItem(programDropdown:getItemIndex()).text
        length = tonumber(lengthInput:getValue()) or 0
        width = tonumber(widthInput:getValue()) or 0
        height = tonumber(heightInput:getValue()) or 0

        sendThread:start(sendDigProgram)
    end
end)

resetButton:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        programDropdown:selectItem(1)
        lengthInput:setValue("1")
        widthInput:setValue("1")
        heightInput:setValue("1")

        torchCheckbox:setValue(false)
        chestCheckbox:setValue(false)
        rtsCheckbox:setValue(false)
    end
end)

--- INPUT FRAME END ---

local function clipboardCopy(_info)
    clipboard = _info
    setSetting(settingClipboard, _info)
    addLog(log, "Clipboard: Info Saved")
end

local function clipboardPaste(_id)
    rednet.send(_id, clipboard, "digOS_clipboard_paste_info")
    addLog(log, "Clipboard: Info Requested")
end

local function runUpdateThread()
    while true do
        local id, update = rednet.receive("digOS_update"..rednetID)
        if update[1] == "update" then
            addLog(log, update[2])
        elseif update[1] == "clipboard" then
            if update[2] == "copy" then
                clipboardCopy(update[3])
            elseif update[2] == "paste" then
                clipboardPaste(id)
            else
                addLog(log, "Clipboard: Error")
            end
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
    if rednetOpen then
        rednetOpen = false
        setRednetStatus(rednetOpen)
        rednet.close()
        --rednetThread:stop()
        stopUpdateThread()
        addLog(log, "Rednet Closed")
    end
end

local function startRednet()
    if not rednetOpen then
        rednetOpen = true
        setRednetStatus(rednetOpen)
        modem = peripheral.find("modem", rednet.open)
        if rednetID ~= homeNetworkID:getValue() then
            rednetID = homeNetworkID:getValue()
        end
        setSetting(settingRednetID, homeNetworkID:getValue())
        addLog(log, "Rednet Opened. ID: "..rednetID)
        --rednetThread:start()
        startUpdateThread()
    end
end

local function startupRednet()
    modem = peripheral.find("modem", rednet.open)
    addLog(log, "Rednet Opened. ID: "..rednetID)
    --rednetThread:start()
    startUpdateThread()
end

local function toggleRednet()
    if rednetOpen then
        stopRednet()
    else
        startRednet()
    end
    menubarRednetStatusButton:setBackground(getMenubarRednetStatusButtonColor())
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

local function digCheckboxChange(self)
    local checked = self:getValue()
    if checked then
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
    moveAmount = _value
    moveAmountInput:setValue(_value)
end

moveAmountAdd5Button:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        local newValue = moveAmount + 5
        if newValue <= 1000 then
            setMoveAmount(newValue)
        end
    end
end)

moveAmountAdd1Button:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        local newValue = moveAmount + 1
        if newValue <= 1000 then
            setMoveAmount(newValue)
        end
    end
end)

moveAmountSub1Button:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        local newValue = moveAmount - 1
        if newValue >= 1 then
            setMoveAmount(newValue)
        end
    end
end)

moveAmountSub5Button:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        local newValue = moveAmount - 5
        if newValue >= 1 then
            setMoveAmount(newValue)
        end
    end
end)

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

--- MOVE END (Backend) ---

local function init()
    initializeProgramsDropdown()

    if rednetOpen then
        startupRednet()
    else
        stopRednet()
    end
end

init()

basalt.autoUpdate()