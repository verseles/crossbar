-- memory.10s.lua
-- Memory usage monitor using embedded Lua interpreter
-- Output: Usage percentage (without % symbol)

local platform = crossbar.platform()

function get_linux_memory()
    local f = io.open("/proc/meminfo", "r")
    if not f then return nil end
    local content = f:read("*a")
    f:close()
    
    local total = tonumber(content:match("MemTotal:%s+(%d+)"))
    local avail = tonumber(content:match("MemAvailable:%s+(%d+)"))
    
    if total and avail then
        local used = total - avail
        return math.floor((used / total) * 100), math.floor(total/1024), math.floor(used/1024)
    end
    return nil
end

local percent, total_mb, used_mb

if platform == "linux" or platform == "android" then
    percent, total_mb, used_mb = get_linux_memory()
end

if percent then
    -- Color logic
    local color = "green"
    if percent > 80 then color = "red"
    elseif percent > 60 then color = "yellow"
    end
    
    print("🧠 " .. percent .. " | color=" .. color)
    print("---")
    print("Used: " .. used_mb .. " MB")
    print("Total: " .. total_mb .. " MB")
else
    print("🧠 ??")
    print("---")
    print("Platform: " .. platform)
end
