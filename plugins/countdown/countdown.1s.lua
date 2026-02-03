-- countdown.1s.lua
-- Countdown Timer in Lua

local function env(name, default)
    local value = crossbar.env(name, default)
    if value == nil or value == '' then
        return default
    end
    return value
end

local target_str = env('COUNTDOWN_TARGET', '')
if target_str == '' then
    target_str = env('CROSSBAR_COUNTDOWN_TARGET', '2025-12-31 23:59:59')
end
local label = env('COUNTDOWN_LABEL', 'Countdown')
local done_text = env('COUNTDOWN_DONE_TEXT', 'Countdown complete!')

-- 2. Parse the date string "YYYY-MM-DD HH:MM:SS"
local year, month, day, hour, min, sec = target_str:match("(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)")

if not year then
    print('! | color=red')
    print('---')
    print('Error: Invalid date format')
    print('Set COUNTDOWN_TARGET')
    print('Format: YYYY-MM-DD HH:MM:SS')
    return
end

-- 3. Convert target date to a Unix timestamp
local target_time = os.time({
    year = tonumber(year), month = tonumber(month), day = tonumber(day),
    hour = tonumber(hour), min = tonumber(min), sec = tonumber(sec)
})

-- 4. Get current time and calculate the difference
local now = os.time()
local diff_seconds = target_time - now

-- 5. Format the output based on the difference
if diff_seconds <= 0 then
    print('Done!')
    print('---')
    print(done_text)
else
    local days = math.floor(diff_seconds / 86400)
    local remainder = diff_seconds % 86400
    local hours = math.floor(remainder / 3600)
    remainder = remainder % 3600
    local minutes = math.floor(remainder / 60)
    local seconds = remainder % 60

    local display = ""
    if days > 0 then
        display = string.format("%dd %dh", days, hours)
    elseif hours > 0 then
        display = string.format("%dh %dm", hours, minutes)
    else
        display = string.format("%dm %ds", minutes, seconds)
    end

    print('⏳ ' .. display)
    print('---')
    print(label .. ': ' .. target_str)
end

print('---')
print('Refresh | refresh=true')
