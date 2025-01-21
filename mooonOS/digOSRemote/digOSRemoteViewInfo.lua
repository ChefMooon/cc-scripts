local programInfo = {
    name = "digOSRemoteViewInfo",
    version = "1.0.0",
    author = "ChefMooon"
}

--- LOCAL FUNCTIONS

local function createProgressBar(progress)
    local barWidth = 10
    local filledAmount = math.floor((progress / 100) * barWidth)
    local bar = "["

    for i = 1, barWidth do
        if i <= filledAmount then
            bar = bar.."I"
        else
            bar = bar.." "
        end
    end

    bar = bar.."]"
    return bar
end

--- LOCAL FUNCTIOSN END

local view = {}

local connectedTurtleInfo = {}

local components = {}

function view.initTurtleDetailGUI(frame, theme)

end

function view.initTurtleListGUI(frame, theme)
    components.turtleListFrame = frame:addFrame():setPosition(1,4):setSize("{parent.w}", "{parent.h-5}")
    components.turtleListScrollableFrame = components.turtleListFrame:addScrollableFrame():setPosition(1,1):setSize("{parent.w-3}", "{parent.h-3}"):setDirection("vertical"):setBackground(theme.background)



end

function view.init(frame, info, rednetInfo, theme)
    components.frame = frame:addFrame():setPosition(1,2):setSize("{parent.w}", "{parent.h}")

    view.initTurtleListGUI(components.frame, theme)
end

function view.updateConectedTurtleInfoGUI(turtleInfo, theme)
    connectedTurtleInfo = turtleInfo
    local yPos = 1
    for _, value in ipairs(connectedTurtleInfo) do
        components.tInfoFrame = components.turtleListScrollableFrame:addFrame():setPosition(1, yPos):setSize("{parent.w}", 3):setBackground(theme.background)

        if (value.turtleInfo.jobStatus.working) then
            components.tInfoWorkingStatus = components.tInfoFrame:addFrame():setPosition(1, 1):setSize(1, 1):setBackground(colors.green)
        else
            components.tInfoWorkingStatus = components.tInfoFrame:addFrame():setPosition(1, 1):setSize(1, 1):setBackground(colors.red)
        end

        components.tInfoLabel1 = components.tInfoFrame:addLabel():setText(value.turtleInfo.idLabel):setPosition(3, 1):setSize("{parent.w-3}", 1):setForeground(theme.text)
        components.listFuelLabel = components.tInfoFrame:addLabel():setText("Fuel: "..tostring(value.turtleInfo.fuel)):setPosition(1, 2)
        if (value.jobElapsedTime) then
            components.listStartTimeLabel = components.tInfoFrame:addLabel():setText(tostring(value.jobElapsedTime)):setPosition(14, 2)
        end
        local jobProgress = 0
        if (value.layersMined and value.digArgs) then
            jobProgress = (value.layersMined / value.digArgs.length) * 100
        end
        local progressBar = createProgressBar(jobProgress)
        components.tInfoLabel2 = components.tInfoFrame:addLabel()
            :setText("Progress:"..progressBar.." "..tostring(math.floor(jobProgress).."%"))
            :setPosition(1, 3)
            :setSize("{parent.w-3}", 1)
            :setForeground(theme.text)
        yPos = yPos + 3
    end
end

function view.get()
    return components
end

function view.getTurtleList()
    return {
        turtleList = components.turtleList
    }
end

return view