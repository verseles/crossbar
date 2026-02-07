-- pomodoro.1s.lua
-- Pomodoro Timer (file-based state)

local function env(name, default)
    local value = crossbar.env(name, default)
    if value == nil or value == '' then
        return default
    end
    return value
end

local function env_num(name, default)
    local value = env(name, tostring(default))
    local num = tonumber(value)
    if num == nil then
        return default
    end
    return num
end

local function expand_home(path)
    if path:sub(1, 1) == '~' then
        return crossbar.homeDir() .. path:sub(2)
    end
    return path
end

local function shell_escape(value)
    local escaped = tostring(value)
    escaped = escaped:gsub('\\', '\\\\')
    escaped = escaped:gsub(' ', '\\ ')
    escaped = escaped:gsub('"', '\\"')
    escaped = escaped:gsub("'", "\\'")
    return escaped
end

local work_mins = env_num('POMODORO_WORK_MINS', 25)
local break_mins = env_num('POMODORO_BREAK_MINS', 5)
if work_mins < 1 then work_mins = 1 end
if work_mins > 180 then work_mins = 180 end
if break_mins < 1 then break_mins = 1 end
if break_mins > 60 then break_mins = 60 end
local state_file = expand_home(env('POMODORO_STATE_FILE', crossbar.homeDir() .. '/.crossbar/pomodoro.state'))

local function read_state()
    local state = {
        running = false,
        start_time = 0,
        is_break = false,
        completed = 0,
    }
    local f = io.open(state_file, 'r')
    if not f then return state end
    for line in f:lines() do
        local key, value = line:match('^(%w+)=(.+)$')
        if key == 'RUNNING' then
            state.running = value == 'true'
        elseif key == 'START_TIME' then
            state.start_time = tonumber(value) or 0
        elseif key == 'IS_BREAK' then
            state.is_break = value == 'true'
        elseif key == 'COMPLETED' then
            state.completed = tonumber(value) or 0
        end
    end
    f:close()
    return state
end

local function write_state(state)
    local f = io.open(state_file, 'w')
    if not f then return end
    f:write('RUNNING=' .. (state.running and 'true' or 'false') .. '\n')
    f:write('START_TIME=' .. tostring(state.start_time) .. '\n')
    f:write('IS_BREAK=' .. (state.is_break and 'true' or 'false') .. '\n')
    f:write('COMPLETED=' .. tostring(state.completed) .. '\n')
    f:close()
end

local function build_write_cmd(running, is_break, start_time, completed)
    local running_str = running and 'true' or 'false'
    local break_str = is_break and 'true' or 'false'
    local escaped_path = shell_escape(state_file)
    local cmd = "sh -c 'printf RUNNING=" .. running_str
        .. "\\nSTART_TIME=" .. start_time
        .. "\\nIS_BREAK=" .. break_str
        .. "\\nCOMPLETED=" .. completed
        .. "\\n > " .. escaped_path .. "'"
    return cmd
end

local state = read_state()
local now = os.time()
local work_secs = work_mins * 60
local break_secs = break_mins * 60

if state.running and state.start_time > 0 then
    local elapsed = now - state.start_time
    local duration = state.is_break and break_secs or work_secs
    local remaining = duration - elapsed

    if remaining <= 0 then
        if not state.is_break then
            state.completed = state.completed + 1
        end
        state.running = false
        write_state(state)

        if state.is_break then
            print('🎉 Break Over!')
        else
            print('🍅 Work Done!')
        end
    else
        local mins = math.floor(remaining / 60)
        local secs = remaining % 60
        local icon = state.is_break and '☕' or '🍅'
        local color = state.is_break and 'green' or 'red'
        print(string.format('%s %02d:%02d | color=%s', icon, mins, secs, color))
    end
else
    print('🍅 ' .. tostring(state.completed))
end

print('---')
print('Completed: ' .. tostring(state.completed))
print('Work: ' .. tostring(work_mins) .. 'm')
print('Break: ' .. tostring(break_mins) .. 'm')
print('---')

if state.running then
    local stop_cmd = build_write_cmd(false, false, 0, state.completed)
    print('Stop | bash="' .. stop_cmd .. '" terminal=false refresh=true')
else
    local start_work_cmd = build_write_cmd(true, false, now, state.completed)
    local start_break_cmd = build_write_cmd(true, true, now, state.completed)
    print('Start Work (' .. tostring(work_mins) .. 'm) | bash="' .. start_work_cmd .. '" terminal=false refresh=true')
    print('Start Break (' .. tostring(break_mins) .. 'm) | bash="' .. start_break_cmd .. '" terminal=false refresh=true')
end

local reset_cmd = build_write_cmd(false, false, 0, 0)
print('Reset Counter | bash="' .. reset_cmd .. '" terminal=false refresh=true')

print('---')
print('Refresh | refresh=true')
