-- todo.1m.lua
-- Simple Todo List using text file

local todo_file = crossbar.homeDir() .. "/.crossbar/todo.txt"

local function read_todos()
    local f = io.open(todo_file, "r")
    if not f then return {} end
    local lines = {}
    for line in f:lines() do
        table.insert(lines, line)
    end
    f:close()
    return lines
end

local todos = read_todos()
local count = #todos

local icon = count > 0 and "" or ""

print(icon .. " " .. count)
print("---")

if count > 0 then
    for _, task in ipairs(todos) do
        print(task)
    end
else
    print("No pending tasks")
end

print("---")
print("Edit Todo List | bash='open " .. todo_file .. "' terminal=false")
print("Refresh | refresh=true")
