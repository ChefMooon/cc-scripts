-- winchOScmd V0.1.0
-- Created by: ChefMooon

-- this will help filter broadcast messages
local programName = "winchOS"

-- Peripherals
local monitors = {peripheral.find("monitor")}
local modem = peripheral.find("modem", rednet.open)

-- Local Variables
local shutdownKeywords = { "shutdown", "exit", "q", "t" }
local requestKeywords = { "here", "h"}
local settingKeywords = { "settings" }
local elevatorName, floorNum
local terminalType, terminalSecurity
local numFloors, currentFloor = 0
local redstoneContactSide = "back"

local tArgs = { ... }
local tArg1 = tostring(tArgs[1])

-- Settings Definition
local settingElevatorName = programName ..".elevatorname"
local settingElevatorNameDefault = "noName"
settings.define(settingElevatorName, {
    description = programName .. " - Elevator Name",
    default = settingElevatorNameDefault,
})

local settingfloorNum = programName ..".floornum"
local settingfloorNumDefault = 01234
settings.define(settingfloorNum, {
    description = programName .. " - Floor Number",
    default = settingfloorNumDefault,
    type = number,
})

local settingTerminalType = programName ..".terminaltype"
local settingTerminalTypeDefault = "noType"
settings.define(settingTerminalType, {
    description = programName .. " - Terminal Type",
    default = settingTerminalTypeDefault,
})

local settingTerminalSecurity = programName ..".terminalsecurity"
local settingTerminalSecurityDefault = "W" -- W, M, S
settings.define(settingTerminalSecurity, {
    description = programName .. " - Terminal Security",
    default = settingTerminalSecurityDefault,
})

local function getProtocol(protocol)
    return programName .. "_" .. protocol
end

local function getNumberWithSuffix(number)
    local suffix
    if number ~= nil then
        if number == 0 then
            suffix = ""
        -- Special case for numbers ending in 11, 12, or 13 (use "th" suffix)
        elseif number % 100 >= 11 and number % 100 <= 13 then
            suffix = "th"
        else
            -- For other numbers, determine the appropriate suffix based on the last digit
            local lastDigit = number % 10
            if lastDigit == 1 then
                suffix = "st"
            elseif lastDigit == 2 then
                suffix = "nd"
            elseif lastDigit == 3 then
                suffix = "rd"
            else
                suffix = "th"
            end
        end
    
        -- Concatenate the number and suffix and return the result
        return number .. suffix
    else
        return ""
    end
end

local function elevatorCheck()
    return redstone.getInput(redstoneContactSide)
end

local function getElevatorLocation()
-- This should check where the elevator is Currently
    io.write("Looking for elevator... ")

    -- If the elevator is at the current floor return floorNum
    if elevatorCheck() then
        print("Found. Current Floor.")
        return floorNum
    else
        -- Otherwise ask the network where it is
        local message = { type = "getFloor" }
        rednet.broadcast(message, getProtocol(elevatorName))
        
        local id, floor = rednet.receive(getProtocol(elevatorName), 2)
        if floor ~= nil then 
            local number = tonumber(floor["floor"])
            print("Found:", getNumberWithSuffix(number), "floor.")
            return number
        else
            print("Elevator not found.")
            return 0
        end
    end
end

local function getNetworkInfo()
    -- TODO: make sure to only check if the id is not the id of the current computer

    print("Checking Elevator Network ... ")
    local floors = {rednet.lookup(getProtocol(elevatorName))}
    local terminalID = os.getComputerID
    local totalFloors = 0
    local totalRemotes = 0

    print(tonumber(#floors)- 1, "terminals found.")

    -- check what the current floor is
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
            rednet.send(floorID, message, getProtocol(elevatorName))
            local id, message = rednet.receive(getProtocol(elevatorName), 3)
            
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

    numFloors = tonumber(totalFloors)
end

local function setupBroadcast()
    local message = { type = "info", floor = currentFloor, numFloors = numFloors }
    rednet.broadcast(message, getProtocol(elevatorName))
end

local function isValidFloorName(floorName)
    local string = tostring(floorName)
    return string and string ~= "" and #string <= 256
end

local function isValidFloor(floor)
    -- TOOD: nil check?
    local number = tonumber(floor)
    local isFloor = number >= 0 and number <= 256
    local isRemote = number >= 900 and number <= 999
    if isFloor then
        terminalType = "floor"
    elseif isRemote then
        terminalType = "remote"
    end
    return isFloor or isRemote
end

local function isValidTerminalSecurity(terminalSecurity)
    local validSecurityTypes = { "W", "M", "S" }
    for _, validType in ipairs(validSecurityTypes) do
        if terminalSecurity == validType then
            return true
        end
    end
    return false
end

local function setSettings()
    settings.set(settingElevatorName, elevatorName)
    settings.set(settingfloorNum, floorNum)
    settings.set(settingTerminalType, terminalType)
    settings.set(settingTerminalSecurity, terminalSecurity)
    settings.save()
    print("Settings Saved.")
end

local function getSettingsFromUser()
    -- Basic Information User Input
    local floorNameInput
    repeat
        io.write("Elevator Name: ")
        floorNameInput = read()

        if not isValidFloorName(floorNameInput) then
            print("Invalid Floor Name.") -- describe more
        end
    until isValidFloorName(floorNameInput)
    elevatorName = tostring(floorNameInput)

    local floorNumInput
    repeat
        io.write("Floor Number: ")
        floorNumInput = read()

        if not isValidFloor(floorNumInput) then
            print("Invalid input. Please enter a valid floor number. (0-256 or 900-999)")
        end
    until isValidFloor(floorNumInput)
    floorNum = tonumber(floorNumInput)

    local terminalSecurityInput
    repeat
        io.write("Terminal Security: ")
        terminalSecurityInput = read()

        if not isValidTerminalSecurity(terminalSecurityInput) then
            print("Invalid terminal security type. Please enter 'W', 'M', or 'S'.")
        end
    until isValidTerminalSecurity(terminalSecurityInput)
    terminalSecurity = tostring(terminalSecurityInput)

    setSettings()
end

local function updateSettings()
    getSettingsFromUser()
    print("\nSettings Updated.")
    print("Name:" , elevatorName , "| Number:" , floorNum)
    print("Terminal Type:", terminalType, "| Terminal Security:", terminalSecurity)
end

local function getSavedSettings()
    settings.load()
    elevatorName = settings.get(settingElevatorName)
    floorNum = settings.get(settingfloorNum)
    terminalType = settings.get(settingTerminalType)
    terminalSecurity = settings.get(settingTerminalSecurity)
end

local function checkSettings()
    local savedElevatorName = settings.get(settingElevatorName) ~= nil and settings.get(settingElevatorName) ~= settingElevatorNameDefault
    local savedFloorNum = settings.get(settingfloorNum) ~= nil and settings.get(settingfloorNum) ~= settingfloorNumDefault
    local savedTerminalType = settings.get(settingTerminalType) ~= nil and settings.get(settingTerminalType) ~= settingTerminalTypeDefault
    local savedTerminalSecurity = settings.get(settingTerminalSecurity) ~= nil
    return savedElevatorName and savedFloorNum and savedTerminalType and savedTerminalSecurity
end

----- This happens on startup -----
local function init()
    term.clear()
    print("---Begin Elevator Setup---\n")
    -- maybe check if any tArgs at all then do more otherwise checkSettings()

    if #tArgs == 0 then
        -- Startup with saved settings
        -- Check if settings exist
        if checkSettings() then
            -- Get the saved settings from the computer
            print("Local Settings Found.")
            getSavedSettings()
        else
            getSettingsFromUser()
        end
    else
        if tArg1 == "reset" then
            -- Startup with new settings
            getSettingsFromUser()
        elseif tArg1 == "info" then
            -- print terminal saved info and exit
            if checkSettings() then
                -- Print saved info
                getSavedSettings()
                print("WinchOS Saved Data Found.")
                print("Name:" , elevatorName , "| Number:" , floorNum)
                print("Terminal Type:", terminalType, "| Terminal Security:", terminalSecurity)
                os.exit()
            else
                print("No WinchOS Saved Data Found.")
            end
        end
    end

    -- Print new or saved information
    print("\n---Saved Information---")
    print("Name:" , elevatorName , "| Number:" , floorNum)
    print("Terminal Type:", terminalType, "| Terminal Security:", terminalSecurity)

    -- Get and Set the currnet location of the elevator
    currentFloor = getElevatorLocation()

    -- Get and Set the total numFloors
    rednet.host(getProtocol(elevatorName), tostring(floorNum))
    getNetworkInfo()

    -- Broadcast info to update network
    setupBroadcast()

    print("---Elevator Setup Complete---\n")
end
----- End of Startup -----

local function redstonePulse()
    redstone.setOutput(redstoneContactSide, true)
    sleep(1)
    redstone.setOutput(redstoneContactSide, false)
end

local function requestFloor(floor)
    -- Broadcast on elevatorName protocol to the desired floorNum
    if floor == floorNum then
        redstonePulse()
    else
        local message = { type = "request", floor = floor }
        rednet.broadcast(message, getProtocol(elevatorName))
    end
    term.clear()
end

local function shutdown()
    print("Shutting Down...")

    local message = { type = "info", floor = currentFloor, numFloors = numFloors-1 }
    rednet.broadcast(message, getProtocol(elevatorName))
    rednet.unhost(getProtocol(elevatorName))
    modem = peripheral.find("modem", rednet.close)
    for _,monitor in pairs(monitors) do
        monitor.clear()
    end
    redstone.setOutput("back", false)

    print("Shutdown Complete.")
    os.exit()
end

local function printFloorInformation()
    print("---Elevator Infomation---")
    print("Elevator Name:", elevatorName, "|", getNumberWithSuffix(floorNum), "floor.")
    print("Total Floors:", numFloors)
    print("Elevator Location:", getNumberWithSuffix(currentFloor), "floor.\n")
end

local function printRemoteInformation()
    print("---Elevator Infomation---")
    print("Elevator Name:", elevatorName)
    print("Remote Frequency:", floorNum)
    print("Total Floors:", numFloors)
    print("Elevator Location:", getNumberWithSuffix(currentFloor), "floor.\n")
end

local function userInput()
    redstone.setOutput(redstoneContactSide, false) -- Reset redstone

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
        if isNumber and tonumber(input) >= 0 then -- and input <= numFloors 
            -- Send a request to the elevator
            requestFloor(isNumber)
        else
            print("Invalid floor. Please enter a valid floor number.")
        end
    else
        -- If input is not a number, check for keywords
        local keywordFound = false

        -- Check for request keywords
        for _, keyword in ipairs(requestKeywords) do
            if input:lower() == keyword then
                keywordFound = true
                if currentFloor ~= floorNum then
                    requestFloor(floorNum)
                else
                    print("Elevator is on the current floor.")
                end
                break
            end
        end

        -- If request keyword not found, check for shutdown keywords
        if not keywordFound then
            for _, keyword in ipairs(shutdownKeywords) do
                if input:lower() == keyword then
                    keywordFound = true
                    shutdown()
                    break
                end
            end
        end

        -- If shutdown keyword not found, check for settings keywords
        if not keywordFound then
            for _, keyword in ipairs(settingKeywords) do
                if input:lower() == keyword then
                    keywordFound = true
                    updateSettings()
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
        monitor.setCursorPos(verticalCenterPos-getNumberLength(getNumberWithSuffix(floorNum))+3, horizontalCenterPos-1)
        monitor.write(getNumberWithSuffix(floorNum))

        monitor.setCursorPos(verticalCenterPos-1, horizontalCenterPos)
        monitor.write("floor")

        monitor.setCursorPos(verticalCenterPos, horizontalCenterPos+2)
        monitor.write("[")
        monitor.write(currentFloor)
        monitor.write("]")
    end
end

local function request(message)
    local requestedFloor = message["floor"]
    if requestedFloor == floorNum then
        redstonePulse()
    end
end

local function update()
    local message = { type = "info", floor = floorNum, numFloors = numFloors}
    rednet.broadcast(message, getProtocol(elevatorName))
end

local function validRedstoneEvent()
    return  elevatorCheck() and redstone.getAnalogInput(redstoneContactSide) < 15
end

local function event()
    while true do
        -- Wait for redstone update
        os.pullEvent("redstone")

        -- Check the redstone signal is on
        if validRedstoneEvent() then
            currentFloor = floorNum
            displaySetup()
            update()
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
    currentFloor = message["floor"]
    numFloors = message["numFloors"]
    displaySetup()
    term.clear()
end

local function getFloor(id)
    if currentFloor == floorNum then
        local message = { type = "getFloor", floor = floorNum }
        rednet.send(id, message, getProtocol(elevatorName))
    end
end

local function getTerminalInfo(id)
    -- TODO: maybe check for nil terminalType? add security level info?
    local message = { terminalType = terminalType }
    rednet.send(id, message, getProtocol(elevatorName))
end

local function receiveRequest()
    -- Wait for request, if valid interact with redstone
    -- Do Validation
    local type
    repeat
        local id, message = rednet.receive(getProtocol(elevatorName))
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
    until type == "info"
end

-- Setup & Main Loop
init()
displaySetup()

while true do
    -- Wait for User Input(floor request), Event(elevator on the floor), or a Request
    parallel.waitForAny(userInput, event, receiveRequest, monitorEvent, monitorResize)
end