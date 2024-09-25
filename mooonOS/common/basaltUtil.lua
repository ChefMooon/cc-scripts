local programInfo = {
    name = "basaltUtil",
    version = "1.0.0",
    author = "ChefMooon"
}

----- UTILITY -----

local function buttonClick(self)
    self:setBackground(colors.yellow)
end

local function buttonRelease(self)
    self:setBackground(colors.gray)
end

local basaltUtil = {}

basaltUtil.userValidation = {
    frame,
    popupFrame,
    popupLabel,
    yesButton,
    noButton
}

function basaltUtil.initUserValidation(frame, xPos, yPos, theme)
    local w, h = term.getSize()
    if xPos == nil then xPos = w end
    if yPos == nil then yPos = h end
    xPos = w / 2 - 10
    yPos = math.ceil(h / 2 - 3)

    basaltUtil.userValidation.frame = frame:addFrame():setPosition(tonumber(xPos), tonumber(yPos)):setSize(22, 6):setBackground(colors.yellow)
    basaltUtil.userValidation.popupFrame = basaltUtil.userValidation.frame:addFrame():setPosition(2, 2):setSize("{parent.w-3}", "{parent.h-3}")
    basaltUtil.userValidation.popupLabel = basaltUtil.userValidation.popupFrame:addLabel():setText("Are you sure?"):setPosition(5, 1)
    basaltUtil.userValidation.yesButton = basaltUtil.userValidation.popupFrame:addButton():setText("Yes"):setPosition(3, 3):setSize(7, 1):onClick(function(self) buttonClick(self) end):onRelease(function(self) buttonRelease(self) end)
    basaltUtil.userValidation.noButton = basaltUtil.userValidation.popupFrame:addButton():setText("No"):setPosition(12, 3):setSize(7, 1):onClick(function(self) buttonClick(self) end):onRelease(function(self) buttonRelease(self) end)

    basaltUtil.userValidation.yesButton:onClick(function(self, event, button, x, y)
        if (event == "mouse_click") and (button == 1) then
            os.queueEvent("updateOS_validation", true)
            basaltUtil.userValidation.frame:hide()
        end
    end)

    basaltUtil.userValidation.noButton:onClick(function(self, event, button, x, y)
        if (event == "mouse_click") and (button == 1) then
            self:setBackground(colors.yellow)
            os.queueEvent("updateOS_validation", false)
            basaltUtil.userValidation.frame:hide()
        end
    end)

    local event, realConfirm = os.pullEvent("updateOS_validation")
    return realConfirm
end

return basaltUtil