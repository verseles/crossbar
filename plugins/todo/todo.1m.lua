-- todo.1m.lua
-- Simple Todo List using text file

local function env(name, default)
    local value = crossbar.env(name, default)
    if value == nil or value == '' then
        return default
    end
    return value
end

local function expand_home(path)
    if path:sub(1, 1) == '~' then
        return crossbar.homeDir() .. path:sub(2)
    end
    return path
end

local todo_file = expand_home(env('TODO_FILE', crossbar.homeDir() .. '/.crossbar/todo.txt'))

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

local icon = count > 0 and 'TODO' or 'DONE'

print(icon .. ' ' .. count)
print("---")

if count > 0 then
    for _, task in ipairs(todos) do
        print(task)
    end
else
    print('No pending tasks')
end

print("---")
print("Edit Todo List | bash='crossbar open file \"" .. todo_file .. "\"' terminal=false refresh=true")
print("Refresh | refresh=true")
