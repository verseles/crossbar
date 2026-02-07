-- submenu_demo.30s.lua
-- Demonstrates nested menus using BitBar format
-- Uses Crossbar embedded API for cross-platform compatibility

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

local cpu = crossbar.cpu()
local mem = crossbar.memory()
local platform = crossbar.platform()
local home = crossbar.homeDir()
local uptime = crossbar.uptime()
local show_env = env_bool('SUBMENU_SHOW_ENV', true)
local menu_title = env('SUBMENU_TITLE', 'System')

print('📊 ' .. menu_title .. ' | color=blue')
print('---')

-- Hardware submenu
print('Hardware')
print('--CPU')
print('----Usage: ' .. string.format('%.1f', cpu) .. '%')
print('----Platform: ' .. platform)
print('--Memory')
if type(mem) == 'table' and mem.percent then
    print('----Total: ' .. mem.total .. ' ' .. mem.unit)
    print('----Used: ' .. mem.used .. ' ' .. mem.unit)
    local free = string.format('%.1f', tonumber(mem.total) - tonumber(mem.used))
    print('----Free: ' .. free .. ' ' .. mem.unit)
else
    print('----Info unavailable')
end
print('--Uptime')
print('----' .. uptime)

print('---')

-- Quick Actions submenu
print('Quick Actions')
if platform == 'linux' then
    print('--Open Terminal | bash=gnome-terminal')
    print('--Open File Manager | bash=nautilus')
elseif platform == 'macos' then
    print('--Open Terminal | bash=open param1=-a param2=Terminal')
    print('--Open Finder | bash=open param1=' .. home)
elseif platform == 'windows' then
    print('--Open Terminal | bash=cmd')
    print('--Open Explorer | bash=explorer')
end

print('---')

-- Info submenu
print('Info')
print('--Home: ' .. home)
print('--OS: ' .. platform)
if show_env then
    print('--CROSSBAR_OS: ' .. env('CROSSBAR_OS', platform))
    print('--CROSSBAR_VERSION: ' .. env('CROSSBAR_VERSION', 'unknown'))
end

print('---')
print('Refresh | refresh=true')
