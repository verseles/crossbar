-- disk.5m.lua
-- Disk Usage Monitor for the root partition in Lua

-- 1. Get disk usage from Crossbar CLI
local success, result = crossbar.exec('crossbar disk /')

if not success then
    print("? | color=gray")
    print("---")
    print("Error: Could not get disk info")
    if result and result ~= '' then
        print(result) -- Show stderr
    end
    return
end

-- 2. Parse the output (e.g., "8.2/16.0 GB")
-- The gmatch iterator finds all numbers in the string
local numbers = {}
for num in result:gmatch("([%d%.]+)") do
    table.insert(numbers, tonumber(num))
end

if #numbers < 2 then
    print("? | color=gray")
    print("---")
    print("Error: Unexpected disk info format")
    print("Received: " .. result)
    return
end

local used_size = numbers[1]
local total_size = numbers[2]

-- 3. Calculate percentage and determine color
local usage_percent = 0
if total_size > 0 then
    usage_percent = math.floor((used_size / total_size) * 100)
end

local color = "green"
if usage_percent > 90 then
    color = "red"
elseif usage_percent > 75 then
    color = "orange"
end

-- 4. Format the output
print(string.format("%d%% | color=%s", usage_percent, color))
print("---")
print(string.format("Used: %.1fG / %.1fG", used_size, total_size))
print("---")
print("Refresh | refresh=true")
