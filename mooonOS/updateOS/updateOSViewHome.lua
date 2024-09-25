local programInfo = {
    name = "updateOSViewHome",
    version = "1.0.0",
    author = "ChefMooon"
}

--PROGRAM TODO--
-- create a function that will create a confirm button, use for delete and confirm button, potentially make this a universal Toast popup. can customize position (and size?) of frame, theme, 

local basalt = require("basalt")  --- Not sure if I need this

----- UTILITY -----

local function buttonClick(self)
    self:setBackground(colors.yellow)
end

local function buttonRelease(self)
    self:setBackground(colors.gray)
end

local view = {}

view.main ={
    frame,
    programDetailsFrame,
    programLabel,
    programFrame,
    programList,
    detailsLabel,
    detailsFrame,
    detailsDownloadStatusLabel,
    detailsDownloadStatus,
    detailsVersionLabel,
    detailsVersion,
    detailsUpToDateLabel,
    detailsDescriptionFrame,
    detailsDescriptionLabel,
    detailsDescription,
    buttonFrame,
    downloadButton,
    updateButton,
    deleteButton,
    updateAllButton
}

view.confirmPopup = {
    frame,
    popupFrame,
    popupLabel,
    yesButton,
    noButton,
    result = true
}


function view.init(frame, theme)
    view.main.frame = frame:addFrame():setPosition(1,1):setSize("{parent.w-2}","{parent.h-2}")
    view.main.programDetailsFrame = view.main.frame:addFrame():setPosition(2,2):setSize("{parent.w-2}",8)
    view.main.programLabel = view.main.programDetailsFrame:addLabel():setText("Programs:"):setPosition(1,1)
    view.main.programFrame = view.main.programDetailsFrame:addScrollableFrame():setPosition(1,2):setSize(20,"{parent.h-1}")
    view.main.programList = view.main.programFrame:addList():setPosition(1,1):setSize("{parent.w}","{parent.h}")

    view.main.detailsLabel = view.main.programDetailsFrame:addLabel():setText("Details:"):setPosition("{parent.w-17}",1)
    view.main.detailsFrame = view.main.programDetailsFrame:addFrame():setPosition("{parent.w-17}",2):setSize(15,"{parent.h-1}"):setBackground(colors.gray)

    view.main.detailsDownloadStatusLabel = view.main.detailsFrame:addLabel():setText("Downloaded:"):setPosition(1,1):setSize(11,1)
    view.main.detailsDownloadStatus = view.main.detailsFrame:addLabel():setText(""):setPosition("{parent.w-3}",1):setSize(2,1)

    view.main.detailsVersionLabel = view.main.detailsFrame:addLabel():setText("Version:"):setPosition(1,2):setSize(8,1)
    view.main.detailsVersion = view.main.detailsFrame:addLabel():setText(""):setPosition(10,2):setSize(5,1)

    view.main.detailsUpToDateLabel = view.main.detailsFrame:addLabel():setText(""):setPosition(1,3):setSize(11,1)

    view.main.detailsDescriptionFrame = view.main.programDetailsFrame:addScrollableFrame():setPosition(1,10):setSize("{parent.w-2}",3)
    view.main.detailsDescription = view.main.detailsFrame:addList():setPosition(1, 5):setSize("{parent.w-1}", 3):setSelectionColor(colors.gray, colors.black)

    view.main.buttonFrame = view.main.frame:addFrame():setPosition(2,11):setSize("{parent.w-4}",1)

    view.main.downloadButton = view.main.buttonFrame:addButton():setText("Download"):setPosition(2,1):setSize(8,1):onClick(function(self)buttonClick(self)end):onRelease(function(self)buttonRelease(self)end)
    view.main.updateButton = view.main.buttonFrame:addButton():setText("Update"):setPosition(11,1):setSize(6,1):onClick(function(self)buttonClick(self)end):onRelease(function(self)buttonRelease(self)end)
    view.main.deleteButton = view.main.buttonFrame:addButton():setText("Delete"):setPosition(18,1):setSize(6,1):onClick(function(self)buttonClick(self)end):onRelease(function(self)buttonRelease(self)end)
    view.main.updateAllButton = view.main.buttonFrame:addButton():setText("Update All"):setPosition(25,1):setSize(10,1):onClick(function(self)buttonClick(self)end):onRelease(function(self)buttonRelease(self)end)-- TODO: Add a confirm for this?
end

function view.initConfirmPopup(frame, xPos, yPos, theme)
    -- local result = nil
    local w, h = term.getSize()
    if xPos == nil then
        xPos = w / 2 - 10
    end
    if yPos == nil then
        yPos = math.ceil(h / 2 - 3)
    end

    view.confirmPopup.frame = frame:addFrame():setPosition(tonumber(xPos), tonumber(yPos)):setSize(22, 6):setBackground(colors.yellow)
    view.confirmPopup.popupFrame = view.confirmPopup.frame:addFrame():setPosition(2, 2):setSize("{parent.w-3}", "{parent.h-3}")
    view.confirmPopup.popupLabel = view.confirmPopup.popupFrame:addLabel():setText("Are you sure?"):setPosition(5, 1)
    view.confirmPopup.yesButton = view.confirmPopup.popupFrame:addButton():setText("Yes"):setPosition(3, 3):setSize(7, 1):onClick(function(self) buttonClick(self) end):onRelease(function(self) buttonRelease(self) end)
    view.confirmPopup.noButton = view.confirmPopup.popupFrame:addButton():setText("No"):setPosition(12, 3):setSize(7, 1):onClick(function(self) buttonClick(self) end):onRelease(function(self) buttonRelease(self) end)

    view.confirmPopup.yesButton:onClick(function(self, event, button, x, y)
        if (event == "mouse_click") and (button == 1) then
            os.queueEvent("updateOS_validation", true)
            view.confirmPopup.frame:hide()
        end
    end)

    view.confirmPopup.noButton:onClick(function(self, event, button, x, y)
        if (event == "mouse_click") and (button == 1) then
            os.queueEvent("updateOS_validation", false)
            view.confirmPopup.frame:hide()
        end
    end)
end

function view.addDescription(description)
    view.main.detailsDescription:clear()
    for i = 1, #description do
        view.main.detailsDescription:addItem(description[i])
    end
    -- view.main.detailsDescription:setText(description)
end

function view.updateDownloadStatus(status, theme)
    if status then
        view.main.detailsDownloadStatus:setBackground(theme.downloadStatusTrue)
    else
        view.main.detailsDownloadStatus:setBackground(theme.downloadStatusFalse)
    end
end

function view.updateVersion(version)
    if version == nil then
        version = "N/A"
    end
    view.main.detailsVersion:setText(version)
end

function view.updateUpToDateLabel(upToDate, theme)
    if upToDate ~= 404 then
        if upToDate >= 0 then
            view.main.detailsUpToDateLabel:setText("Up-to-date")
        elseif upToDate < 0 then
            view.main.detailsUpToDateLabel:setText("Can-update")
        end
    end
end

function view.updateProgramDetails(program, upToDateStatus, wrappedDescription, programMetadata, theme)
    view.updateDownloadStatus(program.status, theme)
    if programMetadata ~= nil then
        view.updateVersion(tostring(programMetadata.version))
    else
        view.updateVersion("N/A")
    end
    view.updateUpToDateLabel(upToDateStatus, theme)
    view.addDescription(wrappedDescription)
end



return view