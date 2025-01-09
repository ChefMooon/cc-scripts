local programInfo = {
    name = "digOSRemoteViewHome",
    version = "1.0.0",
    author = "ChefMooon"
}

local digUtil = require("mooonOS/common/digUtil")

local view = {}

local homeFrame

local logFrame
local logLabel
local logList

local basicDigSettingsGUI = {}

-- might need to make these values local
-- local buttonFrame

local mainButtonFrame = {}

local legendGUI = {}

local advancedDigSettingsGUI = {}

local advancedSettingsSelectionGUI = {}

local savedGUI = {}

local clipboardGUI = {}

local inventoryControllerGUI = {
    inventorySlotSelect = {}
}

local function onClickTheme(self)
    self:setBackground(colors.yellow)
    self:setForeground(colors.black)
end

local function onReleaseTheme(self)
    self:setBackground(colors.gray)
    self:setForeground(colors.black)
end

local function getOffsetValue()
    if basicDigSettingsGUI.offsetLeftButton:getForeground() == colors.black then
        return "l"
    elseif basicDigSettingsGUI.offsetRightButton:getForeground() == colors.black then
        return "r"
    end
end

local function trySlotSelect(slot)
    if slot >= 1 and slot <= 16 then
        turtle.select(slot)
    end
end

local function getInventorySlotInputValue(input)
    local value = tonumber(input:getValue())
    if value < 1 then
        return 1
    elseif value > 16 then
        return 16
    else
        return value
    end
end

local function getTorchDistanceInputValue(input)
    local value = tonumber(input:getValue())
    if value < digUtil.CONST.TORCH_SPACING_MIN then
        return digUtil.CONST.TORCH_SPACING_MIN
    elseif value > digUtil.CONST.TORCH_SPACING_MAX then
        return digUtil.CONST.TORCH_SPACING_MAX
    else
        return value
    end
end

local function getNumberChange(button)
    local result = 0
    if button == 1 then
        result = 1
    elseif button == 2 then
        result = 5
    end
    return result
end


function view.initBasicDigSettingsGUI(frame, digArgs, homeUIInfo, theme)
    basicDigSettingsGUI.frame = frame:addFrame():setPosition(1, 2):setSize("{parent.w}", 4)

    basicDigSettingsGUI.programDropdownLabel = basicDigSettingsGUI.frame:addLabel():setText("Program:"):setPosition(1, 1)

    basicDigSettingsGUI.programDropdown = basicDigSettingsGUI.frame:addDropdown():setPosition(9, 1):setSize(15,1)

    basicDigSettingsGUI.lengthInputLabel = basicDigSettingsGUI.frame:addLabel():setText("L:"):setPosition(1, 2)
    basicDigSettingsGUI.lengthInput = basicDigSettingsGUI.frame:addInput():setPosition(3, 2):setSize(5, 1):setInputType("number"):setInputLimit(4):setValue(digArgs.length)
    basicDigSettingsGUI.lengthSubButton = basicDigSettingsGUI.frame:addButton():setText("\17"):setPosition(9, 2):setSize(2, 1):onClick(function(self)onClickTheme(self)end):onRelease(function(self)onReleaseTheme(self)end)
    basicDigSettingsGUI.lengthAddButton = basicDigSettingsGUI.frame:addButton():setText("\16"):setPosition(11, 2):setSize(2, 1):onClick(function(self)onClickTheme(self)end):onRelease(function(self)onReleaseTheme(self)end)

    basicDigSettingsGUI.widthInputLabel = basicDigSettingsGUI.frame:addLabel():setText("W:"):setPosition(1, 3)
    basicDigSettingsGUI.widthInput = basicDigSettingsGUI.frame:addInput():setPosition(3, 3):setSize(5, 1):setInputType("number"):setInputLimit(4):setValue(digArgs.width)
    basicDigSettingsGUI.widthSubButton = basicDigSettingsGUI.frame:addButton():setText("\17"):setPosition(9, 3):setSize(2, 1):onClick(function(self)onClickTheme(self)end):onRelease(function(self)onReleaseTheme(self)end)
    basicDigSettingsGUI.widthAddButton = basicDigSettingsGUI.frame:addButton():setText("\16"):setPosition(11, 3):setSize(2, 1):onClick(function(self)onClickTheme(self)end):onRelease(function(self)onReleaseTheme(self)end)

    basicDigSettingsGUI.heightInputLabel = basicDigSettingsGUI.frame:addLabel():setText("H:"):setPosition(1, 4)
    basicDigSettingsGUI.heightInput = basicDigSettingsGUI.frame:addInput():setPosition(3, 4):setSize(5, 1):setInputType("number"):setInputLimit(4):setValue(digArgs.height)
    basicDigSettingsGUI.heightSubButton = basicDigSettingsGUI.frame:addButton():setText("\17"):setPosition(9, 4):setSize(2, 1):onClick(function(self)onClickTheme(self)end):onRelease(function(self)onReleaseTheme(self)end)
    basicDigSettingsGUI.heightAddButton = basicDigSettingsGUI.frame:addButton():setText("\16"):setPosition(11, 4):setSize(2, 1):onClick(function(self)onClickTheme(self)end):onRelease(function(self)onReleaseTheme(self)end)

    basicDigSettingsGUI.offsetLeftButton = basicDigSettingsGUI.frame:addButton():setText("\171"):setPosition(14, 2):setSize(1, 1):setForeground(colors.lightGray)
    basicDigSettingsGUI.offsetRightButton = basicDigSettingsGUI.frame:addButton():setText("\187"):setPosition(15, 2):setSize(1, 1)

    basicDigSettingsGUI.torchCheckBoxLabel = basicDigSettingsGUI.frame:addLabel():setText("Torch"):setPosition(18, 2):setBackground(colors.gray):setForeground(colors.black)
    basicDigSettingsGUI.torchCheckbox = basicDigSettingsGUI.frame:addCheckbox():setPosition(17, 2):setBackground(colors.black):setForeground(colors.lightGray)

    basicDigSettingsGUI.chestCheckBoxLabel = basicDigSettingsGUI.frame:addLabel():setText("Chest"):setPosition(18, 3):setBackground(colors.gray):setForeground(colors.black)
    basicDigSettingsGUI.chestCheckbox = basicDigSettingsGUI.frame:addCheckbox():setPosition(17, 3):setBackground(colors.black):setForeground(colors.lightGray)

    basicDigSettingsGUI.rtsCheckBoxLabel = basicDigSettingsGUI.frame:addLabel():setText("RTS"):setPosition(18, 4):setSize(5, 1):setBackground(colors.gray):setForeground(colors.black)
    basicDigSettingsGUI.rtsCheckbox = basicDigSettingsGUI.frame:addCheckbox():setPosition(17, 4):setBackground(colors.black):setForeground(colors.lightGray)

    basicDigSettingsGUI.lengthSubButton:onClick(function(self, event, button, x, y)
        if (event == "mouse_click") then
            local newValue = basicDigSettingsGUI.lengthInput:getValue() - getNumberChange(button)
            if newValue >= digUtil.CONST.DIG_MIN then
                basicDigSettingsGUI.lengthInput:setValue(newValue)
            end
        end
    end)
    basicDigSettingsGUI.lengthAddButton:onClick(function(self, event, button, x, y)
        if (event == "mouse_click") then
            local newValue = basicDigSettingsGUI.lengthInput:getValue() + getNumberChange(button)
            if newValue <= digUtil.CONST.DIG_MAX then
                basicDigSettingsGUI.lengthInput:setValue(newValue)
            end
        end
    end)

    basicDigSettingsGUI.widthSubButton:onClick(function(self, event, button, x, y)
        if (event == "mouse_click") then
            local newValue = basicDigSettingsGUI.widthInput:getValue() - getNumberChange(button)
            if newValue >= digUtil.CONST.DIG_MIN then
                basicDigSettingsGUI.widthInput:setValue(newValue)
            end
        end
    end)
    basicDigSettingsGUI.widthAddButton:onClick(function(self, event, button, x, y)
        if (event == "mouse_click") then
            local newValue = basicDigSettingsGUI.widthInput:getValue() + getNumberChange(button)
            if newValue <= digUtil.CONST.DIG_MAX then
                basicDigSettingsGUI.widthInput:setValue(newValue)
            end
        end
    end)

    basicDigSettingsGUI.heightSubButton:onClick(function(self, event, button, x, y)
        if (event == "mouse_click") then
            local newValue = basicDigSettingsGUI.heightInput:getValue() - getNumberChange(button)
            if newValue >= digUtil.CONST.DIG_MIN then
                basicDigSettingsGUI.heightInput:setValue(newValue)
            end
        end
    end)
    basicDigSettingsGUI.heightAddButton:onClick(function(self, event, button, x, y)
        if (event == "mouse_click") then
            local newValue = basicDigSettingsGUI.heightInput:getValue() + getNumberChange(button)
            if newValue <= digUtil.CONST.DIG_MAX then
                basicDigSettingsGUI.heightInput:setValue(newValue)
            end
        end
    end)

    basicDigSettingsGUI.offsetLeftButton:onClick(function(self, event, button, x, y)
        if (event == "mouse_click") then
            if self:getForeground() == colors.lightGray then
                self:setForeground(colors.black)
                basicDigSettingsGUI.offsetRightButton:setForeground(colors.lightGray)
            end
        end
    end)
    basicDigSettingsGUI.offsetRightButton:onClick(function(self, event, button, x, y)
        if (event == "mouse_click") then
            if self:getForeground() == colors.lightGray then
                self:setForeground(colors.black)
                basicDigSettingsGUI.offsetLeftButton:setForeground(colors.lightGray)
            end
        end
    end)
end

function view.initAdvancedDigSettingsGUI(frame, digArgs, theme)
    advancedDigSettingsGUI.frame = frame:addFrame():setPosition("{parent.w-16}", 7):setSize(12, 6):hide()

    advancedDigSettingsGUI.ignoreInventoryCheckboxFrame = advancedDigSettingsGUI.frame:addFrame():setPosition(1, 1):setSize("{parent.w-1/2}", 1):setBackground(colors.gray)
    advancedDigSettingsGUI.ignoreInventoryCheckbox = advancedDigSettingsGUI.ignoreInventoryCheckboxFrame:addCheckbox():setPosition(1, 1):setBackground(colors.black):setForeground(colors.lightGray)
    advancedDigSettingsGUI.ignoreInventoryCheckboxLabel = advancedDigSettingsGUI.ignoreInventoryCheckboxFrame:addLabel():setText("\120Inv"):setPosition(2, 1)

    advancedDigSettingsGUI.ignoreFuelCheckboxFrame = advancedDigSettingsGUI.frame:addFrame():setPosition(7, 1):setSize("{parent.w-1/2}", 1):setBackground(colors.gray)
    advancedDigSettingsGUI.ignoreFuelCheckbox = advancedDigSettingsGUI.ignoreFuelCheckboxFrame:addCheckbox():setPosition(1, 1):setBackground(colors.black):setForeground(colors.lightGray)
    advancedDigSettingsGUI.ignoreFuelCheckboxLabel = advancedDigSettingsGUI.ignoreFuelCheckboxFrame:addLabel():setText("\120Fuel"):setPosition(2, 1)

    advancedDigSettingsGUI.noPickupCheckboxFrame = advancedDigSettingsGUI.frame:addFrame():setPosition(1, 2):setSize("{parent.w-1}", 1):setBackground(colors.gray)
    advancedDigSettingsGUI.noPickupCheckbox = advancedDigSettingsGUI.noPickupCheckboxFrame:addCheckbox():setPosition(1, 1):setBackground(colors.black):setForeground(colors.lightGray)
    advancedDigSettingsGUI.noPickupCheckboxLabel = advancedDigSettingsGUI.noPickupCheckboxFrame:addLabel():setText("Drop All"):setPosition(3, 1)

    advancedDigSettingsGUI.torchDistanceFrame = advancedDigSettingsGUI.frame:addFrame():setPosition(1, 3):setSize("{parent.w-1}", 1):setBackground(colors.gray)
    advancedDigSettingsGUI.torchDistanceInput = advancedDigSettingsGUI.torchDistanceFrame:addInput():setPosition(1, 1):setSize(4, 1):setInputType("number"):setInputLimit(2):setValue(digArgs.torch.distance)
    advancedDigSettingsGUI.torchDistanceDecreaseButton = advancedDigSettingsGUI.torchDistanceFrame:addButton():setText("\17"):setPosition(5, 1):setSize(1, 1)
    advancedDigSettingsGUI.torchDistanceIncreaseButton = advancedDigSettingsGUI.torchDistanceFrame:addButton():setText("\16"):setPosition(6, 1):setSize(1, 1)
    advancedDigSettingsGUI.torchDistanceLabel = advancedDigSettingsGUI.torchDistanceFrame:addLabel():setText("TSpace"):setPosition(7, 1)

    advancedDigSettingsGUI.torchSlotFrame = advancedDigSettingsGUI.frame:addFrame():setPosition(1, 4):setSize("{parent.w-1}", 1):setBackground(colors.gray)
    advancedDigSettingsGUI.torchSlotInput = advancedDigSettingsGUI.torchSlotFrame:addInput():setPosition(1, 1):setSize(4, 1):setInputType("number"):setInputLimit(2):setValue(digArgs.torch.slot)
    advancedDigSettingsGUI.torchSlotDecreaseButton = advancedDigSettingsGUI.torchSlotFrame:addButton():setText("\17"):setPosition(5, 1):setSize(1, 1)
    advancedDigSettingsGUI.torchSlotIncreaseButton = advancedDigSettingsGUI.torchSlotFrame:addButton():setText("\16"):setPosition(6, 1):setSize(1, 1)
    advancedDigSettingsGUI.torchSlotLabel = advancedDigSettingsGUI.torchSlotFrame:addLabel():setText("TSlot"):setPosition(7, 1)

    advancedDigSettingsGUI.chestSlotFrame = advancedDigSettingsGUI.frame:addFrame():setPosition(1, 5):setSize("{parent.w-1}", 1):setBackground(colors.gray)
    advancedDigSettingsGUI.chestSlotInput = advancedDigSettingsGUI.chestSlotFrame:addInput():setPosition(1, 1):setSize(4, 1):setInputType("number"):setInputLimit(2):setValue(digArgs.chest.slot)
    advancedDigSettingsGUI.chestSlotDecreaseButton = advancedDigSettingsGUI.chestSlotFrame:addButton():setText("\17"):setPosition(5, 1):setSize(1, 1)
    advancedDigSettingsGUI.chestSlotIncreaseButton = advancedDigSettingsGUI.chestSlotFrame:addButton():setText("\16"):setPosition(6, 1):setSize(1, 1)
    advancedDigSettingsGUI.chestSlotLabel = advancedDigSettingsGUI.chestSlotFrame:addLabel():setText("CSlot"):setPosition(7, 1)

    advancedDigSettingsGUI.torchDistanceDecreaseButton:onClick(function(self, event, button, x, y)
        if (event == "mouse_click") then
            local value = tonumber(advancedDigSettingsGUI.torchDistanceInput:getValue()) - getNumberChange(button)
            if value >= digUtil.CONST.TORCH_SPACING_MIN then
                advancedDigSettingsGUI.torchDistanceInput:setValue(value)
            elseif value <= digUtil.CONST.TORCH_SPACING_MIN then
                advancedDigSettingsGUI.torchDistanceInput:setValue(digUtil.CONST.TORCH_SPACING_MIN)
            end
        end
    end):onClick(function(self)onClickTheme(self)end):onRelease(function(self)onReleaseTheme(self)end)
    advancedDigSettingsGUI.torchDistanceIncreaseButton:onClick(function(self, event, button, x, y)
        if (event == "mouse_click") then
            local value = tonumber(advancedDigSettingsGUI.torchDistanceInput:getValue()) + getNumberChange(button)
            if value <= digUtil.CONST.TORCH_SPACING_MAX then
                advancedDigSettingsGUI.torchDistanceInput:setValue(value)
            elseif value >= digUtil.CONST.TORCH_SPACING_MAX then
                advancedDigSettingsGUI.torchDistanceInput:setValue(digUtil.CONST.TORCH_SPACING_MAX)
            end
        end
    end):onClick(function(self)onClickTheme(self)end):onRelease(function(self)onReleaseTheme(self)end)

    advancedDigSettingsGUI.torchSlotDecreaseButton:onClick(function(self, event, button, x, y)
        if (event == "mouse_click") then
            local value = tonumber(advancedDigSettingsGUI.torchSlotInput:getValue()) - getNumberChange(button)
            if value >= 1 then
                advancedDigSettingsGUI.torchSlotInput:setValue(value)
            elseif value <= 1 then
                advancedDigSettingsGUI.torchSlotInput:setValue(1)
            end
        end
    end):onClick(function(self)onClickTheme(self)end):onRelease(function(self)onReleaseTheme(self)end)
    advancedDigSettingsGUI.torchSlotIncreaseButton:onClick(function(self, event, button, x, y)
        if (event == "mouse_click") then
            local value = tonumber(advancedDigSettingsGUI.torchSlotInput:getValue()) + getNumberChange(button)
            if value <= 16 then
                advancedDigSettingsGUI.torchSlotInput:setValue(value)
            elseif value >= 16 then
                advancedDigSettingsGUI.torchSlotInput:setValue(16)
            end
        end
    end):onClick(function(self)onClickTheme(self)end):onRelease(function(self)onReleaseTheme(self)end)

    advancedDigSettingsGUI.chestSlotDecreaseButton:onClick(function(self, event, button, x, y)
        if (event == "mouse_click") then
            local value = tonumber(advancedDigSettingsGUI.chestSlotInput:getValue()) - getNumberChange(button)
            if value >= 1 then
                advancedDigSettingsGUI.chestSlotInput:setValue(value)
            elseif value <= 1 then
                advancedDigSettingsGUI.chestSlotInput:setValue(1)
            end
        end
    end):onClick(function(self)onClickTheme(self)end):onRelease(function(self)onReleaseTheme(self)end)
    advancedDigSettingsGUI.chestSlotIncreaseButton:onClick(function(self, event, button, x, y)
        if (event == "mouse_click") then
            local value = tonumber(advancedDigSettingsGUI.chestSlotInput:getValue()) + getNumberChange(button)
            if value <= 16 then
                advancedDigSettingsGUI.chestSlotInput:setValue(value)
            elseif value >= 16 then
                advancedDigSettingsGUI.chestSlotInput:setValue(16)
            end
        end
    end):onClick(function(self)onClickTheme(self)end):onRelease(function(self)onReleaseTheme(self)end)

end

function view.initSavedGUI(frame, homeUIInfo, theme)
    savedGUI.frame = frame:addFrame():setPosition("{parent.w-16}", 7):setSize(11,3):setBackground(colors.gray):hide()

    savedGUI.saved1Button = savedGUI.frame:addButton():setText("1"):setPosition(2,1):setSize(1,1):setForeground(homeUIInfo.saved1ButtonColor)
    savedGUI.saved2Button = savedGUI.frame:addButton():setText("2"):setPosition(4,1):setSize(1,1):setForeground(homeUIInfo.saved2ButtonColor)
    savedGUI.saved3Button = savedGUI.frame:addButton():setText("3"):setPosition(6,1):setSize(1,1):setForeground(homeUIInfo.saved3ButtonColor)
    savedGUI.saved4Button = savedGUI.frame:addButton():setText("4"):setPosition(8,1):setSize(1,1):setForeground(homeUIInfo.saved4ButtonColor)
    savedGUI.saved5Button = savedGUI.frame:addButton():setText("5"):setPosition(10,1):setSize(1,1):setForeground(homeUIInfo.saved5ButtonColor)

    savedGUI.loadSavedButton = savedGUI.frame:addButton():setText("LOAD"):setPosition(2,2):setSize(4,1):onClick(function(self)onClickTheme(self)end):onRelease(function(self)onReleaseTheme(self)end)
    savedGUI.saveSavedButton = savedGUI.frame:addButton():setText("SAVE"):setPosition(7,2):setSize(4,1):onClick(function(self)onClickTheme(self)end):onRelease(function(self)onReleaseTheme(self)end)
    savedGUI.resetSavedButton = savedGUI.frame:addButton():setText("RESET"):setPosition(4,3):setSize(5,1):onClick(function(self)onClickTheme(self)end):onRelease(function(self)onReleaseTheme(self)end)
end

function view.initAdvanedInventoryControllerGUI(frame, homeUIInfo, digArgs, theme)
    inventoryControllerGUI.frame = frame:addFrame():setPosition("{parent.w-16}", 7):setSize(12, 6):hide()

    inventoryControllerGUI.directionButtonFrame = inventoryControllerGUI.frame:addFrame():setPosition(2, 1):setSize(3, 3)

    inventoryControllerGUI.northButton = inventoryControllerGUI.directionButtonFrame:addButton():setText("\30"):setPosition(2, 1):setSize(1, 1)
        :onClick(function(self)onClickTheme(self)end):onRelease(function(self)onReleaseTheme(self)end)
    inventoryControllerGUI.eastButton = inventoryControllerGUI.directionButtonFrame:addButton():setText("\16"):setPosition(3, 2):setSize(1, 1)
        :onClick(function(self)onClickTheme(self)end):onRelease(function(self)onReleaseTheme(self)end)
    inventoryControllerGUI.southButton = inventoryControllerGUI.directionButtonFrame:addButton():setText("\31"):setPosition(2, 2):setSize(1, 1)
        :onClick(function(self)onClickTheme(self)end):onRelease(function(self)onReleaseTheme(self)end)
    inventoryControllerGUI.westButton = inventoryControllerGUI.directionButtonFrame:addButton():setText("\17"):setPosition(1, 2):setSize(1, 1)
        :onClick(function(self)onClickTheme(self)end):onRelease(function(self)onReleaseTheme(self)end)

    inventoryControllerGUI.northButton:onClick(function(self, event, button, x, y)
        if (event == "mouse_click") and (button == 1) then
            trySlotSelect(turtle.getSelectedSlot() - 4)
        end
    end)
    inventoryControllerGUI.eastButton:onClick(function(self, event, button, x, y)
        if (event == "mouse_click") and (button == 1) then
            trySlotSelect(turtle.getSelectedSlot() + 1)
        end
    end)
    inventoryControllerGUI.southButton:onClick(function(self, event, button, x, y)
        if (event == "mouse_click") and (button == 1) then
            trySlotSelect(turtle.getSelectedSlot() + 4)
        end
    end)
    inventoryControllerGUI.westButton:onClick(function(self, event, button, x, y)
        if (event == "mouse_click") and (button == 1) then
            trySlotSelect(turtle.getSelectedSlot() - 1)
        end
    end)

    inventoryControllerGUI.useButton = inventoryControllerGUI.frame:addButton():setText("USE"):setPosition(6, 1):setSize(3, 1):onClick(function(self)onClickTheme(self)end):onRelease(function(self)onReleaseTheme(self)end)
    inventoryControllerGUI.digButton = inventoryControllerGUI.frame:addButton():setText("DIG"):setPosition(9, 1):setSize(3, 1):onClick(function(self)onClickTheme(self)end):onRelease(function(self)onReleaseTheme(self)end)
    inventoryControllerGUI.dropButton = inventoryControllerGUI.frame:addButton():setText("DROP"):setPosition(7, 2):setSize(4, 1):onClick(function(self)onClickTheme(self)end):onRelease(function(self)onReleaseTheme(self)end)

    inventoryControllerGUI.useButton:onClick(function(self, event, button, x, y)
        if (event == "mouse_click") and (button == 1) then
            turtle.place()
        end
    end)
    inventoryControllerGUI.digButton:onClick(function(self, event, button, x, y)
        if (event == "mouse_click") and (button == 1) then
            turtle.dig()
        end
    end)
    inventoryControllerGUI.dropButton:onClick(function(self, event, button, x, y)
        if (event == "mouse_click") and (button == 1) then
            turtle.drop()
        end
    end)

    inventoryControllerGUI.inventorySlotSelectFrame = inventoryControllerGUI.frame:addFrame():setPosition(1, 4):setSize(12, 3)

    inventoryControllerGUI.inventorySlotSelect.button1 = inventoryControllerGUI.inventorySlotSelectFrame:addButton():setText("1"):setPosition(1, 1):setSize(2, 1)
    inventoryControllerGUI.inventorySlotSelect.button2 = inventoryControllerGUI.inventorySlotSelectFrame:addButton():setText("2"):setPosition(3, 1):setSize(2, 1)
    inventoryControllerGUI.inventorySlotSelect.button3 = inventoryControllerGUI.inventorySlotSelectFrame:addButton():setText("3"):setPosition(5, 1):setSize(2, 1)
    inventoryControllerGUI.inventorySlotSelect.button4 = inventoryControllerGUI.inventorySlotSelectFrame:addButton():setText("4"):setPosition(7, 1):setSize(2, 1)
    inventoryControllerGUI.inventorySlotSelect.button5 = inventoryControllerGUI.inventorySlotSelectFrame:addButton():setText("5"):setPosition(9, 1):setSize(2, 1)
    inventoryControllerGUI.inventorySlotSelect.button6 = inventoryControllerGUI.inventorySlotSelectFrame:addButton():setText("6"):setPosition(11, 1):setSize(2, 1)

    inventoryControllerGUI.inventorySlotSelect.button7 = inventoryControllerGUI.inventorySlotSelectFrame:addButton():setText("7"):setPosition(1, 2):setSize(2, 1)
    inventoryControllerGUI.inventorySlotSelect.button8 = inventoryControllerGUI.inventorySlotSelectFrame:addButton():setText("8"):setPosition(3, 2):setSize(2, 1)
    inventoryControllerGUI.inventorySlotSelect.button9 = inventoryControllerGUI.inventorySlotSelectFrame:addButton():setText("9"):setPosition(5, 2):setSize(2, 1)
    inventoryControllerGUI.inventorySlotSelect.button10 = inventoryControllerGUI.inventorySlotSelectFrame:addButton():setText("10"):setPosition(7, 2):setSize(2, 1)
    inventoryControllerGUI.inventorySlotSelect.button11 = inventoryControllerGUI.inventorySlotSelectFrame:addButton():setText("11"):setPosition(9, 2):setSize(2, 1)
    inventoryControllerGUI.inventorySlotSelect.button12 = inventoryControllerGUI.inventorySlotSelectFrame:addButton():setText("12"):setPosition(11, 2):setSize(2, 1)

    inventoryControllerGUI.inventorySlotSelect.button13 = inventoryControllerGUI.inventorySlotSelectFrame:addButton():setText("13"):setPosition(1, 3):setSize(2, 1)
    inventoryControllerGUI.inventorySlotSelect.button14 = inventoryControllerGUI.inventorySlotSelectFrame:addButton():setText("14"):setPosition(3, 3):setSize(2, 1)
    inventoryControllerGUI.inventorySlotSelect.button15 = inventoryControllerGUI.inventorySlotSelectFrame:addButton():setText("15"):setPosition(5, 3):setSize(2, 1)
    inventoryControllerGUI.inventorySlotSelect.button16 = inventoryControllerGUI.inventorySlotSelectFrame:addButton():setText("16"):setPosition(7, 3):setSize(2, 1)

    local slots = {
        inventoryControllerGUI.inventorySlotSelect.button1,
        inventoryControllerGUI.inventorySlotSelect.button2,
        inventoryControllerGUI.inventorySlotSelect.button3,
        inventoryControllerGUI.inventorySlotSelect.button4,
        inventoryControllerGUI.inventorySlotSelect.button5,
        inventoryControllerGUI.inventorySlotSelect.button6,
        inventoryControllerGUI.inventorySlotSelect.button7,
        inventoryControllerGUI.inventorySlotSelect.button8,
        inventoryControllerGUI.inventorySlotSelect.button9,
        inventoryControllerGUI.inventorySlotSelect.button10,
        inventoryControllerGUI.inventorySlotSelect.button11,
        inventoryControllerGUI.inventorySlotSelect.button12,
        inventoryControllerGUI.inventorySlotSelect.button13,
        inventoryControllerGUI.inventorySlotSelect.button14,
        inventoryControllerGUI.inventorySlotSelect.button15,
        inventoryControllerGUI.inventorySlotSelect.button16
    }

    for i = 1, #slots do
        slots[i]:onClick(function(self, event, button, x, y)
            if (event == "mouse_click") and (button == 1) then
                trySlotSelect(tonumber(self:getText()))
            end
        end):onClick(function(self)onClickTheme(self)end):onRelease(function(self)onReleaseTheme(self)end)
    end
end

function view.initAdvancedSettingsSelectionGUI(frame, homeUIInfo, digArgs, theme)
    advancedSettingsSelectionGUI.presetButton = frame:addButton():setText("\29"):setPosition("{parent.w-3}", 7):setSize(3, 1)
    advancedSettingsSelectionGUI.advancedSettingsButton = frame:addButton():setText("\4"):setPosition("{parent.w-3}", 8):setSize(3, 1)
    advancedSettingsSelectionGUI.advancedInventoryControllerButton = frame:addButton():setText("\18"):setPosition("{parent.w-3}", 9):setSize(3, 1)

    local frames = {
        preset = {
            button = advancedSettingsSelectionGUI.presetButton,
            frame = savedGUI.frame
        },
        advanced = {
            button = advancedSettingsSelectionGUI.advancedSettingsButton,
            frame = advancedDigSettingsGUI.frame
        },
        inventoryController = {
            button = advancedSettingsSelectionGUI.advancedInventoryControllerButton,
            frame = inventoryControllerGUI.frame
        }
    }

    local function showFrame(key)
        for k, frameShow in pairs(frames) do
            if k == key then
                frameShow.frame:setVisible(true)
                frameShow.button:setForeground(colors.yellow) -- todo make this a theme color
            else
                frameShow.frame:setVisible(false)
                frameShow.button:setForeground(colors.black) -- todo make this a theme color
            end
        end
    end

    local function hideAllFrames()
        for k, frameHide in pairs(frames) do
            frameHide.frame:setVisible(false)
            frameHide.button:setForeground(colors.black) -- todo make this a theme color
        end
    end

    advancedSettingsSelectionGUI.presetButton:onClick(function(self, event, button, x, y)
        if (event == "mouse_click") and (button == 1) then
            showFrame("preset")
        elseif (event == "mouse_click") and (button == 2) then
            hideAllFrames()
        end
    end)

    advancedSettingsSelectionGUI.advancedSettingsButton:onClick(function(self, event, button, x, y)
        if (event == "mouse_click") and (button == 1) then
            showFrame("advanced")
        elseif (event == "mouse_click") and (button == 2) then
            hideAllFrames()
        end
    end)

    advancedSettingsSelectionGUI.advancedInventoryControllerButton:onClick(function(self, event, button, x, y)
        if (event == "mouse_click") and (button == 1) then
            showFrame("inventoryController")
        elseif (event == "mouse_click") and (button == 2) then
            hideAllFrames()
        end
    end)
    showFrame("preset") -- todo maybe make it possible to select a favorite to show on startup
end

function view.init(frame, info, digArgs, homeUIInfo, rednetInfo, theme)
    homeFrame = frame:addFrame():setPosition(1, 1):setSize("{parent.w-2}", "{parent.h-2}")

    logFrame = frame:addFrame():setPosition(1, 14):setSize("{parent.w}", 7)
    logLabel = logFrame:addLabel():setText("Log:"):setPosition(1, 1)
    logList = logFrame:addList():setPosition(1, 2):setSize("{parent.w}", 6)

    view.initBasicDigSettingsGUI(homeFrame, digArgs, homeUIInfo, theme)
    -- view.initAdvancedDigSettings(sub, digArgs, theme)

    view.initAdvancedDigSettingsGUI(homeFrame, digArgs, theme)

    view.initSavedGUI(homeFrame, homeUIInfo, theme)

    view.initAdvanedInventoryControllerGUI(homeFrame, homeUIInfo, digArgs, theme)

    view.initAdvancedSettingsSelectionGUI(homeFrame, homeUIInfo, digArgs, theme)

    mainButtonFrame.buttonFrame = homeFrame:addFrame():setPosition(2,7):setSize(5,2)

    mainButtonFrame.runButton = mainButtonFrame.buttonFrame:addButton():setText("RUN"):setSize(5, 1):setPosition(1, 1):onClick(function(self)onClickTheme(self)end):onRelease(function(self)onReleaseTheme(self)end)
    mainButtonFrame.resetButton = mainButtonFrame.buttonFrame:addButton():setText("RESET"):setSize(5, 1):setPosition(1, 2):onClick(function(self)onClickTheme(self)end):onRelease(function(self)onReleaseTheme(self)end)

end

function view.updateArgsUI(digArgs, theme)
    local options = basicDigSettingsGUI.programDropdown:getOptions()
    for i = 1, #options do
        if options[i].text == digArgs.program then
            basicDigSettingsGUI.programDropdown:selectItem(i)
        end
    end
    basicDigSettingsGUI.lengthInput:setValue(digArgs.length or 1)
    basicDigSettingsGUI.widthInput:setValue(digArgs.width or 1)
    basicDigSettingsGUI.heightInput:setValue(digArgs.height or 1)
    if digArgs.offsetDir == "l" then
        basicDigSettingsGUI.offsetLeftButton:setForeground(colors.black)
        basicDigSettingsGUI.offsetRightButton:setForeground(colors.lightGray)
    else
        basicDigSettingsGUI.offsetLeftButton:setForeground(colors.lightGray)
        basicDigSettingsGUI.offsetRightButton:setForeground(colors.black)
    end
    basicDigSettingsGUI.torchCheckbox:setValue(digArgs.torch.torch)
    basicDigSettingsGUI.chestCheckbox:setValue(digArgs.chest.chest)
    basicDigSettingsGUI.rtsCheckbox:setValue(digArgs.rts)
    advancedDigSettingsGUI.ignoreInventoryCheckbox:setValue(digArgs.ignoreInventory)
    advancedDigSettingsGUI.ignoreFuelCheckbox:setValue(digArgs.ignoreFuel)
    advancedDigSettingsGUI.noPickupCheckbox:setValue(digArgs.noPickup)
    advancedDigSettingsGUI.torchSlotInput:setValue(digArgs.torch.slot)
    advancedDigSettingsGUI.torchDistanceInput:setValue(digArgs.torch.distance)
    advancedDigSettingsGUI.chestSlotInput:setValue(digArgs.chest.slot)
end

function view.getDigArgsFromUI()
    return digUtil.createDigArgsTable(
        basicDigSettingsGUI.programDropdown:getItem(basicDigSettingsGUI.programDropdown:getItemIndex()).text,
        "",
        tonumber(basicDigSettingsGUI.lengthInput:getValue()),
        tonumber(basicDigSettingsGUI.widthInput:getValue()),
        tonumber(basicDigSettingsGUI.heightInput:getValue()),
        getOffsetValue(),
        basicDigSettingsGUI.torchCheckbox:getValue(),
        tonumber(getTorchDistanceInputValue(advancedDigSettingsGUI.torchDistanceInput)),
        tonumber(getInventorySlotInputValue(advancedDigSettingsGUI.torchSlotInput)),
        basicDigSettingsGUI.chestCheckbox:getValue(),
        tonumber(getInventorySlotInputValue(advancedDigSettingsGUI.chestSlotInput)),
        basicDigSettingsGUI.rtsCheckbox:getValue(),
        advancedDigSettingsGUI.ignoreInventoryCheckbox:getValue(),
        advancedDigSettingsGUI.ignoreFuelCheckbox:getValue(),
        advancedDigSettingsGUI.noPickupCheckbox:getValue(),
        "",
        ""
    )
end

function view.resetArgsUI()
    basicDigSettingsGUI.programDropdown:selectItem(1)
    basicDigSettingsGUI.lengthInput:setValue("1")
    basicDigSettingsGUI.widthInput:setValue("1")
    basicDigSettingsGUI.heightInput:setValue("1")

    basicDigSettingsGUI.offsetLeftButton:setForeground(colors.lightGray)
    basicDigSettingsGUI.offsetRightButton:setForeground(colors.black)

    basicDigSettingsGUI.torchCheckbox:setValue(false)
    basicDigSettingsGUI.chestCheckbox:setValue(false)
    basicDigSettingsGUI.rtsCheckbox:setValue(false)

    advancedDigSettingsGUI.ignoreInventoryCheckbox:setValue(false)
    advancedDigSettingsGUI.ignoreFuelCheckbox:setValue(false)
    advancedDigSettingsGUI.noPickupCheckbox:setValue(false)

    advancedDigSettingsGUI.torchSlotInput:setValue(digUtil.CONST.DEFAULT_TORCH_SLOT)
    advancedDigSettingsGUI.torchDistanceInput:setValue(digUtil.CONST.DEFAULT_TORCH_SPACING)
    advancedDigSettingsGUI.chestSlotInput:setValue(digUtil.CONST.DEFAULT_CHEST_SLOT)
end

function view.getLogList()
    return {logList = logList}
end

function view.getBasicDigSettingsGUI()
    return {
        frame = basicDigSettingsGUI.frame,
        programDropdownLabel = basicDigSettingsGUI.programDropdownLabel,
        programDropdown = basicDigSettingsGUI.programDropdown,
        lengthInputLabel = basicDigSettingsGUI.lengthInputLabel,
        lengthInput = basicDigSettingsGUI.lengthInput,
        lengthSubButton = basicDigSettingsGUI.lengthSubButton,
        lengthAddButton = basicDigSettingsGUI.lengthAddButton,
        widthInputLabel = basicDigSettingsGUI.widthInputLabel,
        widthInput = basicDigSettingsGUI.widthInput,
        widthSubButton = basicDigSettingsGUI.widthSubButton,
        widthAddButton = basicDigSettingsGUI.widthAddButton,
        heightInputLabel = basicDigSettingsGUI.heightInputLabel,
        heightInput = basicDigSettingsGUI.heightInput,
        heightSubButton = basicDigSettingsGUI.heightSubButton,
        heightAddButton = basicDigSettingsGUI.heightAddButton,
        offsetLeftButton = basicDigSettingsGUI.offsetLeftButton,
        offsetRightButton = basicDigSettingsGUI.offsetRightButton,
        torchCheckBoxLabel = basicDigSettingsGUI.torchCheckBoxLabel,
        torchCheckbox = basicDigSettingsGUI.torchCheckbox,
        chestCheckBoxLabel = basicDigSettingsGUI.chestCheckBoxLabel,
        chestCheckbox = basicDigSettingsGUI.chestCheckbox,
        rtsCheckBoxLabel = basicDigSettingsGUI.rtsCheckBoxLabel,
        rtsCheckbo = basicDigSettingsGUI.rtsCheckbox
    }
end

function view.getSavedDataButtons()
    return {
        saved1Button = savedGUI.saved1Button,
        saved2Button = savedGUI.saved2Button,
        saved3Button = savedGUI.saved3Button,
        saved4Button = savedGUI.saved4Button,
        saved5Button = savedGUI.saved5Button,
        loadSavedButton = savedGUI.loadSavedButton,
        saveSavedButton = savedGUI.saveSavedButton,
        resetSavedButton = savedGUI.resetSavedButton
    }
end

function view.getRunButton()
    return {runButton = mainButtonFrame.runButton}
end

function view.getResetButton()
    return {resetButton = mainButtonFrame.resetButton}
end

function view.getDigArgs()
    return {
        lengthInput = basicDigSettingsGUI.lengthInput,
        lengthSubButton = basicDigSettingsGUI.lengthSubButton,
        lengthAddButton = basicDigSettingsGUI.lengthAddButton,
        widthInput = basicDigSettingsGUI.widthInput,
        widthSubButton = basicDigSettingsGUI.widthSubButton,
        widthAddButton = basicDigSettingsGUI.widthAddButton,
        heightInput = basicDigSettingsGUI.heightInput,
        heightSubButton = basicDigSettingsGUI.heightSubButton,
        heightAddButton = basicDigSettingsGUI.heightAddButton,
        offsetLeftButton = basicDigSettingsGUI.offsetLeftButton,
        offsetRightButton = basicDigSettingsGUI.offsetRightButton,
        torchCheckbox = basicDigSettingsGUI.torchCheckbox,
        chestCheckbox = basicDigSettingsGUI.chestCheckbox,
        rtsCheckbox = basicDigSettingsGUI.rtsCheckbox,
        ignoreInvCheckbox = advancedDigSettingsGUI.ignoreInventoryCheckbox,
        ignoreFuelCheckbox = advancedDigSettingsGUI.ignoreFuelCheckbox,
        noPickupCheckbox = advancedDigSettingsGUI.noPickupCheckbox
    }
end

return view