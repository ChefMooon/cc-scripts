local programInfo = {
    name = "digOSViewSettings",
    version = "V1.0.2",
    author = "ChefMooon"
}

--PROGRAM TODO--
-- refactor, variables can be made into tables

local view = {}

local components = {}

function view.init(frame, turtleInfo, rednetInfo, programInfo, theme)
    components.settingsFrame = frame:addFrame():setPosition(1,2):setSize("{parent.w}", "{parent.h}")

    components.settingsFrameTitle = components.settingsFrame:addLabel():setText("Rednet Settings"):setPosition(2,1)
    components.homeNetworkFrame = components.settingsFrame:addFrame():setPosition(2,3):setSize(20,3)

    components.homeTurtleIDLabel = components.homeNetworkFrame:addLabel():setText("ID:"):setPosition(1,1):setSize(3,1)
    components.homeTurtleIDFrame = components.homeNetworkFrame:addScrollableFrame():setPosition(4,1):setSize("{parent.w-3}",1):setDirection("horizontal")
    components.homeTurtleID = components.homeTurtleIDFrame:addLabel():setText(tostring(turtleInfo.idLabel))

    components.homeNetworkLabel = components.homeNetworkFrame:addLabel():setText("Rednet:"):setPosition(1,2):setSize(7,1)
    components.homeNetworkID = components.homeNetworkFrame:addInput():setPosition(8,2):setSize(3,1):setInputType("number"):setValue(rednetInfo.rednetID):setInputLimit(2)

    components.homeNetworkOffButton = components.homeNetworkFrame:addButton():setText("off"):setPosition(1,3):setSize(5,1):setForeground(theme.networkFalse)
    components.homeNetworkOnButton = components.homeNetworkFrame:addButton():setText("on"):setPosition(6,3):setSize(5,1):setForeground(theme.networkFalse)

    components.programInfoFrame = components.settingsFrame:addFrame():setPosition(2,7):setSize(20,3)

    components.programInfoLabel = components.programInfoFrame:addLabel():setText("Program Info"):setPosition(1,1):setSize("{parent.w-1}",1)
    components.programNameLabel = components.programInfoFrame:addLabel():setText("Version:"..programInfo.version):setPosition(1,2):setSize("{parent.w-1}",1)
end

function view.initHomeNetworkOffOnButtons(offButtonColor, onButtonColor)
    components.homeNetworkOffButton:setForeground(offButtonColor)
    components.homeNetworkOnButton:setForeground(onButtonColor)
end

function view.updateRednetID(rednetID)
    components.homeNetworkID:setValue(rednetID)
end

function view.get()
    return components
end

return view