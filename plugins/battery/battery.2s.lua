-- battery.2s.lua - Battery monitor with dynamic icons (argos-compatible)
-- Updates every 2 seconds for real-time monitoring
--
-- Features:
-- - Uses Crossbar API (crossbarBridge.batterySync)
-- - Dynamic Freedesktop icons (battery-level-X-symbolic)
-- - Works on ALL platforms (Lua runs embedded)

local bridge = crossbarBridge

-- Get battery data
local battery = bridge.batterySync()

if type(battery) ~= "table" then
    print("🔋 --")
    print("---")
    print("No battery detected")
    return
end

local level = battery.level or 0
local charging = battery.charging or false
local state = charging and "charging" or "discharging"

-- Determine icon based on level and state
local function get_battery_icon(pct, st)
    local l = math.floor(pct / 10) * 10
    if l > 100 then l = 100 end
    if l < 0 then l = 0 end

    local suffix = ""
    if st == "charging" then
        suffix = "-charging"
    elseif pct == 100 and st == "charging" then
        suffix = "-charged"
    end

    if pct == 100 then
        return "battery-level-100-charged-symbolic"
    elseif pct <= 5 then
        return "battery-level-0" .. suffix .. "-symbolic"
    else
        return "battery-level-" .. l .. suffix .. "-symbolic"
    end
end

local icon_name = get_battery_icon(level, state)

-- Determine color
local color
if state == "discharging" then
    if level < 20 then
        color = "#ff5555"
    else
        color = "#f8f8f2"
    end
else
    color = "#8be9fd"
end

-- Emoji icon
local emoji = charging and "⚡" or (level <= 20 and "🪫" or "🔋")

-- Output
print(emoji .. " " .. level .. "% | iconName=" .. icon_name .. " color=" .. color)
print("---")
print("State: " .. state)
print("Level: " .. level .. "%")
print("---")
print("Refresh | refresh=true")
