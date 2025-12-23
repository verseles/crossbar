-- system-info.1m.lua
-- System Info using Crossbar API

local os_name = crossbar.platform()
local home = crossbar.homeDir()
local cpu = crossbar.cpu()
local mem = crossbar.memory()
local uptime = crossbar.uptime()

print("ℹ️ System Info")
print("---")
print("OS: " .. os_name)
print("Home: " .. home)
print("Uptime: " .. uptime)
print(string.format("CPU: %.1f%%", cpu))

if mem and mem.percent then
    print(string.format("Memory: %d%% (%s/%s %s)", mem.percent, mem.used, mem.total, mem.unit))
end

print("---")
print("Environment:")
-- LuaDardo doesn't expose full env iteration yet via bridge, only single lookup
-- But bridge has envAll property
-- We can't iterate envAll easily in Lua without bridge change, skipping for now.

print("Refresh | refresh=true")
