-- digOSViewHome V1.0.0
-- Created by: ChefMooon

--PROGRAM TODO--
-- refactor, variables can be made into tables
-- add button to reset all saved data, create a confirm toast window (maybe make the window in another class and call it from here so that it can be used in other places)
-- create a legend (maybe create a class to help with this)

local digOSUtil = require("mooonOS/digOS/digOSUtil")

local CONST = {
    TORCH_SPACING_MIN = 1,
    TORCH_SPACING_MAX = 16,
    DEFAULT_TORCH_SPACING = 7,
    DEFAULT_TORCH_SLOT = 15,
    DEFAULT_CHEST_SLOT = 16
}

local LEGEND = {
    "L = Length",
    "W = Width",
    "H = Height",
    "\29 = Presets",
    "\4 = Advanced Settings",
    "\18 = Inventory Controller",
}

local view = {}

local homeFrame

local logFrame
local logLabel
local logList

local homeFuelFrame

local fuelLabel
local fuelLevelLabel

local fuelButton

local inputFrame

local programDropdownLabel

local programDropdown

local lengthInputLabel
local lengthInput
local lengthSubButton
local lengthAddButton

local widthInputLabel
local widthInput
local widthSubButton
local widthAddButton

local heightInputLabel
local heightInput
local heightSubButton
local heightAddButton

local offsetLeftButton
local offsetRightButton

local torchCheckBoxLabel
local torchCheckbox

local chestCheckBoxLabel
local chestCheckbox

local rtsCheckBoxLabel
local rtsCheckbox

local legendGUI = {
    frame,
    label,
    showButton,
    hideButton,
    list
}

local advancedDigSettingsGUI = {
    showHideButton,
    frame,
    label,
    ignoreInventoryCheckboxFrame,
    ignoreInventoryCheckbox,
    ignoreInventoryCheckboxLabel,
    ignoreFuelCheckboxFrame,
    ignoreFuelCheckbox,
    ignoreFuelCheckboxLabel,
    noPickupCheckboxFrame,
    noPickupCheckbox,
    noPickupCheckboxLabel,
    torchSlotFrame,
    torchSlotInput,
    torchSlotLabel,
    torchSlotIncreaseButton,
    torchSlotDecreaseButton,
    torchDistanceFrame,
    torchDistanceInput,
    torchDistanceLabel,
    torchDistanceIncreaseButton,
    torchDistanceDecreaseButton,
    chestSlotFrame,
    chestSlotInput,
    chestSlotLabel,
    chestSlotIncreaseButton,
    chestSlotDecreaseButton,
}

local advancedSettingsSelectionGUI = {
    frame,
    presetButton,
    advancedSettingsButton,
    advancedInventoryControllerButton
}

local savedGUI = {
    frame,
    labelFrame,
    label,
    saved1Button,
    saved2Button,
    saved3Button,
    saved4Button,
    saved5Button,
    loadSavedButton,
    saveSavedButton,
    resetSavedButton
}

local clipboardGUI = {
    frame,
    copyButton,
    pasteButton
}

local inventoryControllerGUI = {
    frame,
    label,
    directionButtonFrame,
    northButton,
    eastButton,
    southButton,
    westButton,
    useButton,
    digButton,
    dropButton,
    inventorySlotSelectFrame,
    inventorySlotSelect = {
        button1,
        button2,
        button3,
        button4,
        button5,
        button6,
        button7,
        button8,
        button9,
        button10,
        button11,
        button12,
        button13,
        button14,
        button15,
        button16
    }
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
    if offsetLeftButton:getForeground() == colors.black then
        return "l"
    elseif offsetRightButton:getForeground() == colors.black then
        return "r"
    end
end

local function trySlotSelect(slot)
    if slot >= 1 and slot <= 16 then
        turtle.select(slot)
    end
end

local function handleInventoryController(direction)
    local selectedSlot = turtle.getSelectedSlot()
    if direction == "north" then
        trySlotSelect(selectedSlot - 4)
    elseif direction == "east" then
        trySlotSelect(selectedSlot + 1)
    elseif direction == "south" then
        trySlotSelect(selectedSlot + 4)
    elseif direction == "west" then
        trySlotSelect(selectedSlot - 1)
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
    if value < CONST.TORCH_SPACING_MIN then
        return CONST.TORCH_SPACING_MIN
    elseif value > CONST.TORCH_SPACING_MAX then
        return CONST.TORCH_SPACING_MAX
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

local buttonFrame, runButton, resetButton

function view.initAdvancedDigSettingsGUI(frame, digArgs, theme)
    advancedDigSettingsGUI.frame = frame:addFrame():setPosition(24, 2):setSize(12, 7):hide()

    advancedDigSettingsGUI.label = advancedDigSettingsGUI.frame:addLabel():setText("Adv Settings"):setPosition(1, 1)

    advancedDigSettingsGUI.ignoreInventoryCheckboxFrame = advancedDigSettingsGUI.frame:addFrame():setPosition(1, 2):setSize("{parent.w-1/2}", 1):setBackground(colors.gray)
    advancedDigSettingsGUI.ignoreInventoryCheckbox = advancedDigSettingsGUI.ignoreInventoryCheckboxFrame:addCheckbox():setPosition(1, 1):setBackground(colors.black):setForeground(colors.lightGray)
    advancedDigSettingsGUI.ignoreInventoryCheckboxLabel = advancedDigSettingsGUI.ignoreInventoryCheckboxFrame:addLabel():setText("\120Inv"):setPosition(2, 1)

    advancedDigSettingsGUI.ignoreFuelCheckboxFrame = advancedDigSettingsGUI.frame:addFrame():setPosition(7, 2):setSize("{parent.w-1/2}", 1):setBackground(colors.gray)
    advancedDigSettingsGUI.ignoreFuelCheckbox = advancedDigSettingsGUI.ignoreFuelCheckboxFrame:addCheckbox():setPosition(1, 1):setBackground(colors.black):setForeground(colors.lightGray)
    advancedDigSettingsGUI.ignoreFuelCheckboxLabel = advancedDigSettingsGUI.ignoreFuelCheckboxFrame:addLabel():setText("\120Fuel"):setPosition(2, 1)

    advancedDigSettingsGUI.noPickupCheckboxFrame = advancedDigSettingsGUI.frame:addFrame():setPosition(1, 3):setSize("{parent.w-1}", 1):setBackground(colors.gray)
    advancedDigSettingsGUI.noPickupCheckbox = advancedDigSettingsGUI.noPickupCheckboxFrame:addCheckbox():setPosition(1, 1):setBackground(colors.black):setForeground(colors.lightGray)
    advancedDigSettingsGUI.noPickupCheckboxLabel = advancedDigSettingsGUI.noPickupCheckboxFrame:addLabel():setText("Drop All"):setPosition(3, 1)

    advancedDigSettingsGUI.torchDistanceFrame = advancedDigSettingsGUI.frame:addFrame():setPosition(1, 4):setSize("{parent.w-1}", 1):setBackground(colors.gray)
    advancedDigSettingsGUI.torchDistanceInput = advancedDigSettingsGUI.torchDistanceFrame:addInput():setPosition(1, 1):setSize(4, 1):setInputType("number"):setInputLimit(2):setValue(digArgs.torch.distance)
    advancedDigSettingsGUI.torchDistanceDecreaseButton = advancedDigSettingsGUI.torchDistanceFrame:addButton():setText("\17"):setPosition(5, 1):setSize(1, 1)
    advancedDigSettingsGUI.torchDistanceIncreaseButton = advancedDigSettingsGUI.torchDistanceFrame:addButton():setText("\16"):setPosition(6, 1):setSize(1, 1)
    advancedDigSettingsGUI.torchDistanceLabel = advancedDigSettingsGUI.torchDistanceFrame:addLabel():setText("TSpace"):setPosition(7, 1)

    advancedDigSettingsGUI.torchSlotFrame = advancedDigSettingsGUI.frame:addFrame():setPosition(1, 5):setSize("{parent.w-1}", 1):setBackground(colors.gray)
    advancedDigSettingsGUI.torchSlotInput = advancedDigSettingsGUI.torchSlotFrame:addInput():setPosition(1, 1):setSize(4, 1):setInputType("number"):setInputLimit(2):setValue(digArgs.torch.slot)
    advancedDigSettingsGUI.torchSlotDecreaseButton = advancedDigSettingsGUI.torchSlotFrame:addButton():setText("\17"):setPosition(5, 1):setSize(1, 1)
    advancedDigSettingsGUI.torchSlotIncreaseButton = advancedDigSettingsGUI.torchSlotFrame:addButton():setText("\16"):setPosition(6, 1):setSize(1, 1)
    advancedDigSettingsGUI.torchSlotLabel = advancedDigSettingsGUI.torchSlotFrame:addLabel():setText("TSlot"):setPosition(7, 1)

    advancedDigSettingsGUI.chestSlotFrame = advancedDigSettingsGUI.frame:addFrame():setPosition(1, 6):setSize("{parent.w-1}", 1):setBackground(colors.gray)
    advancedDigSettingsGUI.chestSlotInput = advancedDigSettingsGUI.chestSlotFrame:addInput():setPosition(1, 1):setSize(4, 1):setInputType("number"):setInputLimit(2):setValue(digArgs.chest.slot)
    advancedDigSettingsGUI.chestSlotDecreaseButton = advancedDigSettingsGUI.chestSlotFrame:addButton():setText("\17"):setPosition(5, 1):setSize(1, 1)
    advancedDigSettingsGUI.chestSlotIncreaseButton = advancedDigSettingsGUI.chestSlotFrame:addButton():setText("\16"):setPosition(6, 1):setSize(1, 1)
    advancedDigSettingsGUI.chestSlotLabel = advancedDigSettingsGUI.chestSlotFrame:addLabel():setText("CSlot"):setPosition(7, 1)

    advancedDigSettingsGUI.torchDistanceDecreaseButton:onClick(function(self, event, button, x, y)
        if (event == "mouse_click") then
            local value = tonumber(advancedDigSettingsGUI.torchDistanceInput:getValue()) - getNumberChange(button)
            if value > CONST.TORCH_SPACING_MIN then
                advancedDigSettingsGUI.torchDistanceInput:setValue(value)
            elseif value < CONST.TORCH_SPACING_MIN then
                advancedDigSettingsGUI.torchDistanceInput:setValue(CONST.TORCH_SPACING_MIN)
            end
        end
    end):onClick(function(self)onClickTheme(self)end):onRelease(function(self)onReleaseTheme(self)end)
    advancedDigSettingsGUI.torchDistanceIncreaseButton:onClick(function(self, event, button, x, y)
        if (event == "mouse_click") then
            local value = tonumber(advancedDigSettingsGUI.torchDistanceInput:getValue()) + getNumberChange(button)
            if value < CONST.TORCH_SPACING_MAX then
                advancedDigSettingsGUI.torchDistanceInput:setValue(value)
            elseif value > CONST.TORCH_SPACING_MAX then
                advancedDigSettingsGUI.torchDistanceInput:setValue(CONST.TORCH_SPACING_MAX)
            end
        end
    end):onClick(function(self)onClickTheme(self)end):onRelease(function(self)onReleaseTheme(self)end)

    advancedDigSettingsGUI.torchSlotDecreaseButton:onClick(function(self, event, button, x, y)
        if (event == "mouse_click") then
            local value = tonumber(advancedDigSettingsGUI.torchSlotInput:getValue()) - getNumberChange(button)
            if value > 1 then
                advancedDigSettingsGUI.torchSlotInput:setValue(value)
            elseif value < 1 then
                advancedDigSettingsGUI.torchSlotInput:setValue(1)
            end
        end
    end):onClick(function(self)onClickTheme(self)end):onRelease(function(self)onReleaseTheme(self)end)
    advancedDigSettingsGUI.torchSlotIncreaseButton:onClick(function(self, event, button, x, y)
        if (event == "mouse_click") then
            local value = tonumber(advancedDigSettingsGUI.torchSlotInput:getValue()) + getNumberChange(button)
            if value < 16 then
                advancedDigSettingsGUI.torchSlotInput:setValue(value)
            elseif value > 16 then
                advancedDigSettingsGUI.torchSlotInput:setValue(16)
            end
        end
    end):onClick(function(self)onClickTheme(self)end):onRelease(function(self)onReleaseTheme(self)end)

    advancedDigSettingsGUI.chestSlotDecreaseButton:onClick(function(self, event, button, x, y)
        if (event == "mouse_click") then
            local value = tonumber(advancedDigSettingsGUI.chestSlotInput:getValue()) - getNumberChange(button)
            if value > 1 then
                advancedDigSettingsGUI.chestSlotInput:setValue(value)
            elseif value < 1 then
                advancedDigSettingsGUI.chestSlotInput:setValue(1)
            end
        end
    end):onClick(function(self)onClickTheme(self)end):onRelease(function(self)onReleaseTheme(self)end)
    advancedDigSettingsGUI.chestSlotIncreaseButton:onClick(function(self, event, button, x, y)
        if (event == "mouse_click") then
            local value = tonumber(advancedDigSettingsGUI.chestSlotInput:getValue()) + getNumberChange(button)
            if value < 16 then
                advancedDigSettingsGUI.chestSlotInput:setValue(value)
            elseif value > 16 then
                advancedDigSettingsGUI.chestSlotInput:setValue(16)
            end
        end
    end):onClick(function(self)onClickTheme(self)end):onRelease(function(self)onReleaseTheme(self)end)

end

function view.initSavedGUI(frame, homeUIInfo, theme)
    savedGUI.frame = frame:addFrame():setPosition(24,2):setSize(11,4):setBackground(colors.gray):hide()

    savedGUI.labelFrame = savedGUI.frame:addFrame():setPosition(1,1):setSize("{parent.w}",1):setBackground(colors.lightGray)
    savedGUI.label = savedGUI.labelFrame:addLabel():setText("Presets"):setPosition(3,1)

    savedGUI.saved1Button = savedGUI.frame:addButton():setText("1"):setPosition(2,2):setSize(1,1):setForeground(homeUIInfo.saved1ButtonColor)
    savedGUI.saved2Button = savedGUI.frame:addButton():setText("2"):setPosition(4,2):setSize(1,1):setForeground(homeUIInfo.saved2ButtonColor)
    savedGUI.saved3Button = savedGUI.frame:addButton():setText("3"):setPosition(6,2):setSize(1,1):setForeground(homeUIInfo.saved3ButtonColor)
    savedGUI.saved4Button = savedGUI.frame:addButton():setText("4"):setPosition(8,2):setSize(1,1):setForeground(homeUIInfo.saved4ButtonColor)
    savedGUI.saved5Button = savedGUI.frame:addButton():setText("5"):setPosition(10,2):setSize(1,1):setForeground(homeUIInfo.saved5ButtonColor)

    savedGUI.loadSavedButton = savedGUI.frame:addButton():setText("LOAD"):setPosition(2,3):setSize(4,1):onClick(function(self)onClickTheme(self)end):onRelease(function(self)onReleaseTheme(self)end)
    savedGUI.saveSavedButton = savedGUI.frame:addButton():setText("SAVE"):setPosition(7,3):setSize(4,1):onClick(function(self)onClickTheme(self)end):onRelease(function(self)onReleaseTheme(self)end)
    savedGUI.resetSavedButton = savedGUI.frame:addButton():setText("RESET"):setPosition(4,4):setSize(5,1):onClick(function(self)onClickTheme(self)end):onRelease(function(self)onReleaseTheme(self)end)
end

function view.initAdvanedInventoryControllerGUI(frame, homeUIInfo, digArgs, theme)
    inventoryControllerGUI.frame = frame:addFrame():setPosition(24,2):setSize(12,7):hide()

    inventoryControllerGUI.label = inventoryControllerGUI.frame:addLabel():setText("Inventory"):setPosition(2, 1)

    inventoryControllerGUI.directionButtonFrame = inventoryControllerGUI.frame:addFrame():setPosition(2, 2):setSize(3, 3)

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

    inventoryControllerGUI.useButton = inventoryControllerGUI.frame:addButton():setText("USE"):setPosition(6, 2):setSize(3, 1):onClick(function(self)onClickTheme(self)end):onRelease(function(self)onReleaseTheme(self)end)
    inventoryControllerGUI.digButton = inventoryControllerGUI.frame:addButton():setText("DIG"):setPosition(9, 2):setSize(3, 1):onClick(function(self)onClickTheme(self)end):onRelease(function(self)onReleaseTheme(self)end)
    inventoryControllerGUI.dropButton = inventoryControllerGUI.frame:addButton():setText("DROP"):setPosition(7, 3):setSize(4, 1):onClick(function(self)onClickTheme(self)end):onRelease(function(self)onReleaseTheme(self)end)

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

    inventoryControllerGUI.inventorySlotSelectFrame = inventoryControllerGUI.frame:addFrame():setPosition(1, 5):setSize(12, 3)

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

function view.initLegendGUI(frame, parentFrame, theme)
    legendGUI.showButton = frame:addButton():setText("LGD"):setPosition("{parent.w-3}", 2):setSize(3, 1)

    legendGUI.frame = parentFrame:addFrame():setPosition(1, 2):setSize("{parent.w-2}", "{parent.h-3}"):hide()
    legendGUI.hideButton = legendGUI.frame:addButton():setText("\0X"):setPosition("{parent.w-3}", 1):setSize(3, 1)

    legendGUI.showButton:onClick(function(self, event, button, x, y)
        if (event == "mouse_click") and (button == 1) then
            legendGUI.frame:show()
        end
    end)
    legendGUI.hideButton:onClick(function(self, event, button, x, y)
        if (event == "mouse_click") and (button == 1) then
            legendGUI.frame:hide()
        end
    end)

    legendGUI.label = legendGUI.frame:addLabel():setText("Legend:"):setPosition(2, 1)

    for i = 1, #LEGEND do
        legendGUI.frame:addLabel():setText(LEGEND[i]):setPosition(3, i+2)
    end
end

function view.initAdvancedSettingsSelectionGUI(frame, homeUIInfo, digArgs, theme)
    advancedSettingsSelectionGUI.presetButton = frame:addButton():setText("\29"):setPosition("{parent.w-3}", 3):setSize(3, 1)
    advancedSettingsSelectionGUI.advancedSettingsButton = frame:addButton():setText("\4"):setPosition("{parent.w-3}", 4):setSize(3, 1)
    advancedSettingsSelectionGUI.advancedInventoryControllerButton = frame:addButton():setText("\18"):setPosition("{parent.w-3}", 5):setSize(3, 1)
    
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

    advancedSettingsSelectionGUI.presetButton:onClick(function(self, event, button, x, y)
        if (event == "mouse_click") and (button == 1) then
            showFrame("preset")
        end
    end)

    advancedSettingsSelectionGUI.advancedSettingsButton:onClick(function(self, event, button, x, y)
        if (event == "mouse_click") and (button == 1) then
            showFrame("advanced")
        end
    end)

    advancedSettingsSelectionGUI.advancedInventoryControllerButton:onClick(function(self, event, button, x, y)
        if (event == "mouse_click") and (button == 1) then
            showFrame("inventoryController")
        end
    end)
    showFrame("preset") -- todo maybe make it possible to select a favorite to show on startup
end

function view.init(frame, turtleInfo, digArgs, homeUIInfo, rednetInfo, theme)
    homeFrame = frame:addFrame():setPosition(1, 1):setSize("{parent.w-2}", "{parent.h-2}")

    homeInputFrame = frame:addFrame():setPosition(1, 1):setSize("{parent.w-2}", 8)

    logFrame = frame:addFrame():setPosition(1, 9):setSize("{parent.w-2}", 4)
    logLabel = logFrame:addLabel():setText("Log:"):setPosition(1, 1)
    logList = logFrame:addList():setPosition(1, 2):setSize("{parent.w}", 3)

    homeFuelFrame = homeInputFrame:addFrame():setPosition(11, 7):setSize(11, 3)

    fuelLabel = homeFuelFrame:addLabel():setText("Fuel:"):setPosition(1, 1)
    fuelLevelLabel = homeFuelFrame:addLabel():setText(tostring(turtleInfo.fuel)):setPosition(6, 1)

    fuelButton = homeFuelFrame:addButton():setText("REFUEL"):setSize("{parent.w-1}", 1):setPosition(1, 2)

    inputFrame = homeInputFrame:addFrame():setPosition(1, 2):setSize(22, 4)

    programDropdownLabel = inputFrame:addLabel():setText("Program:"):setPosition(1, 1)

    programDropdown = inputFrame:addDropdown():setPosition(9, 1):setSize(14,1)

    lengthInputLabel = inputFrame:addLabel():setText("L:"):setPosition(1, 2)
    lengthInput = inputFrame:addInput():setPosition(3, 2):setSize(5, 1):setInputType("number"):setInputLimit(4):setValue(digArgs.length)
    lengthSubButton = inputFrame:addButton():setText("\17"):setPosition(9, 2):setSize(2, 1):onClick(function(self)onClickTheme(self)end):onRelease(function(self)onReleaseTheme(self)end)
    lengthAddButton = inputFrame:addButton():setText(" \16"):setPosition(11, 2):setSize(2, 1):onClick(function(self)onClickTheme(self)end):onRelease(function(self)onReleaseTheme(self)end)

    widthInputLabel = inputFrame:addLabel():setText("W:"):setPosition(1, 3)
    widthInput = inputFrame:addInput():setPosition(3, 3):setSize(5, 1):setInputType("number"):setInputLimit(4):setValue(digArgs.width)
    widthSubButton = inputFrame:addButton():setText("\17"):setPosition(9, 3):setSize(2, 1):onClick(function(self)onClickTheme(self)end):onRelease(function(self)onReleaseTheme(self)end)
    widthAddButton = inputFrame:addButton():setText(" \16"):setPosition(11, 3):setSize(2, 1):onClick(function(self)onClickTheme(self)end):onRelease(function(self)onReleaseTheme(self)end)

    heightInputLabel = inputFrame:addLabel():setText("H:"):setPosition(1, 4)
    heightInput = inputFrame:addInput():setPosition(3, 4):setSize(5, 1):setInputType("number"):setInputLimit(4):setValue(digArgs.height)
    heightSubButton = inputFrame:addButton():setText("\17"):setPosition(9, 4):setSize(2, 1):onClick(function(self)onClickTheme(self)end):onRelease(function(self)onReleaseTheme(self)end)
    heightAddButton = inputFrame:addButton():setText(" \16"):setPosition(11, 4):setSize(2, 1):onClick(function(self)onClickTheme(self)end):onRelease(function(self)onReleaseTheme(self)end)

    offsetLeftButton = inputFrame:addButton():setText("\171"):setPosition(14,2):setSize(1,1):setForeground(colors.lightGray)
    offsetRightButton = inputFrame:addButton():setText("\187"):setPosition(15,2):setSize(1,1)

    torchCheckBoxLabel = inputFrame:addLabel():setText("Torch"):setPosition(18,2):setBackground(colors.gray):setForeground(colors.black)
    torchCheckbox = inputFrame:addCheckbox():setPosition(17,2):setBackground(colors.black):setForeground(colors.lightGray)

    chestCheckBoxLabel = inputFrame:addLabel():setText("Chest"):setPosition(18,3):setBackground(colors.gray):setForeground(colors.black)
    chestCheckbox = inputFrame:addCheckbox():setPosition(17,3):setBackground(colors.black):setForeground(colors.lightGray)

    rtsCheckBoxLabel = inputFrame:addLabel():setText("RTS"):setPosition(18,4):setSize(5,1):setBackground(colors.gray):setForeground(colors.black)
    rtsCheckbox = inputFrame:addCheckbox():setPosition(17,4):setBackground(colors.black):setForeground(colors.lightGray)

    view.initAdvancedDigSettingsGUI(homeInputFrame, digArgs, theme)

    view.initSavedGUI(homeInputFrame, homeUIInfo, theme)

    view.initAdvanedInventoryControllerGUI(homeInputFrame, homeUIInfo, digArgs, theme)

    view.initAdvancedSettingsSelectionGUI(homeInputFrame, homeUIInfo, digArgs, theme)

    clipboardGUI.frame = homeInputFrame:addFrame():setPosition("{parent.w-3}",7):setSize(7,2)

    clipboardGUI.copyButton = clipboardGUI.frame:addButton():setText("CPY"):setSize(3,1):setPosition(1, 1):onClick(function(self)onClickTheme(self)end):onRelease(function(self)onReleaseTheme(self)end)
    clipboardGUI.pasteButton = clipboardGUI.frame:addButton():setText("PST"):setSize(3,1):setPosition(1, 2):onClick(function(self)onClickTheme(self)end):onRelease(function(self)onReleaseTheme(self)end)

    buttonFrame = homeInputFrame:addFrame():setPosition(2,7):setSize(5,2)

    runButton = buttonFrame:addButton():setText("RUN"):setSize(5, 1):setPosition(1, 1):onClick(function(self)onClickTheme(self)end):onRelease(function(self)onReleaseTheme(self)end)
    resetButton = buttonFrame:addButton():setText("RESET"):setSize(5, 1):setPosition(1, 2):onClick(function(self)onClickTheme(self)end):onRelease(function(self)onReleaseTheme(self)end)

    view.initLegendGUI(homeInputFrame, frame, theme)
end

function view.updateArgsUI(digArgs, theme)
    local options = programDropdown:getOptions()
    for i = 1, #options do
        if options[i].text == digArgs.program then
            programDropdown:selectItem(i)
        end
    end
    lengthInput:setValue(digArgs.length or 1)
    widthInput:setValue(digArgs.width or 1)
    heightInput:setValue(digArgs.height or 1)
    if digArgs.offsetDir == "l" then
        offsetLeftButton:setForeground(colors.black)
        offsetRightButton:setForeground(colors.lightGray)
    else
        offsetLeftButton:setForeground(colors.lightGray)
        offsetRightButton:setForeground(colors.black)
    end
    torchCheckbox:setValue(digArgs.torch.torch)
    chestCheckbox:setValue(digArgs.chest.chest)
    rtsCheckbox:setValue(digArgs.rts)
    advancedDigSettingsGUI.ignoreInventoryCheckbox:setValue(digArgs.ignoreInventory)
    advancedDigSettingsGUI.ignoreFuelCheckbox:setValue(digArgs.ignoreFuel)
    advancedDigSettingsGUI.noPickupCheckbox:setValue(digArgs.noPickup)
    advancedDigSettingsGUI.torchSlotInput:setValue(digArgs.torch.slot)
    advancedDigSettingsGUI.torchDistanceInput:setValue(digArgs.torch.distance)
    advancedDigSettingsGUI.chestSlotInput:setValue(digArgs.chest.slot)
end

function view.getDigArgsFromUI()
    return digOSUtil.createDigArgsTable(
        programDropdown:getItem(programDropdown:getItemIndex()).text,
        "",
        tonumber(lengthInput:getValue()),
        tonumber(widthInput:getValue()),
        tonumber(heightInput:getValue()),
        getOffsetValue(),
        torchCheckbox:getValue(),
        tonumber(getTorchDistanceInputValue(advancedDigSettingsGUI.torchDistanceInput)),
        tonumber(getInventorySlotInputValue(advancedDigSettingsGUI.torchSlotInput)),
        chestCheckbox:getValue(),
        tonumber(getInventorySlotInputValue(advancedDigSettingsGUI.chestSlotInput)),
        rtsCheckbox:getValue(),
        advancedDigSettingsGUI.ignoreInventoryCheckbox:getValue(),
        advancedDigSettingsGUI.ignoreFuelCheckbox:getValue(),
        advancedDigSettingsGUI.noPickupCheckbox:getValue(),
        "",
        ""
    )
end

function view.resetArgsUI()
    programDropdown:selectItem(1)
    lengthInput:setValue("1")
    widthInput:setValue("1")
    heightInput:setValue("1")

    offsetLeftButton:setForeground(colors.lightGray)
    offsetRightButton:setForeground(colors.black)

    torchCheckbox:setValue(false)
    chestCheckbox:setValue(false)
    rtsCheckbox:setValue(false)
    
    advancedDigSettingsGUI.ignoreInventoryCheckbox:setValue(false)
    advancedDigSettingsGUI.ignoreFuelCheckbox:setValue(false)
    advancedDigSettingsGUI.noPickupCheckbox:setValue(false)

    advancedDigSettingsGUI.torchSlotInput:setValue(CONST.DEFAULT_TORCH_SLOT)
    advancedDigSettingsGUI.torchDistanceInput:setValue(CONST.DEFAULT_TORCH_SPACING)
    advancedDigSettingsGUI.chestSlotInput:setValue(CONST.DEFAULT_CHEST_SLOT)
end


-- todo: these functions make me sick, must fix when i fix all the variables

function view.getLogList()
    return {logList = logList}
end

function view.getProgramDropdown()
    return {programDropdown = programDropdown}
end

function view.getBaseGUI()
    return {
        homeFrame = homeFrame,
        logFrame = logFrame,
        logLabel = logLabel,
        logList = logList,
        inputFrame = inputFrame,
        programDropdownLabel = programDropdownLabel,
        programDropdown = programDropdown,
    }
end

function view.getFuelGUI()
    return {
        homeFuelFrame = homeFuelFrame,
        fuelLabel = fuelLabel,
        fuelLevelLabel = fuelLevelLabel,
        fuelButton = fuelButton
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

function view.getClipboardGUI()
    return {
        frame = clipboardGUI.frame,
        copyButton = clipboardGUI.copyButton,
        pasteButton = clipboardGUI.pasteButton
    }
end

function view.getRunButton()
    return {runButton = runButton}
end

function view.getResetButton()
    return {resetButton = resetButton}
end

function view.getDigArgs()
    return {
        lengthInput = lengthInput,
        lengthSubButton = lengthSubButton,
        lengthAddButton = lengthAddButton,
        widthInput = widthInput,
        widthSubButton = widthSubButton,
        widthAddButton = widthAddButton,
        heightInput = heightInput,
        heightSubButton = heightSubButton,
        heightAddButton = heightAddButton,
        offsetLeftButton = offsetLeftButton,
        offsetRightButton = offsetRightButton,
        torchCheckbox = torchCheckbox,
        chestCheckbox = chestCheckbox,
        rtsCheckbox = rtsCheckbox,
        ignoreInvCheckbox = advancedDigSettingsGUI.ignoreInventoryCheckbox,
        ignoreFuelCheckbox = advancedDigSettingsGUI.ignoreFuelCheckbox,
        noPickupCheckbox = advancedDigSettingsGUI.noPickupCheckbox
    }
end

return view