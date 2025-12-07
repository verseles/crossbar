-- memory.10s.lua
-- Memory usage monitor using embedded Lua interpreter
-- Uses Universal Crossbar API

local mem = crossbar.memory()

if mem and mem.percent then
    local percent = math.floor(mem.percent)
    local color = "green"
    if percent > 80 then color = "red"
    elseif percent > 60 then color = "yellow"
    end
    
    print("🧠 " .. percent .. " | color=" .. color)
    print("---")
    print("Used: " .. mem.used .. " " .. mem.unit)
    print("Total: " .. mem.total .. " " .. mem.unit)
else
    print("🧠 ??")
    print("---")
    print("Memory data unavailable")
end
