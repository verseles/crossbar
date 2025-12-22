-- battery.30s.lua
-- Battery status monitor using embedded Lua interpreter
-- Uses Universal Crossbar API

local bat = crossbar.battery()

if bat and bat.available then
    local icon = "🔋"
    local color = "green"
    
    if bat.charging then 
        icon = "⚡"
        color = "blue"
    elseif bat.level <= 20 then
        icon = "🪫"
        color = "red"
    elseif bat.level <= 50 then
        color = "yellow"
    end
    
    print(icon .. " " .. bat.level .. "% | color=" .. color)
    print("---")
    print("Battery Level: " .. bat.level .. "%")
    print("Status: " .. (bat.charging and "Charging" or "Discharging"))
    print("---")
    print("Refresh | refresh=true")
else
    print("🔋 --")
    print("---")
    print("No battery detected")
end
