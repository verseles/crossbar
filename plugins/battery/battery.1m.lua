-- battery.1m.lua
-- Battery status monitor using embedded Lua interpreter
-- Uses Universal Crossbar API

local bat = crossbar.battery()

if bat and bat.available then
    local icon = "🔋"
    if bat.charging then icon = "⚡" end
    if bat.level <= 20 and not bat.charging then icon = "🪫" end
    
    print(icon .. " " .. bat.level .. "%")
    print("---")
    print("Status: " .. bat.status)
else
    print("🔋 --")
    print("---")
    print("No battery detected")
end
