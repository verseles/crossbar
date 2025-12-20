-- time.1s.lua
-- Shows the current time with an icon for the time of day.

-- 1. Get current time components
-- 1. Get current time components
local current_hour = tonumber(os.date('%H'))
local current_time = os.date('%H:%M:%S')
local current_date = os.date('%Y-%m-%d')

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
