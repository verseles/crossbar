-- cpu.10s.lua
-- CPU usage monitor using embedded Lua interpreter
-- Linux/Android: Reads /proc/stat
-- Others: Placeholder

local platform = crossbar.platform()
local tmp_path = "/tmp/crossbar_cpu_" .. (os.getenv("USER") or "user") .. ".stat"

function get_cpu_linux()
    local f = io.open("/proc/stat", "r")
    if not f then return nil end
    local line = f:read() -- first line "cpu  user nice system idle ..."
    f:close()
    
    local user, nice, system, idle = line:match("cpu%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)")
    if not (user and nice and system and idle) then return nil end
    
    local total = user + nice + system + idle
    local work = user + nice + system
    
    local prev_total, prev_work = 0, 0
    
    -- Read previous state
    local fp = io.open(tmp_path, "r")
    if fp then
        local content = fp:read()
        if content then
             local p_w, p_t = content:match("(%d+)%s+(%d+)")
             if p_w and p_t then
                 prev_work = tonumber(p_w)
                 prev_total = tonumber(p_t)
             end
        end
        fp:close()
    end
    
    -- Save current state
    local fw = io.open(tmp_path, "w")
    if fw then
        fw:write(work .. " " .. total)
        fw:close()
    end
    
    if prev_total == 0 then return "..." end
    
    local delta_total = total - prev_total
    local delta_work = work - prev_work
    
    if delta_total == 0 then return "0.0" end
    
    return string.format("%.1f", (delta_work / delta_total) * 100)
end

local cpu

if platform == "linux" or platform == "android" then
    cpu = get_cpu_linux()
end

if cpu then
    print("💻 " .. cpu .. "%")
    print("---")
    print("CPU Usage: " .. cpu .. "%")
else
    print("💻 CPU")
    print("---")
    print("Platform: " .. platform)
end
