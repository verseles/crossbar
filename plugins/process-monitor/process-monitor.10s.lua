-- process-monitor.10s.lua
-- Process Monitor (desktop only)

local function env(name, default)
    local value = crossbar.env(name, default)
    if value == nil or value == '' then
        return default
    end
    return value
end

local function env_num(name, default)
    local value = env(name, tostring(default))
    local num = tonumber(value)
    if num == nil then
        return default
    end
    return num
end

local is_mobile = crossbar.isMobile()
local max_items = env_num('PROC_MAX_ITEMS', 5)
if max_items < 1 then max_items = 1 end
if max_items > 50 then max_items = 50 end
if is_mobile then
    print('PROC N/A | color=gray')
    print('---')
    print('Process monitoring is desktop-only')
    print('---')
    print('Refresh | refresh=true')
    return
end

local platform = crossbar.platform()
local cmd = ''
if platform == 'macos' then
    cmd = 'ps aux | sort -nrk 3 | head -6'
else
    cmd = 'ps aux --sort=-%cpu | head -6'
end

local output = crossbar.exec(cmd)
local total_proc_raw = crossbar.exec('ps aux | wc -l')
local total_proc = tonumber((total_proc_raw or ''):match('%d+')) or 0
if total_proc > 0 then total_proc = total_proc - 1 end

print('PROC ' .. tostring(total_proc))
print('---')
print('Running Processes: ' .. tostring(total_proc))
print('---')
print('Top by CPU:')

local shown = 0
for line in (output or ''):gmatch('[^\n]+') do
    if not line:match('^USER') then
        local parts = {}
        for part in line:gmatch('%S+') do
            table.insert(parts, part)
        end

        if #parts >= 11 then
            local cpu = tonumber(parts[3]) or 0
            local proc_cmd = ''
            for i = 11, #parts do
                proc_cmd = proc_cmd .. parts[i] .. ' '
            end
            proc_cmd = proc_cmd:sub(1, 30)

            local color = 'green'
            if cpu > 50 then color = 'red'
            elseif cpu > 20 then color = 'yellow'
            end

            print(string.format('  %.1f%% %s | color=%s', cpu, proc_cmd, color))
            shown = shown + 1
            if shown >= max_items then
                break
            end
        end
    end
end

if shown == 0 then
    print('No process data available')
end

print('---')
print('Refresh | refresh=true')
