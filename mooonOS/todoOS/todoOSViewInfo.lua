-- todoOSViewInfo V1.0.0
-- Created by: ChefMooon

local view = {}

local infoFrame
function view.init(frame, info, theme)
    infoFrame = frame:addFrame():setPosition(1, 2):setSize("{parent.w-2}", "{parent.h-5}")
    infoFrame:addLabel():setText("Version: " .. info.programVersion)
end

return view