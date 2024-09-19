-- digOSUtil
-- Created by: ChefMooon

-- This program contains all functions unique to digOS
--PROGRAM TODO--
-- 

--- Define digOS program args ---
--- selectedProgram
--- length
--- width
--- height
--- offsetDir
--- torch
---    torch
---    distance
---    slot
--- chest
---    chest
---    slot
--- rts
--- ignoreInventory
--- ignoreFuel
--- noPickup
--- blockWhiteList
--- blockBlackList

--- to add:
--- ignoreInventory
--- noPickup
---     plan for this to allow for filters
---     ie. only drop stone (pickup blacklist)



local digOSUtil = {}

-- todo fix this 3 unused inputs
function digOSUtil.createDigArgsString(program, command, length, width, height, offsetDir, torch, torchDistance, torchSlot, chest, chestSlot, rts, ignoreInventory, ignoreFuel, noPickup, blockWhiteList, blockBlackList)
    return table.concat( { 
        "digOS-" .. program .. ".lua",
        tostring(command),
        tostring(length),
        tostring(width),
        tostring(height),
        tostring(offsetDir),
        tostring(torch.torch), tostring(torchDistance), tostring(torchSlot),
        tostring(chest.chest), tostring(chestSlot),
        tostring(rts),
        tostring(ignoreInventory),
        tostring(ignoreFuel),
        tostring(noPickup),
        tostring(blockWhiteList),
        tostring(blockBlackList)
    }, " ")
end

function digOSUtil.createDigArgsTable(program, command, length, width, height, offsetDir, torch, torchDistance, torchSlot, chest, chestSlot, rts, ignoreInventory, ignoreFuel, noPickup, blockWhiteList, blockBlackList)
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

function digOSUtil.digArgsArgsToTable(programName, args)
    local digArgs = digOSUtil.createDigArgsTable(
        programName,
        tostring(args[1]),
        tonumber(args[2]) or 0,
        tonumber(args[3]) or 0,
        tonumber(args[4]) or 0,
        tostring(args[5]) or 0,
        args[6] or false,
        tonumber(args[7]) or 0,
        tonumber(args[8]) or 0,
        args[9] or false,
        tonumber(args[10]) or 0,
        args[11] or false,
        args[12] or false,
        args[13] or false,
        args[14] or false,
        args[15],
        args[16]
    )
    return digArgs
end

function digOSUtil.digArgsRun(digArgs)
    local newDigArgs = digArgs
    newDigArgs.program = "mooonOS/digOS/digPrograms/digOS-" .. digArgs.program .. ".lua"
    newDigArgs.command = "run"
    return newDigArgs
end

function digOSUtil.digArgsTableToString(digArgs)
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

-- Did not have to use but might be useful
function digOSUtil.booleanFromString(string)
    if string == "true" then
        return true
    elseif string == "false" then
        return false
    end
end

function digOSUtil.getDigOSPrograms()
    local programs = fs.find("mooonOS/digOS/digPrograms/digOS-*.lua")
    local programNames = {}
    for i = 1, #programs do
        local name = programs[i]:gsub("^.*/", ""):gsub("digOS%-", ""):gsub(".lua", "")
        table.insert(programNames, name)
    end
    return programNames
end

function digOSUtil.splitString(inputString)
    local words = {}
    for word in inputString:gmatch("%S+") do
        table.insert(words, word)
    end
    return words
end

function digOSUtil.getTurtleIDLabel()
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



--- THEME RELATED FUNCTIONS ---

function digOSUtil.getSavedButtonColor(slot, currentSettings, theme)
    if slot == 1 and currentSettings.saved1 ~= "" then
        return theme.savedDataTrue
    elseif slot == 2 and currentSettings.saved2 ~= "" then
        return theme.savedDataTrue
    elseif slot == 3 and currentSettings.saved3 ~= "" then
        return theme.savedDataTrue
    elseif slot == 4 and currentSettings.saved4 ~= "" then
        return theme.savedDataTrue
    elseif slot == 5 and currentSettings.saved5 ~= "" then
        return theme.savedDataTrue
    end
    return theme.savedDataFalse
end

function digOSUtil.getMenubarRednetStatusButtonColor(rednetInfo, theme)
    if rednetInfo.rednetOpen then
        return theme.rednetOn
    else
        return theme.rednetOff
    end
end

function digOSUtil.getNetworkOffButtonColor(rednetInfo, theme)
    if rednetInfo.rednetOpen then
        return theme.networkFalse
    else
        return theme.networkTrue
    end
end

function digOSUtil.getNetworkOnButtonColor(rednetInfo, theme)
    if rednetInfo.rednetOpen then
        return theme.networkTrue
    else
        return theme.networkFalse
    end
end

--- THEME RELATED FUNCTIONS END ---


return digOSUtil