-- cpu.10s.lua
-- CPU usage monitor using embedded Lua interpreter
-- Uses Universal Crossbar API

local cpu = crossbar.cpu()
local platform = crossbar.platform()

if cpu then
    local usage = math.floor(cpu + 0.5)

    -- Check if Android (CPU monitoring unavailable due to SELinux)
    if platform == "android" and usage == 0 then
        print("💻 N/A")
        print("---")
        print("CPU monitoring unavailable on Android")
        print("(SELinux blocks /proc/stat since Android 8+)")
    else
        local color = "green"
        if usage > 80 then color = "red"
        elseif usage > 60 then color = "yellow"
        end

        print("💻 " .. usage .. "% | color=" .. color)
        print("---")
        print("CPU Usage: " .. cpu .. "%")
        print("Platform: " .. platform)
    end
else
    print("💻 ??")
end
