-- cpu.10s.lua
-- CPU usage monitor using embedded Lua interpreter
-- Uses Universal Crossbar API

local cpu = crossbar.cpu()

if cpu then
    local usage = math.floor(cpu + 0.5)
    
    local color = "green"
    if usage > 80 then color = "red"
    elseif usage > 60 then color = "yellow"
    end
    
    print("💻 " .. usage .. "% | color=" .. color)
    print("---")
    print("CPU Usage: " .. cpu .. "%")
    print("Platform: " .. crossbar.platform())
else
    print("💻 ??")
end
