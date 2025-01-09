local programInfo = {
    name = "digUtil",
    version = "1.0.0",
    author = "ChefMooon"
}

-- This program contains all functions related to turtle movement with optional digging
--PROGRAM TODO--
-- 

local digUtil = {}

digUtil.CONST = {
    DIG_MAX = 1000,
    DIG_MIN = 1,
    TORCH_SPACING_MIN = 1,
    TORCH_SPACING_MAX = 16,
    DEFAULT_TORCH_SPACING = 7,
    DEFAULT_TORCH_SLOT = 15,
    DEFAULT_CHEST_SLOT = 16
}

function digUtil.forward(count, dig)
    local moveSuccess, digSuccess = true, true
    local moveCount, digCount = 0, 0
    local moveError, digError
    if count == nil then count = 1 end
    for i = 1, count do
        if dig then
            while turtle.detect() do
                digSuccess, digError = turtle.dig()
                if digSuccess then
                    digCount = digCount + 1
                end
            end
        end
        moveSuccess, moveError = turtle.forward()
        if not moveSuccess then break end
        moveCount = moveCount + 1
    end
    return moveSuccess, moveCount, digCount, moveError, digError
end

function digUtil.down(count, dig)
    local moveSuccess, digSuccess = true, true
    local moveCount, digCount = 0, 0
    local moveError, digError
    if count == nil then count = 1 end
    for i = 1, count do
        if dig then
            while turtle.detectDown() do
                digSuccess, digError = turtle.digDown()
                if digSuccess then
                    digCount = digCount + 1
                end
            end
        end
        moveSuccess, moveError = turtle.down()
        if not moveSuccess then break end
        moveCount = moveCount + 1
    end
    return moveSuccess, moveCount, digCount, moveError, digError
end

function digUtil.up(count, dig)
    local moveSuccess, digSuccess = true, true
    local moveCount, digCount = 0, 0
    local moveError, digError
    if count == nil then count = 1 end
    for i = 1, count do
        if dig then
            while turtle.detectUp() do
                digSuccess, digError = turtle.digUp()
                if digSuccess then
                    digCount = digCount + 1
                end
            end
        end
        moveSuccess, moveError = turtle.up()
        if not moveSuccess then break end
        moveCount = moveCount + 1
    end
    return moveSuccess, moveCount, digCount, moveError, digError
end

function digUtil.back(count)
    local moveSuccess, moveCount, moveError = true, 0
    if count == nil then count = 1 end
    for i = 1, count do
        moveSuccess, moveError = turtle.back()
        if not moveSuccess then break end
        moveCount = moveCount + 1
    end
    return moveSuccess, moveCount, moveError
end

function digUtil.left(count)
    local moveSuccess, moveError = true, 0
    if count == nil then count = 1 end
    for i = 1, count do
        moveSuccess, moveError = turtle.turnLeft()
        if not moveSuccess then break end
    end
    return moveSuccess, moveError
end

function digUtil.right(count)
    local moveSuccess, moveError = true
    if count == nil then count = 1 end
    for i = 1, count do
        moveSuccess, moveError = turtle.turnRight()
        if not moveSuccess then break end
    end
    return moveSuccess, moveError
end

-- todo shift functions are unused and untest, make them work?
function digUtil.shiftLeft(count, dig)
    local leftSuccess, leftMoveError = left(1)
    if not leftSuccess then return leftSuccess, leftMoveError end
    local moveSuccess, moveCount, digCount, moveError, digError = forward(count, dig)
    if not moveSuccess then return moveSuccess, moveCount, digCount, moveError, digError end
    local rightSuccess, rightMoveError = right(1)
    if not rightSuccess then return rightSuccess, rightMoveError end
    return true, moveCount, digCount
end

function digUtil.shiftRight(count, dig)
    local rightSuccess, rightMoveError = right(1)
    if not rightSuccess then return rightSuccess, rightMoveError end
    local moveSuccess, moveCount, digCount, moveError, digError = forward(count, dig)
    if not moveSuccess then return moveSuccess, moveCount, digCount, moveError, digError end
    local leftSuccess, leftMoveError = left(1)
    if not leftSuccess then return leftSuccess, leftMoveError end
    return true, moveCount, digCount
end

function digUtil.getTurtleIDLabel()
    local result = ""
    local id = os.getComputerID()
    local label = os.getComputerLabel()
    if id ~= nil then
        result = id
    end
    if label ~= nil then
        result = result.."-"..label
    end
    return result
end

---- DATA SERIALIZER / DESERIALIZER
function digUtil.createDigArgsTable(program, command, length, width, height, offsetDir, torch, torchDistance, torchSlot, chest, chestSlot, rts, ignoreInventory, ignoreFuel, noPickup, blockWhiteList, blockBlackList)
    local digArgs = {
        program = program,
        command = command,
        length = length,
        width = width,
        height = height,
        offsetDir = offsetDir,
        torch = {
            torch = torch,
            distance = torchDistance,
            slot = torchSlot
        },
        chest = {
            chest = chest,
            slot = chestSlot
        },
        rts = rts,
        ignoreInventory = ignoreInventory,
        ignoreFuel = ignoreFuel,
        noPickup = noPickup,
        blockWhiteList = blockWhiteList,
        blockBlackList = blockBlackList
    }
    return digArgs
end

function digUtil.digArgsTableToString(digArgs)
    return table.concat( { 
        digArgs.program,
        tostring(digArgs.command),
        tostring(digArgs.length),
        tostring(digArgs.width),
        tostring(digArgs.height),
        tostring(digArgs.offsetDir),
        tostring(digArgs.torch.torch), tostring(digArgs.torch.distance), tostring(digArgs.torch.slot),
        tostring(digArgs.chest.chest), tostring(digArgs.chest.slot),
        tostring(digArgs.rts),
        tostring(digArgs.ignoreInventory),
        tostring(digArgs.ignoreFuel),
        tostring(digArgs.noPickup),
        tostring(digArgs.blockWhiteList),
        tostring(digArgs.blockBlackList)
    }, " ")
end

return digUtil