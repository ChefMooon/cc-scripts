local programInfo = {
    name = "winchOSUtil",
    version = "1.0.0",
    author = "ChefMooon"
}

-- This program conatins all the utility functions for winchOScmd

local rednetUtil = require("mooonOS/common/rednetUtil")

local winchOSUtil = {}

function winchOSUtil.getFloorWithSuffix(floorNum)
    local suffix
    if floorNum ~= nil then
        if floorNum == 0 then
            suffix = ""
        -- Special case for numbers ending in 11, 12, or 13 (use "th" suffix)
        elseif floorNum % 100 >= 11 and floorNum % 100 <= 13 then
            suffix = "th"
        else
            -- For other numbers, determine the appropriate suffix based on the last digit
            local lastDigit = floorNum % 10
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
        return floorNum .. suffix
    else
        return ""
    end
end

function winchOSUtil.elevatorCheck(redstoneContactSide) -- TODO: not used, remove/refactor?
    return redstone.getInput(redstoneContactSide)
end

function winchOSUtil.isValidFloorName(floorName)
    local string = tostring(floorName)
    return string and string ~= "" and #string <= 256
end

function winchOSUtil.isValidFloor(floor)
    -- TOOD: nil check?
    local number = tonumber(floor)
    local isFloor = number >= 0 and number <= 256
    local isRemote = number >= 900 and number <= 999
    local terminalType = "nil"
    if isFloor then
        terminalType = "floor"
    elseif isRemote then
        terminalType = "remote"
    end
    local result = {
        valid = isFloor or isRemote,
        terminalType = terminalType
    }
    return result
end

function winchOSUtil.isValidTerminalSecurity(terminalSecurity)
    local validSecurityTypes = { "W", "M", "S" }
    for _, validType in ipairs(validSecurityTypes) do
        if terminalSecurity:upper() == validType then
            return true
        end
    end
    return false
end

return winchOSUtil