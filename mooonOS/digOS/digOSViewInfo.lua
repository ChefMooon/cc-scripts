local programInfo = {
    name = "digOSViewInfo",
    version = "1.0.0",
    author = "ChefMooon"
}

--PROGRAM TODO--
-- refactor, variables can be made into tables

local view = {}

local programsInfoFrame
local programsInfoTitle

local programsInfoList

local programDetailsFrame
local programDetailsLabel

function view.init(frame, theme)
    programsInfoFrame = frame:addFrame():setPosition(1,2):setSize("{parent.w}","{parent.h-2}")
    programsInfoTitle = programsInfoFrame:addLabel():setText("Programs"):setPosition(2,1)

    programsInfoList = programsInfoFrame:addList():setPosition(2,2):setSize(15,8)

    programDetailsFrame = programsInfoFrame:addFrame():setPosition(18,2)
    programDetailsLabel = programDetailsFrame:addLabel():setText("Details:"):setPosition(1,1)
end

function view.get()
    return {
        programsInfoList = programsInfoList
    }
end

return view