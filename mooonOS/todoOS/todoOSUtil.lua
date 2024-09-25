rogramInfo = {
    name = "todoOSUtil",
    version = "1.0.0",
    author = "ChefMooon"
}

--- The file contains the folowing logic:
----- File Save/Load
----- SavedDate Utility

--- SavedData Table Structure
--- todo | dateCreated

----- PROGRAM TODO -----
--- error codes currently print to screen, how can those be better displayed?

local savedDataPath = ""
local fileUtil = {}

--- div ---

local function getTimestamp()
    return os.date("%Y-%m-%d %H:%M:%S")
end

--- div ---

function fileUtil.loadFileToTable(path)
    local data = {}
    local file = io.open(path, "r")

    if file then
        local index = 1
        for line in file:lines() do
            local todo, timestamp = line:match("^(.-) | (.+)$")
            if todo and timestamp then
                timestamp = timestamp or getTimestamp()
                data[index] = { todo = todo, dateCreated = timestamp }
            end
            index = index + 1
        end
        file:close()
    else
        print("Could not open file " .. path)
    end

    return data
end

function fileUtil.saveTableToFile(path, data)
    local file = io.open(path, "w")

    if file then
        for _, entry in ipairs(data) do
            file:write(entry.todo .. " | " .. entry.dateCreated .. "\n")
        end
        file:close()
    else
        print("Could not write to file " .. path)
    end
end

function fileUtil.quicksave(data)
    fileUtil.saveTableToFile(savedDataPath, data)
end

--- div ---

function fileUtil.createTodo(data, newTodo)
    table.insert(data, {
        todo = newTodo,
        dateCreated = getTimestamp()
    })
    return data
end

function fileUtil.readTodo(data, lineNumber)
    if data[lineNumber] then
        return data[lineNumber]
    end
end

function fileUtil.updateTodo(data, lineNumber, newTodo)
    if data[lineNumber] then
        data[lineNumber].todo = newTodo.todo
        data[lineNumber].dateCreated = newTodo.dateCreated
    else
        print("Line " .. lineNumber .. " does not exist.")
    end
    return data
end

function fileUtil.deleteTodo(data, lineNumber)
    if data[lineNumber] then
        table.remove(data, lineNumber)
    else
        print("Line " .. lineNumber .. " does not exist.")
    end
    return data
end

function fileUtil.moveTodo(data, index, newIndex)
    -- Check if the index is within the bounds of the data
    -- todo add better ways to return errors and information
    if newIndex < 1 then
        newIndex = 1
    elseif newIndex > #data then
        newIndex = #data
    end
    if data[newIndex] and data[index] then
        local swap = data[index]
        data[index] = data[newIndex]
        data[newIndex] = swap
    else
        if not data[index] then
            print("Index " .. index .. " does not exist.")
        end
        if not data[newIndex] then
            print("New index " .. newIndex .. " does not exist.")
        end
    end
    return data
end

function fileUtil.init(path)
    savedDataPath = path
    return fileUtil.loadFileToTable(savedDataPath)
end

--- div ---

return fileUtil