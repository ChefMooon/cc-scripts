local programInfo = {
    name = "todoOSView",
    version = "1.0.0",
    author = "ChefMooon"
}

----- PROGRAM TODO -----
--- Implement the _theme more in each function

-- ideas
--- add each ui element to a list, create a function to update the theme of all ui elements at onece
--- for each element in the list set stuff i.e. setBackground, setForeground
--- 
--- Add term dimensions on init
---     make it possible to use on any sized screen?

----- VARIABLES START -----
--- Declaring variables outisde of the function allows the elements to be changed



----- VARIABLES END -----

local view = {}

----- ***** -----

local menubarInfoFrame, menubarRednetStatusButton, programLabel
function view.initMenubarInfoFrame(frame, theme)
    menubarInfoFrame = frame:addFrame():setPosition("{parent.w-7}", 1):setSize(7,1):setBackground(theme.background)
    menubarRednetStatusButton = menubarInfoFrame:addButton():setText(""):setPosition(1, 1):setSize(1,1):setBackground(theme.rednetOff) -- getMenubarRednetStatusButtonColor()
    programLabel = menubarInfoFrame:addLabel():setText("todoOS"):setPosition(2, 1):setForeground(theme.foreground)
end

function view.menubarRednetStatusButton()
    return menubarRednetStatusButton
end

function view.setRednetStatusButton(background)
    menubarRednetStatusButton:setBackground(background)
end

----- ***** -----

local todoFrame, todoLabel, todoList
function view.initTodoFrame(frame, theme)
    todoFrame = frame:addFrame():setPosition(1, 2):setSize("{parent.w-2}", "{parent.h-5}")
    todoFrame:addLabel():setText("TODO:"):setPosition(1, 1)
    todoList = todoFrame:addList():setPosition(1, 2):setSize("{parent.w}", "{parent.h-1}")
end

function view.getTodoList()
    return todoList
end

function view.setSelectedTodo(index)
    if index > 0 and index <= todoList:getItemCount() then
        todoList:selectItem(index)
    end
end

function view.setTodoList(list, theme)
    -- maybe change this to iterate through the list and add each individually
    -- also handle the theme (aList:setOptions("Entry 1", {"Entry 2", colors.yellow},))
    local todos = {}
    for _, todo in ipairs(list) do
        table.insert(todos, todo.todo)
    end
    todoList:setOptions(todos)
end

function view.clearTodoList()
    todoList:clear()
end

function view.createTodo(todo, theme)
    if #theme == 0 then
        todoList:addItem(todo)
    else
        -- impelement add item with theme, need to specify todoListItem in theme array
    end
end

function view.readTodo(index)
    return todoList:getItem(index)
end

function view.updateTodo(index, todo, theme)
    if #theme == 0 then
        todoList:editItem(index, todo)
    else
        -- impelement add item with theme, need to specify todoListItem in theme array
    end
end

function view.deleteTodo(index)
    todoList:removeItem(index)
end

--- functions left
--- modify entry
--- move entry up/down

----- ***** -----

local inputFrame, inputText, buttonFrame, buttonAdd, buttonDelete, buttonMoveUp, buttonMoveDown
function view.initInputFrame(frame, theme)
    inputFrame = frame:addFrame():setPosition(1,"{parent.h-3}"):setSize("{parent.w}", 2)
    inputText = inputFrame:addInput():setInputType("text"):setPosition(2,1):setSize("{parent.w-5}", 1)
    buttonFrame = inputFrame:addFlexbox():setPosition(2,2):setSize("{parent.w-6}", 1)
    buttonAdd = buttonFrame:addButton():setText("\43"):setSize(5, 1)
    buttonDelete = buttonFrame:addButton():setText("\45"):setSize(5, 1)
    buttonMoveUp = buttonFrame:addButton():setText("\30"):setSize(5, 1)
    buttonMoveDown = buttonFrame:addButton():setText("\31"):setSize(5, 1)
end

function view.getInputText()
    return inputText
end

function view.getInputButtons()
    return buttonAdd, buttonDelete, buttonMoveUp, buttonMoveDown
end

----- ***** -----


return view

