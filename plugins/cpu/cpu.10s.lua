-- cpu.10s.lua
-- CPU usage monitor using embedded Lua interpreter
-- Uses Crossbar embedded API

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

local warn = env_num('CPU_WARN', 60)
local crit = env_num('CPU_CRIT', 80)
local show_platform = env_bool('CPU_SHOW_PLATFORM', true)
local show_raw = env_bool('CPU_SHOW_RAW', false)

local cpu = crossbar.cpu()
local platform = crossbar.platform()

-- Android does not expose CPU usage in /proc/stat
if platform == 'android' and cpu == 0 then
    print('💻 N/A | color=gray')
    print('---')
    print('CPU monitoring unavailable on Android')
    print('(SELinux blocks /proc/stat since Android 8+)')
    return
end

local usage = show_raw and string.format('%.1f', cpu) or tostring(math.floor(cpu + 0.5))
local color = 'green'
if cpu >= crit then
    color = 'red'
elseif cpu >= warn then
    color = 'yellow'
end

print('💻 ' .. usage .. '% | color=' .. color)
print('---')
print('Usage: ' .. usage .. '%')
if show_platform then
    print('Platform: ' .. platform)
end
print('---')
print('Refresh | refresh=true')
