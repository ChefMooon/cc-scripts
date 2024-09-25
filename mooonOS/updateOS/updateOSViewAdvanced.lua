local programInfo = {
    name = "updateOSViewAdvanced",
    version = "1.0.0",
    author = "ChefMooon"
}

--PROGRAM TODO--
--

local view = {}

view.advanced = {
    frame,
    label,
    legendButton,
    programsFrame,
    programsList,
    detailsFrame,
    detailsLabel,
    statusFrame,
    statusLabel,
    statusStatus
}

function view.init(frame, theme)
    view.advanced.frame = frame:addFrame():setPosition(1, 1):setSize("{parent.w-2}", "{parent.h-2}")
end

return view