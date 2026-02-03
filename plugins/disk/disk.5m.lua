-- disk.5m.lua
-- Disk Usage Monitor (desktop via CLI)

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

local is_mobile = crossbar.isMobile()
if is_mobile then
    print('DISK N/A | color=gray')
    print('---')
    print('Disk info via CLI is limited on mobile')
    print('---')
    print('Refresh | refresh=true')
    return
end

local platform = crossbar.platform()
local default_path = platform == 'windows' and 'C:\\' or '/'
local path = env('DISK_PATH', default_path)
local warn = env_num('DISK_WARN', 75)
local crit = env_num('DISK_CRIT', 90)

local result = crossbar.exec('crossbar disk ' .. path)

if result == nil or result == '' then
    print('DISK -- | color=gray')
    print('---')
    print('Error: Could not get disk info')
    return
end

local numbers = {}
for num in result:gmatch('([%d%.]+)') do
    table.insert(numbers, tonumber(num))
end

if #numbers < 2 then
    print('DISK -- | color=gray')
    print('---')
    print('Error: Unexpected disk info format')
    print('Received: ' .. result)
    return
end

local used_size = numbers[1]
local total_size = numbers[2]
local usage_percent = total_size > 0 and math.floor((used_size / total_size) * 100) or 0

local color = 'green'
if usage_percent >= crit then
    color = 'red'
elseif usage_percent >= warn then
    color = 'orange'
end

print(string.format('DISK %d%% | color=%s', usage_percent, color))
print('---')
print(string.format('Path: %s', path))
print(string.format('Used: %.1fG / %.1fG', used_size, total_size))
print('---')
print('Refresh | refresh=true')
