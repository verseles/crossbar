-- ssh-connections.30s.lua
-- Shows active SSH connections

-- 1. Count active terminal sessions (a common proxy for SSH connections)
local success_who, who_result = crossbar.exec('who | grep "pts" || true')

local connection_count = 0
if success_who and who_result and who_result ~= "" then
    for _ in who_result:gmatch("[^\\n]+") do
        connection_count = connection_count + 1
    end
end

-- 2. Count sshd processes
local success_pgrep, pgrep_result = crossbar.exec('pgrep -c sshd || true')
local ssh_procs = 0
if success_pgrep and pgrep_result and pgrep_result ~= "" then
    ssh_procs = tonumber(pgrep_result:match("%d+")) or 0
end

-- 3. Set color based on active connections
local color = "green"
if connection_count > 0 then
    color = "orange"
end

-- 4. Print the main status line
print(string.format("SSH: %d | color=%s", connection_count, color))
print("---")
print("Active Sessions: " .. connection_count)
print("SSH Processes: " .. ssh_procs)
print("---")

-- 5. List connected users if any
if connection_count > 0 then
    print("Connected:")
    for line in who_result:gmatch("([^\r\n]+)") do
        print("  " .. line)
    end
end

print("---")
print("Refresh | refresh=true")
