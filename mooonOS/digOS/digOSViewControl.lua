-- digOSViewMove V1.0.0
-- Created by: ChefMooon

--PROGRAM TODO--
-- refactor, variables can be made into tables

local view = {}

local moveInputFrame

local moveInputFrameLabel

local digOptionFrame
local digCheckBoxLabel
local digCheckbox

local moveAmountInput

local moveAmountResetButton

local moveAmountSub5Button
local moveAmountSub1Button
local moveAmountAdd1Button
local moveAmountAdd5Button

local forwardButton
local backwardButton
local upButton
local downButton
local shiftLeftButton
local shiftRightButton
local turnLeftButton
local turnRightButton

local inventoryControl = {
    frame,
    label,
    slot1Button,
    slot2Button,
    slot3Button,
    slot4Button,
    slot5Button,
    slot6Button,
    slot7Button,
    slot8Button,
    slot9Button,
    slot10Button,
    slot11Button,
    slot12Button,
    slot13Button,
    slot14Button,
    slot15Button,
    slot16Button
}

local legendFrameToggleButton, legendFrame


function view.initInventoryControl(frame)
    inventoryControl.frame = frame:addFrame():setPosition(27, 2):setSize(15, "{parent.h-5}")
    inventoryControl.label = inventoryControl.frame:addLabel():setText("Inventory"):setPosition(2, 1)

    inventoryControl.slot1Button = inventoryControl.frame:addButton():setText("1"):setPosition(1, 3):setSize(3, 1)
    inventoryControl.slot2Button = inventoryControl.frame:addButton():setText("2"):setPosition(4, 3):setSize(3, 1)
    inventoryControl.slot3Button = inventoryControl.frame:addButton():setText("3"):setPosition(7, 3):setSize(3, 1)
    inventoryControl.slot4Button = inventoryControl.frame:addButton():setText("4"):setPosition(10, 3):setSize(3, 1)

    inventoryControl.slot5Button = inventoryControl.frame:addButton():setText("5"):setPosition(1, 4):setSize(3, 1)
    inventoryControl.slot6Button = inventoryControl.frame:addButton():setText("6"):setPosition(4, 4):setSize(3, 1)
    inventoryControl.slot7Button = inventoryControl.frame:addButton():setText("7"):setPosition(7, 4):setSize(3, 1)
    inventoryControl.slot8Button = inventoryControl.frame:addButton():setText("8"):setPosition(10, 4):setSize(3, 1)

    inventoryControl.slot9Button = inventoryControl.frame:addButton():setText("9"):setPosition(1, 5):setSize(3, 1)
    inventoryControl.slot10Button = inventoryControl.frame:addButton():setText("10"):setPosition(4, 5):setSize(3, 1)
    inventoryControl.slot11Button = inventoryControl.frame:addButton():setText("11"):setPosition(7, 5):setSize(3, 1)
    inventoryControl.slot12Button = inventoryControl.frame:addButton():setText("12"):setPosition(10, 5):setSize(3, 1)

    inventoryControl.slot13Button = inventoryControl.frame:addButton():setText("13"):setPosition(1, 6):setSize(3, 1)
    inventoryControl.slot14Button = inventoryControl.frame:addButton():setText("14"):setPosition(4, 6):setSize(3, 1)
    inventoryControl.slot15Button = inventoryControl.frame:addButton():setText("15"):setPosition(7, 6):setSize(3, 1)
    inventoryControl.slot16Button = inventoryControl.frame:addButton():setText("16"):setPosition(10, 6):setSize(3, 1)

    inventoryControl.slot1Button:onClick(function(self, event, button, x, y)
        if (event == "mouse_click") and (button == 1) then
            turtle.select(1)
        end
    end)
    inventoryControl.slot2Button:onClick(function(self, event, button, x, y)
        if (event == "mouse_click") and (button == 1) then
            turtle.select(2)
        end
    end)
    inventoryControl.slot3Button:onClick(function(self, event, button, x, y)
        if (event == "mouse_click") and (button == 1) then
            turtle.select(3)
        end
    end)
    inventoryControl.slot4Button:onClick(function(self, event, button, x, y)
        if (event == "mouse_click") and (button == 1) then
            turtle.select(4)
        end
    end)
    inventoryControl.slot5Button:onClick(function(self, event, button, x, y)
        if (event == "mouse_click") and (button == 1) then
            turtle.select(5)
        end
    end)
    inventoryControl.slot6Button:onClick(function(self, event, button, x, y)
        if (event == "mouse_click") and (button == 1) then
            turtle.select(6)
        end
    end)
    inventoryControl.slot7Button:onClick(function(self, event, button, x, y)
        if (event == "mouse_click") and (button == 1) then
            turtle.select(7)
        end
    end)
    inventoryControl.slot8Button:onClick(function(self, event, button, x, y)
        if (event == "mouse_click") and (button == 1) then
            turtle.select(8)
        end
    end)
    inventoryControl.slot9Button:onClick(function(self, event, button, x, y)
        if (event == "mouse_click") and (button == 1) then
            turtle.select(9)
        end
    end)
    inventoryControl.slot10Button:onClick(function(self, event, button, x, y)
        if (event == "mouse_click") and (button == 1) then
            turtle.select(10)
        end
    end)
    inventoryControl.slot11Button:onClick(function(self, event, button, x, y)
        if (event == "mouse_click") and (button == 1) then
            turtle.select(11)
        end
    end)
    inventoryControl.slot12Button:onClick(function(self, event, button, x, y)
        if (event == "mouse_click") and (button == 1) then
            turtle.select(12)
        end
    end)
    inventoryControl.slot13Button:onClick(function(self, event, button, x, y)
        if (event == "mouse_click") and (button == 1) then
            turtle.select(13)
        end
    end)
    inventoryControl.slot14Button:onClick(function(self, event, button, x, y)
        if (event == "mouse_click") and (button == 1) then
            turtle.select(14)
        end
    end)
    inventoryControl.slot15Button:onClick(function(self, event, button, x, y)
        if (event == "mouse_click") and (button == 1) then
            turtle.select(15)
        end
    end)
    inventoryControl.slot16Button:onClick(function(self, event, button, x, y)
        if (event == "mouse_click") and (button == 1) then
            turtle.select(16)
        end
    end)
end

function view.init(frame, theme)
    moveInputFrame = frame:addFrame():setPosition(1, 2):setSize(16, "{parent.h-3}")

    moveInputFrameLabel = moveInputFrame:addLabel():setText("Move"):setPosition(7, 1)

    digOptionFrame = moveInputFrame:addFrame():setPosition(10, 7):setSize(7, 1):setBackground(colors.gray):setForeground(colors.black)
    digCheckBoxLabel = digOptionFrame:addLabel():setText("Dig"):setPosition(4, 1)
    digCheckbox = digOptionFrame:addCheckbox():setPosition(2, 1):setBackground(colors.black):setForeground(colors.lightGray)

    moveAmountInput = moveInputFrame:addInput():setPosition(6, 9):setSize(7, 1):setInputType("number"):setInputLimit(4):setValue("1")

    moveAmountResetButton = moveInputFrame:addButton():setText("RESET"):setPosition(1,"{parent.h-1}"):setSize(5,1)
    moveAmountSub5Button = moveInputFrame:addButton():setText("\171"):setPosition(2, 9):setSize(1, 1)
    moveAmountSub1Button = moveInputFrame:addButton():setText("\17"):setPosition(4, 9):setSize(1, 1)
    moveAmountAdd1Button = moveInputFrame:addButton():setText("\16"):setPosition(14, 9):setSize(1, 1)
    moveAmountAdd5Button = moveInputFrame:addButton():setText("\187"):setPosition(16, 9):setSize(1, 1)

    forwardButton = moveInputFrame:addButton():setText("\30"):setPosition(6, 3):setSize(3, 1)
    backwardButton = moveInputFrame:addButton():setText("\31"):setPosition(6, 5):setSize(3, 1)
    upButton = moveInputFrame:addButton():setText("\24"):setPosition(14, 3):setSize(3, 1)
    downButton = moveInputFrame:addButton():setText("\25"):setPosition(14, 5):setSize(3, 1)
    shiftLeftButton = moveInputFrame:addButton():setText("\171"):setPosition(2, 7):setSize(3, 1)
    shiftRightButton = moveInputFrame:addButton():setText("\187"):setPosition(5, 7):setSize(3, 1)
    turnLeftButton = moveInputFrame:addButton():setText("\17"):setPosition(2, 4):setSize(3, 1)
    turnRightButton = moveInputFrame:addButton():setText("\16"):setPosition(10, 4):setSize(3, 1)

    view.initInventoryControl(frame)

    legendFrameToggleButton = frame:addButton():setText("Legend"):setPosition("{parent.w-7}", "{parent.h-2}"):setSize(6, 1)

    legendFrame = frame:addFrame():setPosition(1, 2):setSize("{parent.w}", "{parent.h-4}"):hide()
    legendFrameToggleButton:onClick(function(self, event, button, x, y)
        if (event == "mouse_click") and (button == 1) then
            if legendFrame:isVisible() then
                legendFrame:hide()
                moveInputFrame:show()
                inventoryControl.frame:show()
                legendFrameToggleButton:setForeground(colors.black)
            else
                legendFrame:show()
                moveInputFrame:hide()
                inventoryControl.frame:hide()
                legendFrameToggleButton:setForeground(colors.yellow)
            end
        end
    end)

    local legendLabel = legendFrame:addLabel():setText("Legend"):setPosition(1, 1)

    local legendForwardButtonLabel = legendFrame:addLabel():setText("\30 = Forward"):setPosition(3, 3)
    local legendBackwardButtonLabel = legendFrame:addLabel():setText("\31 = Backward"):setPosition(3, 4)
    local legendTurnLeftButtonLabel = legendFrame:addLabel():setText("\17 = Turn Left"):setPosition(3, 5)
    local legendTurnRightButtonLabel = legendFrame:addLabel():setText("\16 = Turn Right"):setPosition(3, 6)
    local legendUpButtonLabel = legendFrame:addLabel():setText("\24 = Up"):setPosition(20, 3)
    local legendDownButtonLabel = legendFrame:addLabel():setText("\25 = Down"):setPosition(20, 4)
    local legendShiftLeftButtonLabel = legendFrame:addLabel():setText("\171 = Shift Left"):setPosition(20, 5)
    local legendShiftRightButtonLabel = legendFrame:addLabel():setText("\187 = Shift Right"):setPosition(20, 6)
end

function view.getButtons()
    return digCheckbox, moveAmountInput, moveAmountResetButton,
        moveAmountSub5Button, moveAmountSub1Button, moveAmountAdd1Button, moveAmountAdd5Button,
        forwardButton, backwardButton, upButton, downButton,
        shiftLeftButton, shiftRightButton, turnLeftButton, turnRightButton
end

function view.getMoveButtons()
    return {
        digCheckbox = digCheckbox,
        moveAmountInput = moveAmountInput,
        moveAmountResetButton = moveAmountResetButton,
        moveAmountSub5Button = moveAmountSub5Button,
        moveAmountSub1Button = moveAmountSub1Button,
        moveAmountAdd1Button = moveAmountAdd1Button,
        moveAmountAdd5Button = moveAmountAdd5Button,
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

return view
