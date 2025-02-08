local programInfo = {
    name = "digOSViewControl",
    version = "1.0.3",
    author = "ChefMooon"
}

local digUtil = require("mooonOS/common/digUtil")
local basaltUtil = require("mooonOS/common/basaltUtil")

--PROGRAM TODO--
-- refactor, variables can be made into tables

local view = {}

local components = {}

local legend = {}

local moveInputFrame

local moveInputFrameLabel

local digOptionFrame
local digCheckBoxLabel
local digCheckbox

local moveAmountInput

local moveAmountResetButton

local moveAmountSubButton
local moveAmountAddButton

local forwardButton
local backwardButton
local upButton
local downButton
local shiftLeftButton
local shiftRightButton
local turnLeftButton
local turnRightButton

local inventoryControl = {}

local legendFrameToggleButton, legendFrame


function view.initInventoryControl(frame, theme)
    inventoryControl.frame = frame:addFrame():setPosition(27, 2):setSize(15, "{parent.h-5}")
    inventoryControl.label = inventoryControl.frame:addLabel():setText("Inventory"):setPosition(2, 1)

    inventoryControl.slot1Button = inventoryControl.frame:addButton():setText("1"):setPosition(1, 3):setSize(3, 1):onRelease(function(self)basaltUtil.buttonThemeOnRelease(self, theme)end)
    inventoryControl.slot2Button = inventoryControl.frame:addButton():setText("2"):setPosition(4, 3):setSize(3, 1):onRelease(function(self)basaltUtil.buttonThemeOnRelease(self, theme)end)
    inventoryControl.slot3Button = inventoryControl.frame:addButton():setText("3"):setPosition(7, 3):setSize(3, 1):onRelease(function(self)basaltUtil.buttonThemeOnRelease(self, theme)end)
    inventoryControl.slot4Button = inventoryControl.frame:addButton():setText("4"):setPosition(10, 3):setSize(3, 1):onRelease(function(self)basaltUtil.buttonThemeOnRelease(self, theme)end)

    inventoryControl.slot5Button = inventoryControl.frame:addButton():setText("5"):setPosition(1, 4):setSize(3, 1):onRelease(function(self)basaltUtil.buttonThemeOnRelease(self, theme)end)
    inventoryControl.slot6Button = inventoryControl.frame:addButton():setText("6"):setPosition(4, 4):setSize(3, 1):onRelease(function(self)basaltUtil.buttonThemeOnRelease(self, theme)end)
    inventoryControl.slot7Button = inventoryControl.frame:addButton():setText("7"):setPosition(7, 4):setSize(3, 1):onRelease(function(self)basaltUtil.buttonThemeOnRelease(self, theme)end)
    inventoryControl.slot8Button = inventoryControl.frame:addButton():setText("8"):setPosition(10, 4):setSize(3, 1):onRelease(function(self)basaltUtil.buttonThemeOnRelease(self, theme)end)

    inventoryControl.slot9Button = inventoryControl.frame:addButton():setText("9"):setPosition(1, 5):setSize(3, 1):onRelease(function(self)basaltUtil.buttonThemeOnRelease(self, theme)end)
    inventoryControl.slot10Button = inventoryControl.frame:addButton():setText("10"):setPosition(4, 5):setSize(3, 1):onRelease(function(self)basaltUtil.buttonThemeOnRelease(self, theme)end)
    inventoryControl.slot11Button = inventoryControl.frame:addButton():setText("11"):setPosition(7, 5):setSize(3, 1):onRelease(function(self)basaltUtil.buttonThemeOnRelease(self, theme)end)
    inventoryControl.slot12Button = inventoryControl.frame:addButton():setText("12"):setPosition(10, 5):setSize(3, 1):onRelease(function(self)basaltUtil.buttonThemeOnRelease(self, theme)end)

    inventoryControl.slot13Button = inventoryControl.frame:addButton():setText("13"):setPosition(1, 6):setSize(3, 1):onRelease(function(self)basaltUtil.buttonThemeOnRelease(self, theme)end)
    inventoryControl.slot14Button = inventoryControl.frame:addButton():setText("14"):setPosition(4, 6):setSize(3, 1):onRelease(function(self)basaltUtil.buttonThemeOnRelease(self, theme)end)
    inventoryControl.slot15Button = inventoryControl.frame:addButton():setText("15"):setPosition(7, 6):setSize(3, 1):onRelease(function(self)basaltUtil.buttonThemeOnRelease(self, theme)end)
    inventoryControl.slot16Button = inventoryControl.frame:addButton():setText("16"):setPosition(10, 6):setSize(3, 1):onRelease(function(self)basaltUtil.buttonThemeOnRelease(self, theme)end)

    inventoryControl.slot1Button:onClick(function(self, event, button, x, y)
        if (event == "mouse_click") and (button == 1) then
            turtle.select(1)
            basaltUtil.buttonThemeOnClick(self, theme)
        end
    end)
    inventoryControl.slot2Button:onClick(function(self, event, button, x, y)
        if (event == "mouse_click") and (button == 1) then
            turtle.select(2)
            basaltUtil.buttonThemeOnClick(self, theme)
        end
    end)
    inventoryControl.slot3Button:onClick(function(self, event, button, x, y)
        if (event == "mouse_click") and (button == 1) then
            turtle.select(3)
            basaltUtil.buttonThemeOnClick(self, theme)
        end
    end)
    inventoryControl.slot4Button:onClick(function(self, event, button, x, y)
        if (event == "mouse_click") and (button == 1) then
            turtle.select(4)
            basaltUtil.buttonThemeOnClick(self, theme)
        end
    end)
    inventoryControl.slot5Button:onClick(function(self, event, button, x, y)
        if (event == "mouse_click") and (button == 1) then
            turtle.select(5)
            basaltUtil.buttonThemeOnClick(self, theme)
        end
    end)
    inventoryControl.slot6Button:onClick(function(self, event, button, x, y)
        if (event == "mouse_click") and (button == 1) then
            turtle.select(6)
            basaltUtil.buttonThemeOnClick(self, theme)
        end
    end)
    inventoryControl.slot7Button:onClick(function(self, event, button, x, y)
        if (event == "mouse_click") and (button == 1) then
            turtle.select(7)
            basaltUtil.buttonThemeOnClick(self, theme)
        end
    end)
    inventoryControl.slot8Button:onClick(function(self, event, button, x, y)
        if (event == "mouse_click") and (button == 1) then
            turtle.select(8)
            basaltUtil.buttonThemeOnClick(self, theme)
        end
    end)
    inventoryControl.slot9Button:onClick(function(self, event, button, x, y)
        if (event == "mouse_click") and (button == 1) then
            turtle.select(9)
            basaltUtil.buttonThemeOnClick(self, theme)
        end
    end)
    inventoryControl.slot10Button:onClick(function(self, event, button, x, y)
        if (event == "mouse_click") and (button == 1) then
            turtle.select(10)
            basaltUtil.buttonThemeOnClick(self, theme)
        end
    end)
    inventoryControl.slot11Button:onClick(function(self, event, button, x, y)
        if (event == "mouse_click") and (button == 1) then
            turtle.select(11)
            basaltUtil.buttonThemeOnClick(self, theme)
        end
    end)
    inventoryControl.slot12Button:onClick(function(self, event, button, x, y)
        if (event == "mouse_click") and (button == 1) then
            turtle.select(12)
            basaltUtil.buttonThemeOnClick(self, theme)
        end
    end)
    inventoryControl.slot13Button:onClick(function(self, event, button, x, y)
        if (event == "mouse_click") and (button == 1) then
            turtle.select(13)
            basaltUtil.buttonThemeOnClick(self, theme)
        end
    end)
    inventoryControl.slot14Button:onClick(function(self, event, button, x, y)
        if (event == "mouse_click") and (button == 1) then
            turtle.select(14)
            basaltUtil.buttonThemeOnClick(self, theme)
        end
    end)
    inventoryControl.slot15Button:onClick(function(self, event, button, x, y)
        if (event == "mouse_click") and (button == 1) then
            turtle.select(15)
            basaltUtil.buttonThemeOnClick(self, theme)
        end
    end)
    inventoryControl.slot16Button:onClick(function(self, event, button, x, y)
        if (event == "mouse_click") and (button == 1) then
            turtle.select(16)
            basaltUtil.buttonThemeOnClick(self, theme)
        end
    end)
end

function view.initLegend(frame, theme)
    legend.frameToggleButton = frame:addButton():setText("Legend"):setPosition("{parent.w-7}", "{parent.h-2}"):setSize(6, 1)

    legend.frame = frame:addFrame():setPosition(1, 1):setSize("{parent.w}", "{parent.h-3}"):hide()
    legend.scrollableFrame = legend.frame:addScrollableFrame():setPosition(1, 2):setSize("{parent.w-1}", "{parent.h}")
    legend.frameToggleButton:onClick(function(self, event, button, x, y)
        if (event == "mouse_click") and (button == 1) then
            if legend.frame:isVisible() then
                legend.frame:hide()
                moveInputFrame:show()
                inventoryControl.frame:show()
                legend.frameToggleButton:setForeground(colors.black)
            else
                legend.frame:show()
                moveInputFrame:hide()
                inventoryControl.frame:hide()
                legend.frameToggleButton:setForeground(colors.yellow)
            end
        end
    end)

    legend.label = legend.scrollableFrame:addLabel():setText("Legend"):setPosition(1, 1)

    legend.forwardButtonLabel = legend.scrollableFrame:addLabel():setText("\30 = Forward"):setPosition(3, 3)
    legend.backwardButtonLabel = legend.scrollableFrame:addLabel():setText("\31 = Backward"):setPosition(3, 4)
    legend.turnLeftButtonLabel = legend.scrollableFrame:addLabel():setText("\17 = Turn Left"):setPosition(3, 5)
    legend.turnRightButtonLabel = legend.scrollableFrame:addLabel():setText("\16 = Turn Right"):setPosition(3, 6)
    legend.upButtonLabel = legend.scrollableFrame:addLabel():setText("\24 = Up"):setPosition(20, 3)
    legend.downButtonLabel = legend.scrollableFrame:addLabel():setText("\25 = Down"):setPosition(20, 4)
    legend.shiftLeftButtonLabel = legend.scrollableFrame:addLabel():setText("\171 = Shift Left"):setPosition(20, 5)
    legend.shiftRightButtonLabel = legend.scrollableFrame:addLabel():setText("\187 = Shift Right"):setPosition(20, 6)

    legend.useButtonLabel = legend.scrollableFrame:addLabel():setText("USE = Place Item"):setPosition(3, 8)
    legend.digButtonLabel = legend.scrollableFrame:addLabel():setText("DIG = Dig Block"):setPosition(3, 9)
    legend.dropButtonLabel = legend.scrollableFrame:addLabel():setText("DROP = L-Click - Drop Single Item"):setPosition(3, 10)
    legend.dropAllButtonLabel = legend.scrollableFrame:addLabel():setText("DROP = R-Click - Drop All Items"):setPosition(3, 11)
    legend.endSpace = legend.scrollableFrame:addLabel():setText(""):setPosition(1, 12)
end

function view.init(frame, currentSettings, theme)
    components.moveInputFrame = frame:addFrame():setPosition(1, 2):setSize(16, "{parent.h-3}")

    components.moveInputFrameLabel = components.moveInputFrame:addLabel():setText("Move"):setPosition(7, 1)

    components.digOptionFrame = components.moveInputFrame:addFrame():setPosition(10, 7):setSize(7, 1):setBackground(colors.gray):setForeground(colors.black)
    components.digCheckBoxLabel = components.digOptionFrame:addLabel():setText("Dig"):setPosition(4, 1)
    components.digCheckbox = components.digOptionFrame:addCheckbox():setPosition(2, 1):setBackground(colors.black):setForeground(colors.lightGray):setValue(currentSettings.moveDig)

    components.moveAmountInput = components.moveInputFrame:addInput():setPosition(6, 9):setSize(7, 1):setInputType("number"):setInputLimit(4):setValue(currentSettings.moveAmount)

    components.moveAmountResetButton = components.moveInputFrame:addButton():setText("RESET"):setPosition(1,"{parent.h-1}"):setSize(5,1):onClick(function(self)basaltUtil.buttonThemeOnClick(self, theme)end):onRelease(function(self)basaltUtil.buttonThemeOnRelease(self, theme)end)
    components.moveAmountSubButton = components.moveInputFrame:addButton():setText("\0\17\0"):setPosition(2, 9):setSize(3, 1):onClick(function(self)basaltUtil.buttonThemeOnClick(self, theme)end):onRelease(function(self)basaltUtil.buttonThemeOnRelease(self, theme)end)
    components.moveAmountAddButton = components.moveInputFrame:addButton():setText("\0\16\0"):setPosition(14, 9):setSize(3, 1):onClick(function(self)basaltUtil.buttonThemeOnClick(self, theme)end):onRelease(function(self)basaltUtil.buttonThemeOnRelease(self, theme)end)

    components.forwardButton = components.moveInputFrame:addButton():setText("\30"):setPosition(6, 3):setSize(3, 1):onClick(function(self)basaltUtil.buttonThemeOnClick(self, theme)end):onRelease(function(self)basaltUtil.buttonThemeOnRelease(self, theme)end)
    components.backwardButton = components.moveInputFrame:addButton():setText("\31"):setPosition(6, 5):setSize(3, 1):onClick(function(self)basaltUtil.buttonThemeOnClick(self, theme)end):onRelease(function(self)basaltUtil.buttonThemeOnRelease(self, theme)end)
    components.upButton = components.moveInputFrame:addButton():setText("\24"):setPosition(14, 3):setSize(3, 1):onClick(function(self)basaltUtil.buttonThemeOnClick(self, theme)end):onRelease(function(self)basaltUtil.buttonThemeOnRelease(self, theme)end)
    components.downButton = components.moveInputFrame:addButton():setText("\25"):setPosition(14, 5):setSize(3, 1):onClick(function(self)basaltUtil.buttonThemeOnClick(self, theme)end):onRelease(function(self)basaltUtil.buttonThemeOnRelease(self, theme)end)
    components.shiftLeftButton = components.moveInputFrame:addButton():setText("\171"):setPosition(2, 7):setSize(3, 1):onClick(function(self)basaltUtil.buttonThemeOnClick(self, theme)end):onRelease(function(self)basaltUtil.buttonThemeOnRelease(self, theme)end)
    components.shiftRightButton = components.moveInputFrame:addButton():setText("\187"):setPosition(5, 7):setSize(3, 1):onClick(function(self)basaltUtil.buttonThemeOnClick(self, theme)end):onRelease(function(self)basaltUtil.buttonThemeOnRelease(self, theme)end)
    components.turnLeftButton = components.moveInputFrame:addButton():setText("\17"):setPosition(2, 4):setSize(3, 1):onClick(function(self)basaltUtil.buttonThemeOnClick(self, theme)end):onRelease(function(self)basaltUtil.buttonThemeOnRelease(self, theme)end)
    components.turnRightButton = components.moveInputFrame:addButton():setText("\16"):setPosition(10, 4):setSize(3, 1):onClick(function(self)basaltUtil.buttonThemeOnClick(self, theme)end):onRelease(function(self)basaltUtil.buttonThemeOnRelease(self, theme)end)

    components.actionFrame = frame:addFrame():setPosition(18, 4):setSize(5, 3)

    components.useButton = components.actionFrame:addButton():setText("USE"):setPosition(1, 1):setSize(5, 1):onClick(function(self)basaltUtil.buttonThemeOnClick(self, theme)end):onRelease(function(self)basaltUtil.buttonThemeOnRelease(self, theme)end)
    components.digButton = components.actionFrame:addButton():setText("DIG"):setPosition(1, 2):setSize(5, 1):onClick(function(self)basaltUtil.buttonThemeOnClick(self, theme)end):onRelease(function(self)basaltUtil.buttonThemeOnRelease(self, theme)end)
    components.dropButton = components.actionFrame:addButton():setText("\0DROP"):setPosition(1, 3):setSize(5, 1):onClick(function(self)basaltUtil.buttonThemeOnClick(self, theme)end):onRelease(function(self)basaltUtil.buttonThemeOnRelease(self, theme)end)

    view.initInventoryControl(frame, theme)

    view.initLegend(frame, theme)
end

function view.getButtons()
    return digCheckbox, moveAmountInput, moveAmountResetButton,
        moveAmountSubButton, moveAmountAddButton,
        forwardButton, backwardButton, upButton, downButton,
        shiftLeftButton, shiftRightButton, turnLeftButton, turnRightButton
end

function view.getMoveButtons()
    return {
        digCheckbox = digCheckbox,
        moveAmountInput = moveAmountInput,
        moveAmountResetButton = moveAmountResetButton,
        moveAmountSubButton = moveAmountSubButton,
        moveAmountAddButton = moveAmountAddButton,
        forwardButton = forwardButton,
        backwardButton = backwardButton,
        upButton = upButton,
        downButton = downButton,
        shiftLeftButton = shiftLeftButton,
        shiftRightButton = shiftRightButton,
        turnLeftButton = turnLeftButton,
        turnRightButton = turnRightButton
    }
end

function view.get()
    return components
end

return view