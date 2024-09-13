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

----- REQUIRE START -----

--- Make me a loop, waiting on upload to get downloadPath
local requiredPrograms = {
    basalt = {
        filename = "basalt.lua",
        downloadPath = "wget run https://basalt.madefor.cc/install.lua release basalt-1.7.1.lua "
    },
    todoOSView = {
        filename = "todoOSView.lua",
        downloadPath = ""
    },
    todoOSFile = {
        filename = "todoOSFile.lua",
        downloadPath = ""
    }
}

local basaltPath = "basalt.lua"
if not (fs.exists(basaltPath)) then
    print("Basalt Not Found. Installing ...")
    shell.run("wget run https://basalt.madefor.cc/install.lua release basalt-1.7.1.lua " .. basaltPath)
end
local basalt = require(basaltPath:gsub(".lua", ""))

local programPath = "mooonOS/todoOS/"

local todoOSViewPath = programPath .. "todoOSView.lua"
local view = require(todoOSViewPath:gsub(".lua", ""))

local todoOSFilePath = programPath .. "todoOSUtil.lua"
local file = require(todoOSFilePath:gsub(".lua", ""))

----- REQUIRE END -----


----- VARIABLES START -----

local rednetOpen = false

local savedDataFilename = programPath .. "todoOSData.txt"


----- VARIABLES END -----
---





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

view.initMenubarInfoFrame(main, theme)
view.initTodoFrame(sub[1], theme)
view.initInputFrame(sub[1], theme)


local buttonAdd, buttonDelete, buttonMoveUp, buttonMoveDown = view.getInputButtons()
local todoList = view.getTodoList()


local savedData = file.init(savedDataFilename)
view.setTodoList(savedData)


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

----- MENUBAR END -----

----- FUNCTION START -----




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
