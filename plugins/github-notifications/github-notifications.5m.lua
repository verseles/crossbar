-- github-notifications.5m.lua
-- GitHub Notifications in Lua using Crossbar API
-- Shows unread notification count

-- 1. Get token from Crossbar secure config, or fallback to env var
local token = crossbar.env('CROSSBAR_PLUGIN_GITHUB_TOKEN')
if token == nil or token == '' then
    token = crossbar.env('GITHUB_TOKEN')
end

-- 2. Handle missing token
if token == nil or token == '' then
    print("? | color=gray")
    print("---")
    print("Error: Set GITHUB_TOKEN")
    print("Configure via `crossbar settings set CROSSBAR_PLUGIN_GITHUB_TOKEN your_token`")
    return -- Exit
end

-- 3. Build curl command to fetch notifications
-- The '-s' flag makes curl silent, preventing progress meters
local cmd = 'curl -s -H "Authorization: token ' .. token .. '" -H "Accept: application/vnd.github.v3+json" https://api.github.com/notifications'

-- 4. Execute the command
local success, result = crossbar.exec(cmd)

-- 5. Process the result
if not success then
    print("? | color=gray")
    print("---")
    print("Error: Failed to execute curl")
    -- The result might contain stderr, useful for debugging
    if result and result ~= '' then
        print(result)
    end
else
    -- This is a simple way to count notifications without a full JSON parser.
    -- Each notification in the JSON array is an object that contains an "id" field.
    -- We count the occurrences of the string '"id":'. This is not perfect
    -- but works for the GitHub API response format.
    local _, count = result:gsub('"id":', '')

    local color = 'blue'
    if count == 0 then
        color = 'gray'
    end

    print(count .. " | color=" .. color)
    print("---")

    if count > 0 then
        -- A full JSON parser would be needed to list individual notifications.
        -- For now, we show the total count.
        print(count .. " unread notifications")
    else
        print("No unread notifications")
    end

    print("---")
    print("Open GitHub Notifications | href=https://github.com/notifications")
end

print("---")
print("Refresh | refresh=true")
