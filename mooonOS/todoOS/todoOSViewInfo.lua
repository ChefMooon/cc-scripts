local programInfo = {
    name = "todoOSViewInfo",
    version = "1.0.0",
    author = "ChefMooon"
}

local view = {}

local infoFrame
function view.init(frame, info, theme)
    infoFrame = frame:addFrame():setPosition(1, 2):setSize("{parent.w-2}", "{parent.h-5}")
    infoFrame:addLabel():setText("Version: " .. info.version)
end

return view