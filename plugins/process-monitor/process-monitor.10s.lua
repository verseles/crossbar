-- process-monitor.10s.lua
-- Process Monitor

local is_mac = crossbar.platform() == 'macos'
local cmd = ""

if is_mac then
    cmd = "ps aux | sort -nrk 3 | head -6 | tail -5"
else
    -- Linux
    cmd = "ps aux --sort=-%cpu | head -6 | tail -5"
end

local output = crossbar.exec(cmd)
local total_proc = crossbar.exec("ps aux | wc -l")
local count = tonumber(total_proc) or 0
if count > 0 then count = count - 1 end -- Remove header

print(" " .. count)
print("---")
print("Running Processes: " .. count)
print("---")
print("Top by CPU:")

if output then
    for line in output:gmatch("[^
]+") do
        -- Extract CPU and Command. 
        -- ps aux format: USER PID %CPU %MEM VSZ RSS TTY STAT START TIME COMMAND
        -- We'll use pattern matching
        local parts = {}
        for part in line:gmatch("%S+") do
            table.insert(parts, part)
        end
        
        if #parts >= 11 then
            local cpu = tonumber(parts[3]) or 0
            local mem = parts[4]
            
            -- Reconstruct command (parts 11 onwards)
            local proc_cmd = ""
            for i=11, #parts do
                proc_cmd = proc_cmd .. parts[i] .. " "
            end
            proc_cmd = proc_cmd:sub(1, 30) -- Truncate
            
            local color = "green"
            if cpu > 50 then color = "red"
            elseif cpu > 20 then color = "yellow"
            end
            
            print(string.format("  %.1f%% %s | color=%s", cpu, proc_cmd, color))
        end
    end
end

print("---")
print("Refresh | refresh=true")
