-- docker-status.1m.lua
-- Docker Status - Shows running container count

-- 1. Determine container runtime (docker or podman)
local runtime = "docker"
local success, _ = crossbar.exec("which podman")
if success then
    runtime = "podman"
end

-- 2. Count running containers
-- The command lists IDs of running containers. We count the lines in the output.
local count_cmd = runtime .. " ps -q"
local success_count, result_count = crossbar.exec(count_cmd)

local container_count = 0
if success_count and result_count and result_count ~= '' then
    -- Count non-empty lines in the result
    local lines = 0
    for _ in result_count:gmatch("[^\\n]+") do
        lines = lines + 1
    end
    container_count = lines
end

-- 3. Set color based on count
local color = "gray"
if container_count > 0 then
    color = "blue"
end

-- 4. Print the main status line
print(string.format("%d | color=%s", container_count, color))
print("---")
print("Running Containers: " .. container_count)
print("---")

-- 5. List running containers if any
if container_count > 0 then
    print("Containers:")
    local list_cmd = runtime .. ' ps --format "{{.Names}}: {{.Status}}"'
    local success_list, result_list = crossbar.exec(list_cmd)
    if success_list and result_list then
        -- Split the result by newlines and print each line
        for line in result_list:gmatch("([^\r\n]+)") do
            print("  " .. line)
        end
    end
    print("---")
end

-- 6. Add actions
print("Refresh | refresh=true")
