-- uptime.1m.lua
-- System uptime monitor using embedded Lua interpreter
-- Uses Crossbar embedded API

local function env(name, default)
    local value = crossbar.env(name, default)
    if value == nil or value == '' then
        return default
    end
    return value
end

local label = env('UPTIME_LABEL', 'Uptime')
local uptime = crossbar.uptime()

if uptime == nil or uptime == '' then
    print('⬆️ -- | color=gray')
    print('---')
    print('Unable to get uptime')
    return
end

print('⬆️ ' .. uptime)
print('---')
print(label .. ': ' .. uptime)
print('---')
print('Refresh | refresh=true')
