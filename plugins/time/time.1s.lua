-- time.1s.lua
-- Shows the current time with an icon for the time of day.

local function env(name, default)
    local value = crossbar.env(name, default)
    if value == nil or value == '' then
        return default
    end
    return value
end

local function env_bool(name, default)
    local value = env(name, default and 'true' or 'false')
    if value == nil then
        return default
    end
    value = tostring(value):lower()
    return value == 'true' or value == '1' or value == 'yes' or value == 'on'
end

local time_format = env('TIME_FORMAT', 'HH:mm:ss')
local date_format = env('DATE_FORMAT', 'yyyy-MM-dd')
local show_date = env_bool('TIME_SHOW_DATE', true)

local time_hm = crossbar.time('HH:mm')
local current_hour = tonumber(string.sub(time_hm, 1, 2)) or 0
local current_time = crossbar.time(time_format)
local current_date = crossbar.date(date_format)

local icon = ''
local color = 'white'

if current_hour >= 6 and current_hour < 12 then
    icon = '☀️'
    color = 'blue'
elseif current_hour >= 12 and current_hour < 18 then
    icon = '🏙️'
    color = 'green'
elseif current_hour >= 18 and current_hour < 22 then
    icon = '🌆'
    color = 'orange'
else
    icon = '🌙'
    color = 'purple'
end

print(string.format('%s %s | color=%s', icon, current_time, color))
print('---')
print('Time: ' .. current_time)
if show_date then
    print('Date: ' .. current_date)
end
print('---')
print('Refresh | refresh=true')
