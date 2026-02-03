-- system-info.1m.lua
-- System Info using Crossbar API

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

local show_platform = env_bool('SYS_SHOW_PLATFORM', true)
local show_home = env_bool('SYS_SHOW_HOME', true)
local show_uptime = env_bool('SYS_SHOW_UPTIME', true)
local show_cpu = env_bool('SYS_SHOW_CPU', true)
local show_memory = env_bool('SYS_SHOW_MEMORY', true)
local show_env = env_bool('SYS_SHOW_ENV', true)

local os_name = crossbar.platform()
local home = crossbar.homeDir()
local cpu = crossbar.cpu()
local mem = crossbar.memory()
local uptime = crossbar.uptime()

print('ℹ️ System Info')
print('---')
if show_platform then
    print('OS: ' .. os_name)
end
if show_home then
    print('Home: ' .. home)
end
if show_uptime then
    print('Uptime: ' .. uptime)
end
if show_cpu then
    print(string.format('CPU: %.1f%%', cpu))
end
if show_memory and type(mem) == 'table' and mem.percent then
    print(string.format('Memory: %d%% (%s/%s %s)', mem.percent, mem.used, mem.total, mem.unit))
end

if show_env then
    print('---')
    print('Environment:')
    print('CROSSBAR_VERSION: ' .. env('CROSSBAR_VERSION', 'unknown'))
    print('CROSSBAR_OS: ' .. env('CROSSBAR_OS', os_name))
    print('CROSSBAR_PLUGIN_ID: ' .. env('CROSSBAR_PLUGIN_ID', 'unknown'))
end

print('---')
print('Refresh | refresh=true')
