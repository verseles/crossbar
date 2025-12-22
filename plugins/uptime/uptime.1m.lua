-- uptime.1m.lua
-- System uptime monitor using embedded Lua interpreter
-- Uses Universal Crossbar API

local uptime = crossbar.uptime()

if uptime then
    print("⬆️ " .. uptime)
    print("---")
    print("System Uptime: " .. uptime)
    print("Refresh | refresh=true")
else
    print("⬆️ --")
    print("---")
    print("Unable to get uptime")
end