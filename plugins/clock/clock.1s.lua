-- clock.1s.lua
-- Simple clock plugin using embedded Lua interpreter

local function env(name, default)
    local value = crossbar.env(name, default)
    if value == nil or value == '' then
        return default
    end
    return value
end

local format = env('CLOCK_FORMAT', 'HH:mm:ss')
local time = crossbar.time(format)
print('🕐 ' .. time)
