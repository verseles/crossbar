-- ssh-connections.30s.lua
-- Shows active SSH connections (desktop only)

local function env(name, default)
    local value = crossbar.env(name, default)
    if value == nil or value == '' then
        return default
    end
    return value
end

local function env_bool(name, default)
    local value = env(name, default and 'true' or 'false')
    if value == nil then
        return default
    end
    value = tostring(value):lower()
    return value == 'true' or value == '1' or value == 'yes' or value == 'on'
end

local is_mobile = crossbar.isMobile()
local show_list = env_bool('SSH_SHOW_LIST', true)

if is_mobile then
    print('SSH: N/A | color=gray')
    print('---')
    print('SSH inspection is desktop-only')
    print('---')
    print('Refresh | refresh=true')
    return
end

local function count_lines(text)
    if text == nil or text == '' then return 0 end
    local count = 0
    for _ in text:gmatch('[^\n]+') do
        count = count + 1
    end
    return count
end

local who_result = crossbar.exec('who | grep "pts" || true')
local connection_count = count_lines(who_result)

local pgrep_result = crossbar.exec('pgrep -c sshd || true')
local ssh_procs = tonumber((pgrep_result or ''):match('%d+')) or 0

local color = connection_count > 0 and 'orange' or 'green'

print(string.format('SSH: %d | color=%s', connection_count, color))
print('---')
print('Active Sessions: ' .. connection_count)
print('SSH Processes: ' .. ssh_procs)
print('---')

if show_list and connection_count > 0 then
    print('Connected:')
    for line in (who_result or ''):gmatch('([^\r\n]+)') do
        print('  ' .. line)
    end
end

print('---')
print('Refresh | refresh=true')
