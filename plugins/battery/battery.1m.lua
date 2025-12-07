-- battery.1m.lua
-- Battery status monitor using embedded Lua interpreter
-- Linux/Android: Reads /sys/class/power_supply
-- Others: Placeholder

local platform = crossbar.platform()

function get_battery_linux()
    -- Try scanning /sys/class/power_supply/BAT*
    -- Simplified: try BAT0 and BAT1
    local bat_paths = {"/sys/class/power_supply/BAT0", "/sys/class/power_supply/BAT1", "/sys/class/power_supply/bat0"}
    
    for _, path in ipairs(bat_paths) do
        local f = io.open(path .. "/capacity", "r")
        if f then
            local capacity = f:read()
            f:close()
            
            local f_status = io.open(path .. "/status", "r")
            local status = "Discharging"
            if f_status then 
                status = f_status:read()
                f_status:close() 
            end
            
            -- Remove newlines
            if capacity then capacity = capacity:gsub("\n", "") end
            if status then status = status:gsub("\n", "") end
            
            return capacity, status
        end
    end
    return nil, nil
end

local capacity, status

if platform == "linux" or platform == "android" then
    capacity, status = get_battery_linux()
end

if capacity then
    local icon = "🔋"
    if status == "Charging" then icon = "⚡" end
    if tonumber(capacity) <= 20 and status ~= "Charging" then icon = "🪫" end
    
    print(icon .. " " .. capacity .. "%")
    print("---")
    print("Status: " .. status)
else
    print("🔋 --")
    print("---")
    print("No battery detected")
end
