-- memory.10s.lua
-- Memory usage monitor using embedded Lua interpreter
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

local warn = env_num('MEM_WARN', 70)
local crit = env_num('MEM_CRIT', 85)
local show_raw = env_bool('MEM_SHOW_RAW', false)
local show_total = env_bool('MEM_SHOW_TOTAL', true)

local mem = crossbar.memory()

if type(mem) ~= 'table' or mem.percent == nil then
    print('🧠 -- | color=gray')
    print('---')
    print('Memory data unavailable')
    return
end

local percent = tonumber(mem.percent) or 0
local color = 'green'
if percent >= crit then
    color = 'red'
elseif percent >= warn then
    color = 'yellow'
end

print('🧠 ' .. percent .. '% | color=' .. color)
print('---')
if show_raw and mem.raw then
    print('Usage: ' .. mem.raw)
else
    if mem.used and mem.unit then
        print('Used: ' .. tostring(mem.used) .. ' ' .. tostring(mem.unit))
    end
    if show_total and mem.total and mem.unit then
        print('Total: ' .. tostring(mem.total) .. ' ' .. tostring(mem.unit))
    end
end
print('---')
print('Refresh | refresh=true')
