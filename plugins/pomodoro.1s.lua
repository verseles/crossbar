-- pomodoro.1s.lua
-- Pomodoro Timer with work/break cycles using Crossbar storage

-- Configuration
local WORK_MINS = 25
local BREAK_MINS = 5
local WORK_SECS = WORK_MINS * 60
local BREAK_SECS = BREAK_MINS * 60

-- Helper to load state from crossbar storage.
-- Returns a table with: running, startTime, isBreak, completed
local function load_state()
    local default = { running = false, startTime = 0, isBreak = false, completed = 0 }
    local state_json = crossbar.storage('pomodoro_state')
    if state_json == nil or state_json == '' then
        return default
    end

    -- Manual JSON parsing for the state object
    local running = state_json:match('"running"%s*:%s*(true)') ~= nil
    local isBreak = state_json:match('"isBreak"%s*:%s*(true)') ~= nil
    local startTime = tonumber(state_json:match('"startTime"%s*:%s*(%d+)')) or 0
    local completed = tonumber(state_json:match('"completed"%s*:%s*(%d+)')) or 0

    return { running = running, startTime = startTime, isBreak = isBreak, completed = completed }
end

-- Main logic
local state = load_state()
local now = os.time()

if state.running and state.startTime > 0 then
    local elapsed = now - state.startTime
    local duration = state.isBreak and BREAK_SECS or WORK_SECS
    local remaining = duration - elapsed

    if remaining <= 0 then
        -- Timer finished, update state
        local new_completed = state.isBreak and state.completed or state.completed + 1
        crossbar.exec("crossbar storage set pomodoro_state '{\"running\":false, \"completed\":"..new_completed.."}'")

        if state.isBreak then
            print("🎉 Break Over!")
        else
            print("🍅 Work Done!")
        end
    else
        -- Timer is running
        local mins = math.floor(remaining / 60)
        local secs = remaining % 60
        local icon = state.isBreak and "☕️" or "🍅"
        local color = state.isBreak and "green" or "red"
        print(string.format("%s %02d:%02d | color=%s", icon, mins, secs, color))
    end
else
    -- Timer is stopped
    print(string.format("🍅 %d", state.completed))
end

-- Actions
print("---")
print(string.format("Completed: %d", state.completed))
print("---")

if state.running then
    local stop_cmd = "crossbar storage set pomodoro_state '{\"running\":false, \"completed\":"..state.completed.."}'"
    print("Stop | bash='"..stop_cmd.."' terminal=false refresh=true")
else
    local start_work_cmd = string.format("crossbar storage set pomodoro_state '{\"running\":true, \"isBreak\":false, \"startTime\":%d, \"completed\":%d}'", now, state.completed)
    local start_break_cmd = string.format("crossbar storage set pomodoro_state '{\"running\":true, \"isBreak\":true, \"startTime\":%d, \"completed\":%d}'", now, state.completed)
    print("Start Work (25m) | bash='"..start_work_cmd.."' terminal=false refresh=true")
    print("Start Break (5m) | bash='"..start_break_cmd.."' terminal=false refresh=true")
end

local reset_cmd = "crossbar storage set pomodoro_state '{\"running\":false, \"completed\":0}'"
print("Reset Counter | bash='"..reset_cmd.."' terminal=false refresh=true")

print("---")
print("Refresh | refresh=true")
