-- rednetUtil V1.0.0
-- Created by: ChefMooon

--PROGRAM TODO--
-- 

local rednetUtil = {}

function rednetUtil.getProtocol(rednetInfo)
    return rednetInfo.programName..":"..rednetInfo.rednetID
end

function rednetUtil.sendJobUpdate(name, message)
    os.queueEvent(name, message)
end

function rednetUtil.sendJobUpdateRequireYesNoInput(name, message)
    local result, validResult = false
    os.queueEvent(name, _message)
    repeat
        local event, input = os.pullEvent(name.."_result")
        if type(input) == "string" then
            if input == "y" then
                validResult = true
                result = true
            elseif input == "n" then
                validResult = true
                result = false
            else
                result = true -- could this be false? does it matter?
            end
        end
        os.queueEvent(name.."_valid", validResult)
    until validResult == true
    return result
end

return rednetUtil