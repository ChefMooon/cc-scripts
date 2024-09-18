-- todoOS V1.0.0
-- Created by: ChefMooon

----- PROGRAM TODO -----
--- Add style options for todo's ie ability to change color of text (3 options?)
---     figure out how to update the record properly?

--- Ideas
--- Keyboard Input
---     Enter to create
---     Delete to delete
---     Arrow keys up/down change selected

-- this will help filter broadcast messages
local programName = "todoOS"
local programVersion = "1.0.0"
local programDescription = "This is a simple Todo list."

local programInfo = {
    programName = "todoOS",
    programVersion = "1.0.0",
    programDescription, "This is a simple Todo list."
}

----- REQUIRE START -----

local lib = {
    mooonUtil = {
        path = "mooonOS/common/mooonUtil.lua",
        url = "https://raw.githubusercontent.com/ChefMooon/cc-scripts/mooonOS/mooonOS/mooonOS/common/mooonUtil.lua"
    },
    basalt = {
        path = "basalt.lua",
        url = "wget run https://basalt.madefor.cc/install.lua release basalt-1.7.1.lua "
    }
}

local subPrograms = {
    todoOSView = {
        path = "mooonOS/todoOS/todoOSView.lua",
        url = "https://raw.githubusercontent.com/ChefMooon/cc-scripts/mooonOS/mooonOS/mooonOS/todoOS/todoOSView.lua"
    },
    todoOSViewInfo = {
        path = "mooonOS/todoOS/todoOSViewInfo.lua",
        url = "https://raw.githubusercontent.com/ChefMooon/cc-scripts/mooonOS/mooonOS/mooonOS/todoOS/todoOSViewInfo.lua"
    },
    todoOSUtil = {
        path = "mooonOS/todoOS/todoOSUtil.lua",
        url = "https://raw.githubusercontent.com/ChefMooon/cc-scripts/mooonOS/mooonOS/mooonOS/todoOS/todoOSUtil.lua"
    }
}

if not (fs.exists(lib.mooonUtil.path)) then
    shell.run("wget " .. lib.mooonUtil.url .. " " .. lib.mooonUtil.path)
end
local mooonUtil = require(lib.mooonUtil.path:gsub(".lua", ""))
local basalt = mooonUtil.getBasalt(lib.basalt.path)

for _, program in pairs(subPrograms) do
    if not (fs.exists(program.path)) then
        print(program.path:gsub(".lua", "") .. " Not Found. Installing ...")
        mooonUtil.downloadFile(program.url, program.path)
    else
        print(program.path:gsub(".lua", "") .. " Found!")
    end
end

local view = mooonUtil.getProgram(subPrograms.todoOSView.path)
local viewInfo = mooonUtil.getProgram(subPrograms.todoOSViewInfo.path)
local file = mooonUtil.getProgram(subPrograms.todoOSUtil.path)

----- REQUIRE END -----

----- VARIABLES START -----

local rednetOpen = false

local savedDataPath = "mooonOS/todoOS/todoOSData.txt"

----- VARIABLES END -----

local theme = {
    background = colors.gray,
    foreground = colors.yellow,
    rednetOn = colors.red,
    rednetOff = colors.black
}

----- MENUBAR START -----

local w, h = term.getSize()
local main = basalt.createFrame():setTheme({ FrameBG = colors.lightGray, FrameFG = colors.black })

local sub = {
    main:addFrame():setPosition(1, 2):setSize("{parent.w}", "{parent.h - 1}"),
    main:addFrame():setPosition(1, 2):setSize("{parent.w}", "{parent.h - 1}"):hide(),
    main:addFrame():setPosition(1, 2):setSize("{parent.w}", "{parent.h - 1}"):hide(),
}

local function openSubFrame(id)
    if (sub[id] ~= nil) then
        for k, v in pairs(sub) do
            v:hide()
        end
        sub[id]:show()
    end
end

local menubar = main:addMenubar():setScrollable()
    :setSize("{parent.w-8}", 1)
    :onSelect(function(self, event, item)
        openSubFrame(self:getItemIndex())
    end)
    :addItem("Home")
    :addItem("Settings")
    :addItem("Info")


----- MENUBAR END -----

view.initMenubarInfoFrame(main, theme)
view.initTodoFrame(sub[1], theme)
view.initInputFrame(sub[1], theme)

local buttonAdd, buttonDelete, buttonMoveUp, buttonMoveDown = view.getInputButtons()
local todoList = view.getTodoList()

viewInfo.init(sub[3], programInfo, theme)

local savedData = file.init(savedDataPath)
view.setTodoList(savedData)

----- FUNCTION START -----

local function createTodo(todo)
    if todo ~= "" then
        view.createTodo(todo, theme)
        savedData = file.createTodo(savedData, todo)
        view.getInputText():setValue("")
        view.setSelectedTodo(#savedData)
        file.quicksave(savedData)
    end
end

local function deleteTodo(index)
    view.deleteTodo(index)
    savedData = file.deleteTodo(savedData, index)
    view.setSelectedTodo(index-1)
    file.quicksave(savedData)
end

local function moveTodo(index, newIndex)
    savedData = file.moveTodo(savedData, index, newIndex)
    view.setTodoList(savedData, theme)
    view.setSelectedTodo(newIndex)
    file.quicksave(savedData)
end

----- FUNCTION END -----

local function getMenubarRednetStatusButtonColor()
    if rednetOpen then
        return theme.rednetOn
    else
        return theme.rednetOff
    end
end

local function toggleRednet()
    if rednetOpen then
        -- stopRednet()
        rednetOpen = false
    else
        -- startRednet()
        rednetOpen = true
    end
    view.setRednetStatusButton(getMenubarRednetStatusButtonColor())
end

view.menubarRednetStatusButton():onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        toggleRednet()
    end
end)

buttonAdd:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        createTodo(view.getInputText():getValue())
    end
end)

buttonDelete:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        deleteTodo(view.getTodoList():getItemIndex())
    end
end)

buttonMoveUp:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        moveTodo(view.getTodoList():getItemIndex(), view.getTodoList():getItemIndex()-1)
    end
end)

buttonMoveDown:onClick(function(self, event, button, x, y)
    if (event == "mouse_click") and (button == 1) then
        moveTodo(view.getTodoList():getItemIndex(), view.getTodoList():getItemIndex()+1)
    end
end)

basalt.autoUpdate()