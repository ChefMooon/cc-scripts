-- digOSViewSettings V1.0.0
-- Created by: ChefMooon

--PROGRAM TODO--
-- refactor, variables can be made into tables

local view = {}

local settingsFrame

local settingsFrameTitle
local homeNetworkFrame

local homeTurtleIDLabel
local homeTurtleIDFrame
local homeTurtleID

local homeNetworkLabel
local homeNetworkID

local homeNetworkOffButton
local homeNetworkOnButton

function view.init(frame, turtleInfo, rednetInfo, theme)
    settingsFrame = frame:addFrame():setPosition(1,2):setSize("{parent.w}", "{parent.h}")

    settingsFrameTitle = settingsFrame:addLabel():setText("Rednet Settings"):setPosition(2, 1)
    homeNetworkFrame = settingsFrame:addFrame():setPosition(2,3):setSize(20,3)

    homeTurtleIDLabel = homeNetworkFrame:addLabel():setText("ID:"):setPosition(1,1):setSize(3,1)
    homeTurtleIDFrame = homeNetworkFrame:addScrollableFrame():setPosition(4,1):setSize("{parent.w-3}",1):setDirection("horizontal")
    homeTurtleID = homeTurtleIDFrame:addLabel():setText(turtleInfo.idLabel)

    homeNetworkLabel = homeNetworkFrame:addLabel():setText("Rednet:"):setPosition(1,2):setSize(7,1)
    homeNetworkID = homeNetworkFrame:addInput():setPosition(8,2):setSize(3,1):setInputType("number"):setValue(rednetInfo.rednetID):setInputLimit(2)

    homeNetworkOffButton = homeNetworkFrame:addButton():setText("off"):setPosition(1,3):setSize(5,1):setForeground(theme.networkFalse)
    homeNetworkOnButton = homeNetworkFrame:addButton():setText("on"):setPosition(6,3):setSize(5,1):setForeground(theme.networkFalse)
end

function view.initHomeNetworkOffOnButtons(offButtonColor, onButtonColor)
    homeNetworkOffButton:setForeground(offButtonColor)
    homeNetworkOnButton:setForeground(onButtonColor)
end

function view.get()
    return {
        homeNetworkFrame = homeNetworkFrame,
        homeTurtleID = homeTurtleID,
        homeNetworkID = homeNetworkID,
        homeNetworkOffButton = homeNetworkOffButton,
        homeNetworkOnButton = homeNetworkOnButton
    }
end

return view