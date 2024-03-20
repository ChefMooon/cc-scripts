-- digOS-mid-out V0.1.0
-- Created by: ChefMooon

turtle.select(1)

-- Variables
local yPos, zPos = 0, 0
local layersMined = 0
local blocksMined = 0
local turtleFuel = 0
local turtleFuelSlot = 1
local turtleOptimalFuel = 100

local torchPlaced = false
local torchSpacing = 7 -- TODO: torch spacing variable based on arg

local inventoryStatus = nil
local availableInventorySlots = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16}
local inventoryTorchSlot = 16
local inventoryChestSlot = 15

local args = { ... }
local command = args[1] or ""
local length = tonumber(args[2]) or 0
local width = tonumber(args[3]) or 0
local height = tonumber(args[4]) or 0
local offsetDir = args[5] or "r"
local torch = args[6] or false
local chest = args[7] or false
local rts = args[8] or false

local validStorageTags = { "c:chests" }
local validTorchNames = { "minecraft:torch" }

local errors = 0
local errorMessages = { "woops, something went wrong.", "try again.", "that did not work." }
local errorMessagesExtra = { "no really... try again.", "wrong choice.", "ERROR ... just kidding.", "might be ...user error." }

local function getErrorMessage()
    message = ""
    errors = errors + 1
    if errors <= 5 then
        local messageID = math.random(1, #errorMessages)
        message = errorMessages[messageID]
    else
        local messageID = math.random(1, #errorMessagesExtra)
        message = errorMessagesExtra[messageID]
    end
    return message
end

local function sendJobUpdate(_message)
    os.queueEvent("digOS_job_update", { _message, turtleFuel })
end

local function sendJobInput(_message)
    local result, validResult = false
    os.queueEvent("digOS_job_input", _message)
    repeat
        local event, input = os.pullEvent("digOS_job_input_result")
        if type(input) == "string" then
            if input == "y" then
                validResult = true
                result = true
            elseif input == "n" then
                validResult = true
                result = false
            else
                result = true
            end
        end
        os.queueEvent("digOS_job_input_valid", validResult)
    until validResult == true
    return result
end

local function addAvailableInventorySlot(_slot)
    local index = 1
    while index <= #availableInventorySlots and availableInventorySlots[index] < newItem do
        index = index + 1
    end
    table.insert(availableInventorySlots, index, newItem)
end

local function removeAvailableInventorySlot(_slot)
    for i, slot in ipairs(availableInventorySlots) do
        if slot == _slot then
            table.remove(availableInventorySlots, i)
            return true
        end
    end
    return false
end

local function emptyInventorySlots()
    local emptySlots = 0
    for _, slot in ipairs(availableInventorySlots) do
        local itemCount = turtle.getItemCount(slot)
        if itemCount == 0 then
            emptySlots = emptySlots + 1
        end
    end
    return emptySlots
end

local function isInventoryFull()
    for _, slot in ipairs(availableInventorySlots) do
        local itemCount = turtle.getItemCount(slot)
        if itemCount == 0 then
            return false
        end
    end
    return true
end

local function isInventoryEmpty()
    for _, slot in ipairs(availableInventorySlots) do
        local itemCount = turtle.getItemCount(slot)
        if itemCount ~= 0 then
            return false
        end
    end
    return true
end

local function startupInventoryCheck()
    repeat
        sendJobUpdate("Checking Inventory...")
        if isInventoryEmpty() then
            inventoryStatus = "checked"
            sendJobUpdate("Valid Inventory")
            return true
        else
            local result = sendJobInput("Inventory must be empty. Resume?(Y/N)")
            if not result then
                sendJobUpdate("Job Cancelled.")
                return false
            end
        end
    until inventoryStatus ~= nil
end

local function detectDig()
    local mined = 0
    while turtle.detect() do
        turtle.dig()
        mined = mined + 1
    end
    return mined
end

local function detectDigUp()
    local mined = 0
    while turtle.detectUp() do
        turtle.digUp()
        mined = mined + 1
    end
    return mined
end

local function detectDigDown()
    local mined = 0
    while turtle.detectDown() do
        turtle.digDown()
        mined = mined + 1
    end
    return mined
end

local function moveForward()
    turtle.forward()
    yPos = yPos + 1
end

local function moveBack()
    turtle.back()
    yPos = yPos - 1
end

local function moveUp()
    turtle.up()
    zPos = zPos + 1
end

local function moveDown()
    turtle.down()
    zPos = zPos - 1
end

local function zPosReset()
    repeat
        if zPos > 0 then
            if turtle.detectDown() then
                moveBack()
                layersMined = layersMined - 1
            end
            moveDown()
        elseif zPos < 0 then
            if turtle.detectUp() then
                moveBack()
                layersMined = layersMined - 1
            end
            moveUp()
        end
    until zPos == 0
end

local function halfSpin()
    turtle.turnRight()
    turtle.turnRight()
end

local function updateTurtleFuel()
    turtleFuel = turtle.getFuelLevel()
end

local function getRequiredRemainingFuel()
    local remainingLength = length - layersMined
    local wFuel = 1
    if width > 2 then
        wFuel = width - 2
    end
    return ((wFuel * height) * remainingLength) + layersMined + length
end

local function getRequiredFuel()
    local wFuel = 1
    if width > 2 then
        wFuel = width - 2
    end
    return ((wFuel * height) * length) + (length * 2) -- maybe only length * 1
end

local function runningFuelCheck()
    if turtleFuel - getRequiredRemainingFuel() > turtleOptimalFuel then
        return true
    else
        return false
    end
end

local function startFuelCheck()
    if turtleFuel - getRequiredFuel() > turtleOptimalFuel then
        return true
    else
        return false
    end
end

local function tryRefuel()
    sendJobUpdate("Attempting Refuel.")
    local refuelled = false
    local selectedSlot = turtle.getSelectedSlot()
    for _, slot in ipairs(availableInventorySlots) do
        turtle.select(slot)
        local result = turtle.refuel()
        if result then
            sendJobUpdate("Fuel Consumed.")
            refuelled = true
        end
    end
    if refuelled then
        turtleFuel = turtle.getFuelLevel()
        if startFuelCheck() then
            sendJobUpdate("Valid Refuel.")
        else
            sendJobUpdate("More Fuel Required.")
            refuelled = false
        end
    else
        sendJobUpdate("Refuel Failed. No Available Fuel.")
    end
    turtle.select(selectedSlot)
    return refuelled
end

local function returnToStart()
    sendJobUpdate("Returning to Start.")
    local torchOffset = torch == "true" and torchPlaced == true
    zPosReset()
    if torchOffset then
        moveUp()
    end
    repeat
        moveBack()
    until yPos == 0
    if torchOffset then
        moveDown()
    end
    updateTurtleFuel()
end

local function returnToJob()
    sendJobUpdate("Returning to Job.")
    local torchOffset = torch == "true" and torchPlaced == true
    if torchOffset then
        moveUp()
    end
    for i = 1, layersMined do
        moveForward()
    end
    if torchOffset then
        moveDown()
    end
    updateTurtleFuel()
end

local function emptyAll()
    while true do
        local selectedSlot = turtle.getSelectedSlot()
        sendJobUpdate("Emptying Inventory...")
        for _, slot in ipairs(availableInventorySlots) do
            turtle.select(slot)
            local drop, err = turtle.drop()
        end
        turtle.select(selectedSlot)
        if not isInventoryEmpty() then
            local result = sendJobInput("Chest Full. Resume?(Y/N)")
            if not result then
                sendJobUpdate("Job Cancelled.")
                return false
            end
        else
            return true
        end
    end
end

local function placeChest()
    local selectedSlot = turtle.getSelectedSlot()
    turtle.select(inventoryChestSlot)
    turtle.place()
    turtle.select(selectedSlot)
end

local function tryEmptyInventory()
    local ok, err = true, ""
    sendJobUpdate("Attempt Empty Inventory")
    halfSpin()
    local isBlock, block = turtle.inspect()
    if isBlock then
        if block.tags then
            for i = 1, #validStorageTags do
                if block.tags[validStorageTags[i]] then
                    if emptyAll() then
                        halfSpin()
                        sendJobUpdate("Inventory Emptied.")
                        return ok, err
                    end
                end
            end
        end
    elseif turtle.getItemCount(inventoryChestSlot) > 0 then
        placeChest()
        if emptyAll() then
            halfSpin()
            sendJobUpdate("Inventory Emptied.")
            return ok, err
        end
    else
        while true do
            local result = sendJobInput("No Chest Found. Resume?(Y/N)")
            if not result then
                halfSpin()
                sendJobUpdate("Job Cancelled.")
                ok = false
                err = "no chest found"
                return ok, err
            end
        end
    end
    return ok, err
end

local function checkInventoryAndEmpty()
    local ok, err = true, ""
    if emptyInventorySlots() <= 2 then
        sendJobUpdate("Inventory Full.")
        returnToStart()
        ok, err = tryEmptyInventory()
        if ok then
            if not runningFuelCheck() then
                while true do
                    local result = sendJobInput("More Fuel Required. Refuel?(Y/N)")
                    if result then
                        if tryRefuel() then
                            break
                        end
                    else
                        ok = false
                        err = "insufficient fuel"
                        return ok, err
                    end
                end
            else
                returnToJob()
            end
        end
    end
    return ok, err
end

local function checkInventoryAndWait()
    local ok, err = true, ""
    if emptyInventorySlots() <= 1 then
        zPosReset()
        while true do
            local result = sendJobInput("Empty Inventory and Resume?(Y/N)")
            if result then
                if isInventoryEmpty() then
                    break
                else
                    sendJobUpdate(getErrorMessage())
                end
            else
                ok = false
                err = "inventory full."
                return ok, err
            end
        end
    end
    return ok, err
end

local function endEmptyInventory()
    local ok, err = true, ""
    if yPos ~= 0 then
        returnToStart()
    end
    ok, err = tryEmptyInventory()
    return ok, err
end

local function digRowPattern1(width, offsetDir)
    local mined = 0
    local left = 0
    local right = 0
    if width > 1 then
        if width > 2 then
            left = math.floor(width / 2)
            right = math.floor(width / 2)
        end
        if width % 2 == 0 then
            if offsetDir == "r" then
                right = right + 1
            else
                left = left + 1
            end
        elseif width > 4 then
            right = right + 1
            left = left + 1
        end

        if right > 0 then
            turtle.turnRight()
            mined = mined + detectDig()
            if right > 1 then
                for i = 1, right - 2 do
                    turtle.forward()
                    mined = mined + detectDig()
                end
                for j = 1, right - 2 do
                    turtle.back()
                end
            end
            turtle.turnLeft()
        end
        if left > 0 then
            turtle.turnLeft()
            mined = mined + detectDig()
            if left > 1 then
                for k = 1, left - 2 do
                    turtle.forward()
                    mined = mined + detectDig()
                end
                for l = 1, left - 2 do
                    turtle.back()
                end
            end
            turtle.turnRight()
        end
    end
    return mined
end

local function digLayerPattern1(direction, length, width, height, offsetDir)
    local mined = 0
    if direction ~= nil and tonumber(length) and tonumber(height) and tonumber(width) and offsetDir ~= nil then
        mined = mined + detectDig()
        moveForward()
        mined = mined + digRowPattern1(width, offsetDir)
        if height > 1 then
            if direction == "up" then
                for i = 1, height - 1 do
                    mined = mined + detectDigUp()
                    moveUp()
                    mined = mined + digRowPattern1(width, offsetDir)
                end
            elseif direction == "down" then
                for i = 1, height - 1 do
                    mined = mined + detectDigDown()
                    moveDown()
                    mined = mined + digRowPattern1(width, offsetDir)
                end
            end
        end
    end
    return mined
end

local function digPattern1(length, width, height, offsetDir, torch, chest, rts)
    local mined = 0
    local ok, err = true, ""
    for i = 1, length do
        if zPos == 0 then
            mined = mined + digLayerPattern1("up", length, width, height, offsetDir)
        else
            mined = mined + digLayerPattern1("down", length, width, height, offsetDir)
        end
        layersMined = layersMined + 1
        updateTurtleFuel()
        if torch == "true" and (layersMined > 1 and (layersMined-1) % torchSpacing == 1) then
            local initSlot = turtle.getSelectedSlot()
            turtle.select(inventoryTorchSlot)
            local item = turtle.getItemDetail()
            if item then
                if item.name then
                    for i = 1, #validTorchNames do
                        if item.name == validTorchNames[i] then
                            if zPos > 0 then
                                repeat
                                    moveDown()
                                until zPos == 0
                            end
                            halfSpin()
                            local ok, err = turtle.place()
                            if ok and torchPlaced == false then
                                torchPlaced = true
                            end
                            halfSpin()
                        end
                    end
                end
            end
            turtle.select(initSlot)
        end
        if chest == "true" then
            ok, err = checkInventoryAndEmpty()
            if not ok then
                return ok, err
            end
        else
            ok, err = checkInventoryAndWait()
            if not ok then
                return ok, err
            end
        end
        sendJobUpdate("layer "..tostring(layersMined).." of "..tostring(length).." Complete.")
    end
    zPosReset()
    if rts == "true" then
        returnToStart()
    end
    if chest == "true" then
        ok, err = endEmptyInventory()
        if not ok then
            return ok, err
        end
    end
    blocksMined = mined
    return ok, err
end

if torch == "true" then
    removeAvailableInventorySlot(inventoryTorchSlot)
end
if chest == "true" then
    removeAvailableInventorySlot(inventoryChestSlot)
end

if command == "run" then
    turtleFuel = turtle.getFuelLevel()
    while true do
        if inventoryStatus == nil then
            if not startupInventoryCheck() then
                break
            end
        end
        if startFuelCheck() then
            sendJobUpdate("Job Started...")
            local ok, err = digPattern1(length, width, height, offsetDir, torch, chest, rts)
            if ok then
                sendJobUpdate("Job Complete. "..tostring(blocksMined).." Blocks Mined.")
            else
                sendJobUpdate("Job Cancelled, "..err)
            end
            break
        else
            local requiredFuel = tostring(turtleOptimalFuel + getRequiredFuel())
            local result = sendJobInput(requiredFuel.." Fuel Required. Refuel?(Y/N)")
            if result then
                tryRefuel()
            else
                sendJobUpdate("Job Cancelled.")
                break
            end
        end
    end
end