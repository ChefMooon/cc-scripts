local programInfo = {
    name = "digUtil",
    version = "1.0.0",
    author = "ChefMooon"
}

-- This program contains all functions related to turtle movement with optional digging
--PROGRAM TODO--
-- 

local digUtil = {}

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

return digUtil