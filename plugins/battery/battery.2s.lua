-- battery.2s.lua - Battery monitor with dynamic icons (Lua)
-- Uses Crossbar embedded API (crossbar.battery)

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

local function env_bool(name, default)
    local value = env(name, default and 'true' or 'false')
    if value == nil then
        return default
    end
    value = tostring(value):lower()
    return value == 'true' or value == '1' or value == 'yes' or value == 'on'
end

local low_threshold = env_num('BATTERY_LOW', 20)
local show_percent = env_bool('BATTERY_SHOW_PERCENT', true)
local show_state = env_bool('BATTERY_SHOW_STATE', true)
local color_low = env('BATTERY_COLOR_LOW', '#ff5555')
local color_normal = env('BATTERY_COLOR_NORMAL', '#f8f8f2')
local color_charging = env('BATTERY_COLOR_CHARGING', '#8be9fd')

local battery = crossbar.battery()

if type(battery) ~= 'table' or battery.available == false or battery.level == nil then
    print('🔋 -- | color=gray')
    print('---')
    print('Battery unavailable')
    return
end

local level = tonumber(battery.level) or 0
local charging = battery.charging == true
local state = charging and 'charging' or 'discharging'

local function get_battery_icon(pct, st)
    local l = math.floor(pct / 10) * 10
    if l > 100 then l = 100 end
    if l < 0 then l = 0 end

    local suffix = ''
    if st == 'charging' then
        suffix = '-charging'
    elseif pct == 100 then
        suffix = '-charged'
    end

    if pct == 100 then
        return 'battery-level-100-charged-symbolic'
    elseif pct <= 5 then
        return 'battery-level-0' .. suffix .. '-symbolic'
    else
        return 'battery-level-' .. l .. suffix .. '-symbolic'
    end
end

local icon_name = get_battery_icon(level, state)
local emoji = charging and '⚡' or (level <= low_threshold and '🪫' or '🔋')
local color = charging and color_charging or (level < low_threshold and color_low or color_normal)
local title = show_percent and (tostring(level) .. '%') or 'Battery'

print(emoji .. ' ' .. title .. ' | iconName=' .. icon_name .. ' color=' .. color)
print('---')
if show_state then
    print('State: ' .. state)
end
print('Level: ' .. level .. '%')
if battery.status and battery.status ~= '' then
    print('Status: ' .. battery.status)
end
print('---')
print('Refresh | refresh=true')
