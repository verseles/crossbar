-- time.1s.lua
-- Shows the current time with an icon for the time of day.

-- 1. Get current time components
-- Using crossbar API instead of os.date for better compatibility
local time_hm = crossbar.time('HH:mm') -- "14:30"
local current_hour = tonumber(string.sub(time_hm, 1, 2))
local current_time = crossbar.time('HH:mm:ss')
local current_date = crossbar.date('yyyy-MM-dd')

-- 2. Determine icon and color based on the hour
local icon = ""
local color = "white"

if current_hour >= 6 and current_hour < 12 then
    icon = "☀️" -- Morning
    color = "lightblue"
elseif current_hour >= 12 and current_hour < 18 then
    icon = "🏙️" -- Afternoon
    color = "lightgreen"
elseif current_hour >= 18 and current_hour < 22 then
    icon = "🌆" -- Evening
    color = "orange"
else
    icon = "🌙" -- Night
    color = "purple"
end

-- 3. Print the formatted output
print(string.format("%s %s | color=%s", icon, current_time, color))
print("---")
print("Time: " .. current_time)
print("Date: " .. current_date)
print("---")
print("Refresh | refresh=true")
