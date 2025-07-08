local programInfo = {
    name = "winchOScmd",
    version = "0.2.0",
    author = "ChefMooon"
}

----- REQUIRE START -----

local lib = {
    base = {
        mooonUtil = {
            path = "mooonOS/common/mooonUtil.lua",
            url = "https://raw.githubusercontent.com/ChefMooon/cc-scripts/mooonOS/mooonOS/common/mooonUtil.lua"
        }
    }
}

if not (fs.exists(lib.base.mooonUtil.path)) then
    shell.run("wget " .. lib.base.mooonUtil.url .. " " .. lib.base.mooonUtil.path)
end
local mooonUtil = require(lib.base.mooonUtil.path:gsub(".lua", ""))

for _, program in pairs(mooonUtil.lib.winchOScmd) do
    if not (fs.exists(program.path)) then
        mooonUtil.downloadFile(program.url, program.path)
    end
end

for _, program in pairs(mooonUtil.lib.common) do
    if not (fs.exists(program.path)) then
        mooonUtil.downloadFile(program.url, program.path)
    end
end

local settingsUtil = mooonUtil.getProgram(mooonUtil.lib.common.settingsUtil.path)
local rednetUtil = mooonUtil.getProgram(mooonUtil.lib.common.rednetUtil.path)
local winchOSUtil = mooonUtil.getProgram(mooonUtil.lib.winchOScmd.winchOSUtil.path)
-- local winchOSUtil = mooonUtil.getProgram("mooonOS/winchOS/winchOSUtil.lua")

----- REQUIRE END -----

------ Program Variables ------

-- Peripherals
local monitors = {peripheral.find("monitor")}
local modem = peripheral.find("modem", rednet.open)

-- Local Variables
local keyword = {
    shutdown = { "shutdown", "exit", "q", "t" },
    request = { "here", "h" },
    settings = { "settings", "reset" },
    info = { "info", "help", "?" }
}

local MEMORY = {
    elevatorFound = false,
    totalFloors = 0,
    currentFloor = 0
}

local tArgs = { ... }
local tArg1 = tostring(tArgs[1])

------ Program Variables End ------

------ Progeram Settings ------
local PROG_SETTING_INFO = {
    elevatorName = programInfo.name ..".elevatorname",
    elevatorNameDefault = "noName",
    floorNum = programInfo.name ..".floornum",
    floorNumDefault = 404,
    terminalType = programInfo.name ..".terminaltype",
    terminalTypeDefault = "noType",
    terminalSecurity = programInfo.name ..".terminalsecurity",
    terminalSecurityDefault = "W", -- W , M, S
    redstoneContactSide = programInfo.name ..".redstonecontactside",
    redstoneContactSideDefault = "back"
}

local PROG_SETTINGS = {
    elevatorName = settingsUtil.define(programInfo.name, PROG_SETTING_INFO.elevatorName, PROG_SETTING_INFO.elevatorNameDefault),
    floorNum = settingsUtil.define(programInfo.name, PROG_SETTING_INFO.floorNum, PROG_SETTING_INFO.floorNumDefault),
    terminalType = settingsUtil.define(programInfo.name, PROG_SETTING_INFO.terminalType, PROG_SETTING_INFO.terminalTypeDefault),
    terminalSecurity = settingsUtil.define(programInfo.name, PROG_SETTING_INFO.terminalSecurity, PROG_SETTING_INFO.terminalSecurityDefault),
    redstoneContactSide = settingsUtil.define(programInfo.name, PROG_SETTING_INFO.redstoneContactSide, PROG_SETTING_INFO.redstoneContactSideDefault),
}

settings.load()

local SETTINGS  = {}

function SETTINGS.getElevatorName()
    return settingsUtil.get(PROG_SETTING_INFO.elevatorName)
end
function SETTINGS.setElevatorName(name)
    settingsUtil.set(PROG_SETTING_INFO.elevatorName, name)
end

function SETTINGS.getFloorNum()
    return settingsUtil.get(PROG_SETTING_INFO.floorNum)
end
function SETTINGS.setFloorNum(num)
    settingsUtil.set(PROG_SETTING_INFO.floorNum, num)
end

function SETTINGS.getTerminalType()
    return settingsUtil.get(PROG_SETTING_INFO.terminalType)
end
function SETTINGS.setTerminalType(type)
    settingsUtil.set(PROG_SETTING_INFO.terminalType, type)
end

function SETTINGS.getTerminalSecurity()
    return settingsUtil.get(PROG_SETTING_INFO.terminalSecurity)
end
function SETTINGS.setTerminalSecurity(security)
    settingsUtil.set(PROG_SETTING_INFO.terminalSecurity, security)
end

function SETTINGS.getRedstoneContactSide()
    return settingsUtil.get(PROG_SETTING_INFO.redstoneContactSide)
end
function SETTINGS.setRedstoneContactSide(side)
    settingsUtil.set(PROG_SETTING_INFO.redstoneContactSide, side)
end

function SETTINGS.setAllSettings(elevatorName, floorNum, terminalType, terminalSecurity, redstoneContactSide)
    SETTINGS.setElevatorName(elevatorName)
    SETTINGS.setFloorNum(floorNum)
    SETTINGS.setTerminalType(terminalType)
    SETTINGS.setTerminalSecurity(terminalSecurity)
    SETTINGS.setRedstoneContactSide(redstoneContactSide)
    settings.save()
end

local function setSettings(elevatorName, floorNum, terminalType, terminalSecurity)
    -- Set the settings for the elevator
    SETTINGS.setElevatorName(elevatorName)
    SETTINGS.setFloorNum(floorNum)
    SETTINGS.setTerminalType(terminalType)
    SETTINGS.setTerminalSecurity(terminalSecurity)
    SETTINGS.setRedstoneContactSide(PROG_SETTING_INFO.redstoneContactSideDefault)
    settings.save()
end

local function getSavedSettings()
    settings.load()
    -- elevatorName = settings.get(settingElevatorName)
    -- floorNum = settings.get(settingfloorNum)
    -- terminalType = settings.get(settingTerminalType)
    -- terminalSecurity = settings.get(settingTerminalSecurity)
end

------ Program Settings End ------

local function getProtocol()
    return programInfo.name .. "_" .. SETTINGS.getElevatorName()
end

local function broadcastMessage(message)
    -- Is this needed?
    -- Broadcast a message on the elevatorName protocol
    -- rednet.broadcast(message, rednetUtil.getProtocol(elevatorName))
    rednet.broadcast(message, getProtocol())
end

-- Find the location of the elevator
local function getElevatorLocation(doPrint)
    if doPrint then
        io.write("\nLooking for elevator... ")
    end

    -- If the elevator is at the current floor return floorNum
    if winchOSUtil.elevatorCheck(SETTINGS.getRedstoneContactSide()) then
        if doPrint then print("Found. Current Floor.") end
        return SETTINGS.getFloorNum()
    else
        -- Otherwise ask the network where it is
        local message = { type = "getFloor" }
        rednet.broadcast(message, getProtocol())
        
        local id, floor = rednet.receive(getProtocol(), 2)
        if floor ~= nil then 
            local number = tonumber(floor["floor"])
            if doPrint then print("Found:", winchOSUtil.getFloorWithSuffix(number), "floor.") end
            return number
        else
            if doPrint then print("Elevator not found.") end
            return 404
        end
    end
end

local function getNetworkInfo()
    -- TODO: make sure to only check if the id is not the id of the current computer
    print("Checking Elevator Network ... ")
    local floors = {rednet.lookup(getProtocol())}
    local terminalID = os.getComputerID
    local totalFloors = 0
    local totalRemotes = 0

    local term = " terminals"
    if #floors == 1 then 
        term = " terminal"
    end
    print(tonumber(#floors), term, " found.")

    -- check what the current floor is
    local terminalType = SETTINGS.getTerminalType()
    if terminalType ~= nil then
        if terminalType == "floor" then
            totalFloors = totalFloors + 1
        elseif terminalType == "remote" then
            totalRemotes = totalRemotes + 1
        end
    end

    -- Iterate through the floors and get more information
    for _, floorID in ipairs(floors) do
        if floorID ~= terminalID then
            print("Getting information for Terminal ID:", floorID)
            local message = { type = "getTerminalInfo" }
            rednet.send(floorID, message, getProtocol())
            local id, message = rednet.receive(getProtocol(), 3)
            
            if id then
                if message["terminalType"] == "floor" then
                        totalFloors = totalFloors + 1
                    elseif message["terminalType"] == "remote" then
                        totalRemotes = totalRemotes + 1
                end
            else
                print("Network Error.")
            end
        end
    end

    print("\n---Network Report---")
    print("Total Floors: ", totalFloors, "\nTotal Remotes:", totalRemotes)

    MEMORY.totalFloors = tonumber(totalFloors)
end

local function setupBroadcast()
    local message = { type = "info", floor = MEMORY.currentFloor, totalFloors = MEMORY.totalFloors }
    rednet.broadcast(message, getProtocol())
end

local function getSettingsFromUser()
    local newSettings = {}

    local floorNameInput
    while true do
        print("Elevator Name (1-256 characters, or type 'cancel' to abort): ")
        floorNameInput = read()
        if floorNameInput:lower() == "cancel" then
            print("Settings update cancelled.")
            return nil
        end
        if winchOSUtil.isValidFloorName(floorNameInput) then
            break
        else
            print("Invalid Floor Name.")
        end
    end
    newSettings.elevatorName = tostring(floorNameInput)

    local floorNumInput
    local isValidFloor = false
    while true do
        print("Floor Number (0-256 for floors, 900-999 for remotes, or type 'cancel' to abort): ")
        floorNumInput = read()
        if floorNumInput:lower() == "cancel" then
            print("Settings update cancelled.")
            return nil
        end
        local validResult = winchOSUtil.isValidFloor(floorNumInput)
        isValidFloor = validResult and validResult.valid
        if isValidFloor then
            newSettings.terminalType = validResult.terminalType
            break
        else
            print("Invalid input. Please enter a valid floor number. (0-256 or 900-999)")
        end
    end
    newSettings.floorNum = tonumber(floorNumInput)

    local terminalSecurityInput
    while true do
        print("Terminal Security (W, M, S) or type 'cancel' to abort:")
        terminalSecurityInput = read()
        if terminalSecurityInput:lower() == "cancel" then
            print("Settings update cancelled.")
            return nil
        end
        if winchOSUtil.isValidTerminalSecurity(terminalSecurityInput) then
            break
        else
            print("Invalid terminal security type.")
        end
    end
    newSettings.terminalSecurity = terminalSecurityInput:upper()

    SETTINGS.setAllSettings(newSettings.elevatorName, newSettings.floorNum, newSettings.terminalType, newSettings.terminalSecurity, PROG_SETTING_INFO.redstoneContactSideDefault)
    return newSettings
end

local function updateSettings()
    local result = getSettingsFromUser()
    if not result then
        print("Settings update aborted.")
        return
    end
    print("\nSettings Updated.")
    print("Name:" , result.elevatorName , "| Number:" , result.floorNum)
    print("Terminal Type:", result.terminalType, "| Terminal Security:", result.terminalSecurity)
end

local function checkSettings()
    local check = {
        elevatorName = SETTINGS.getElevatorName(),
        floorNum = SETTINGS.getFloorNum(),
        terminalType = SETTINGS.getTerminalType(),
        terminalSecurity = SETTINGS.getTerminalSecurity()
    }
    local savedElevatorName = check.elevatorName ~= nil and check.elevatorName ~= PROG_SETTING_INFO.elevatorNameDefault
    local savedFloorNum = check.floorNum ~= nil and check.floorNum ~= PROG_SETTING_INFO.floorNumDefault
    local savedTerminalType = check.terminalType ~= nil and check.terminalType ~= PROG_SETTING_INFO.terminalTypeDefault
    local savedTerminalSecurity = check.terminalSecurity ~= nil
    return savedElevatorName and savedFloorNum and savedTerminalType and savedTerminalSecurity
end

----- This happens on startup -----
local function init()
    term.clear()
    term.setCursorPos(1, 1)
    term.write("Welcome to winchOS. Initializing Setup .")
    sleep(0.1)
    term.write(" .")
    sleep(0.1)
    term.write(" .")
    sleep(0.1)

    -- maybe check if any tArgs at all then do more otherwise checkSettings()

    if #tArgs == 0 then
        -- Startup with saved settings
        -- Check if settings exist
        if checkSettings() then
            -- Get the saved settings from the computer
            print("")
            print("Local Settings Found.")
            -- getSavedSettings()
        else
            getSettingsFromUser() -- if nil settings do something?
        end
    else
        if tArg1 == "reset" then
            -- Startup with new settings
            getSettingsFromUser() -- if nil settings do something?
            
        elseif tArg1 == "info" then
            -- print terminal saved info and exit
            if checkSettings() then
                -- Print saved info
                getSavedSettings()
                print("WinchOS Saved Data Found.")
                -- print("Name:" , elevatorName , "| Number:" , floorNum)
                -- print("Terminal Type:", terminalType, "| Terminal Security:", terminalSecurity)
                print("Name:" , SETTINGS.getElevatorName() , "| Number:" , SETTINGS.getFloorNum())
                print("Terminal Type:", SETTINGS.getTerminalType(), "| Terminal Security:", SETTINGS.getTerminalSecurity())
                os.exit()
            else
                print("No WinchOS Saved Data Found.")
            end
        end
    end

    -- Print new or saved information
    print("\n---Saved Information---")
    print("Name:" , SETTINGS.getElevatorName() , "| Floor Number:" , SETTINGS.getFloorNum())
    print("Terminal Type:", SETTINGS.getTerminalType(), "| Terminal Security:", SETTINGS.getTerminalSecurity())

    -- Get and Set the currnet location of the elevator
    MEMORY.currentFloor = getElevatorLocation(true)
    if MEMORY.currentFloor ~= 404 then
        MEMORY.elevatorFound = true
    end

    -- Get and Set totalFloors
    rednet.host(getProtocol(), tostring(SETTINGS.getFloorNum()))
    getNetworkInfo()

    -- Broadcast info to update network
    setupBroadcast()

    print("---Elevator Setup Complete---\n")
end

----- End of Startup -----

local function redstonePulse()
    redstone.setOutput(SETTINGS.getRedstoneContactSide(), true)
    sleep(1)
    redstone.setOutput(SETTINGS.getRedstoneContactSide(), false)
end

local function requestFloor(floor)
    -- Broadcast on elevatorName protocol to the desired floorNum
    if floor == SETTINGS.getFloorNum() then
        redstonePulse()
    else
        local message = { type = "request", floor = floor }
        rednet.broadcast(message, getProtocol())
    end
    -- term.clear()
end

local function shutdown()
    print("Shutting Down...")

    local message = { type = "info", floor = MEMORY.currentFloor, totalFloors = MEMORY.totalFloors-1 }
    rednet.broadcast(message, getProtocol())
    rednet.unhost(getProtocol())
    modem = peripheral.find("modem", rednet.close)
    for _,monitor in pairs(monitors) do
        monitor.clear()
    end
    redstone.setOutput("back", false)

    print("Shutdown Complete.")
    os.shutdown()
end

local function printFloorInformation()
    print("---Elevator Infomation---")
    print("Elevator Name:", SETTINGS.getElevatorName(), "|", winchOSUtil.getFloorWithSuffix(SETTINGS.getFloorNum()), "floor.")
    print("Total Floors:", MEMORY.totalFloors)
    print("Elevator Location:", winchOSUtil.getFloorWithSuffix(MEMORY.currentFloor), "floor.\n")
end

local function printRemoteInformation()
    print("---Elevator Infomation---")
    print("Elevator Name:", SETTINGS.getElevatorName())
    print("Remote Frequency:", SETTINGS.getFloorNum())
    print("Total Floors:", MEMORY.totalFloors)
    print("Elevator Location:", winchOSUtil.getFloorWithSuffix(MEMORY.currentFloor), "floor.\n")
end

local function printManual()
    print("\n---Elevator Manual---")
    print("This is a winchOS terminal for the elevator system.")
    print("To request the elevator to your current floor enter the floor number, 'here', or 'h'.")
    print("To shut down the terminal, use 'shutdown', 'exit', 'q', or 't'.")
    print("To change settings, use 'settings' or 'reset'.")
    print("For help, use 'info', 'help', or '?'.\n")
end

local function userInput()
    redstone.setOutput(SETTINGS.getRedstoneContactSide(), false) -- Reset redstone

    if terminalType == "floor" then
        printFloorInformation()
    elseif terminalType == "remote" then
        printRemoteInformation()
    end

    print("Enter a valid floor or command.")
    local input = read() -- need validation checks/error handling/clear whitespace

    local isNumber = tonumber(input)

    if isNumber then
        -- If input is a number, process it as a floor request
        if isNumber and tonumber(input) >= 0 then -- and input <= totalFloors 
            -- Send a request to the elevator
            requestFloor(isNumber)
        else
            print("Invalid floor. Please enter a valid floor number.")
        end
    else
        -- If input is not a number, check for keywords
        local keywordFound = false

        -- Check for request keywords
        for _, keyword in ipairs(keyword.request) do
            if input:lower() == keyword then
                keywordFound = true
                if MEMORY.currentFloor ~= SETTINGS.getFloorNum() then
                    requestFloor(SETTINGS.getFloorNum())
                else
                    print("Elevator is on the current floor.")
                end
                break
            end
        end

        -- If request keyword not found, check for shutdown keywords
        if not keywordFound then
            for _, keyword in ipairs(keyword.shutdown) do
                if input:lower() == keyword then
                    keywordFound = true
                    shutdown()
                    break
                end
            end
        end

        -- If shutdown keyword not found, check for settings keywords
        if not keywordFound then
            for _, keyword in ipairs(keyword.settings) do
                if input:lower() == keyword then
                    keywordFound = true
                    updateSettings()
                    break
                end
            end
        end

        -- If settings keyword not found, check for info keywords
        if not keywordFound then
            for _, keyword in ipairs(keyword.info) do
                if input:lower() == keyword then
                    keywordFound = true
                    printManual()
                    break
                end
            end
        end

        -- If no keyword is found, print an error message
        if not keywordFound then
            print("Invalid input. Please enter a valid floor number or a recognized keyword.")
        end
    end
end

local function getNumberLength(number)
    local numString = tostring(number)
    local length = string.len(numString)
    return length
end

local function displaySetup()
    -- Check for even/odd width?
    -- This only accounts for changes in width not height
    for _,monitor in pairs(monitors) do
        local x,y = monitor.getSize()
        local verticalCenterPos = math.floor(x/2)
        local horizontalCenterPos = math.floor(y/2)

        if verticalCenterPos % 2 == 0 then
            verticalCenterPos = verticalCenterPos+1
        end

        if horizontalCenterPos % 2 == 0 then
            horizontalCenterPos = horizontalCenterPos+1
        end

        monitor.clear()
        monitor.setCursorPos(verticalCenterPos-2, horizontalCenterPos-2)
        monitor.write("winchOS")

        -- add st,nd,rd,th -- align center based on length of floors
        monitor.setCursorPos(verticalCenterPos-getNumberLength(winchOSUtil.getFloorWithSuffix(SETTINGS.getFloorNum()))+3, horizontalCenterPos-1)
        monitor.write(winchOSUtil.getFloorWithSuffix(SETTINGS.getFloorNum()))

        monitor.setCursorPos(verticalCenterPos-1, horizontalCenterPos)
        monitor.write("floor")

        monitor.setCursorPos(verticalCenterPos, horizontalCenterPos+2)
        monitor.write("[")
        monitor.write(MEMORY.currentFloor)
        monitor.write("]")
    end
end

local function request(message)
    local requestedFloor = message["floor"]
    if requestedFloor == SETTINGS.getFloorNum() then
        redstonePulse()
    end
end

local function update()
    local message = { type = "info", floor = SETTINGS.getFloorNum(), totalFloors = MEMORY.totalFloors}
    rednet.broadcast(message, getProtocol())
end

local function validRedstoneEvent()
    return  winchOSUtil.elevatorCheck(SETTINGS.getRedstoneContactSide()) and redstone.getAnalogInput(SETTINGS.getRedstoneContactSide()) < 15
end

local function redstoneEvent()
    while true do
        -- Wait for redstone update
        os.pullEvent("redstone")

        -- Check the redstone signal is on
        if validRedstoneEvent() then
            MEMORY.currentFloor = SETTINGS.getFloorNum()
            displaySetup()
            update()
        else
            MEMORY.currentFloor = getElevatorLocation(false)
            if MEMORY.currentFloor ~= 404 then
                MEMORY.elevatorFound = true
            else
                MEMORY.elevatorFound = false
            end
            displaySetup()
        end
    end
end

local function monitorEvent()
    -- When a new monitor is added update the monitors list and the displays
    -- Change this to only update the monitor added, not all
    while true do
        local event, side = os.pullEvent("peripheral")
        if event == "peripheral" and peripheral.getType(side) == "monitor"then
            monitors = {peripheral.find("monitor")}
            displaySetup()
        end
    end
end

local function monitorResize()
    -- When an attached monitor is resized update the display
    -- TODO: change this to only update the montior resized
    local event, side = os.pullEvent("monitor_resize")
    if event == "monitor_resize" then
        monitors = {peripheral.find("monitor")}
            displaySetup()
    end
end

local function updateInfo(message)
    -- Update saved information about the elevator and update the monitors
    MEMORY.currentFloor = message["floor"]
    MEMORY.totalFloors = message["totalFloors"]
    displaySetup()
    term.clear()
end

local function getFloor(id)
    if MEMORY.currentFloor == SETTINGS.getFloorNum() then
        local message = { type = "getFloor", floor = SETTINGS.getFloorNum() }
        rednet.send(id, message, getProtocol())
    end
end

local function getTerminalInfo(id)
    -- TODO: maybe check for nil terminalType? add security level info?
    local message = { terminalType = SETTTINGS.getTerminalType() }
    rednet.send(id, message, getProtocol())
end

local function receiveRequest()
    -- Wait for request, if valid interact with redstone
    -- Do Validation
    while true do
        local id, message = rednet.receive(getProtocol())
        local type = message["type"]
        if type == "request" then
            -- If the floor requested is the current floor Power the redstone
            request(message)
        elseif type == "getFloor" then
            -- Broadcast a message if the elevator is on this floor
            getFloor(id)
        elseif type == "getTerminalInfo" then
            -- Send a message back with info
            getTerminalInfo(id)
        elseif type == "info" then
            -- Update current location of elevator and Displays
            updateInfo(message)
        else
            -- Invalid message
            print("Invalid Message.")
        end
    end
end

-- Setup & Main Loop
init()
displaySetup()

while true do
    -- Wait for User Input(floor request), Event(elevator on the floor), or a Request
    parallel.waitForAny(userInput, redstoneEvent, receiveRequest, monitorEvent, monitorResize)
end