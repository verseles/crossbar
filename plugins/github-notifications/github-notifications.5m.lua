-- github-notifications.5m.lua
-- GitHub Notifications

local token = crossbar.env('GITHUB_TOKEN')

if not token or token == '' then
    print("? | color=gray")
    print("---")
    print("Error: Set GITHUB_TOKEN env var")
    return
end

local result = crossbar.web('https://api.github.com/notifications', headers={
    Authorization='token ' .. token,
    Accept='application/vnd.github.v3+json'
})

if type(result) == 'table' and result.error then
    print("? | color=red")
    print("---")
    print("Error: " .. result.message)
elseif type(result) == 'table' then -- Array of notifications
    -- LuaDardo maps JSON array to table with numeric keys
    -- We count the elements
    local count = 0
    for _ in pairs(result) do count = count + 1 end
    
    local color = count > 0 and 'blue' or 'gray'
    
    print(count .. " | color=" .. color)
    print("---")
    
    if count > 0 then
        print(count .. " unread notifications")
        for i, notif in ipairs(result) do
            if i <= 5 and notif.subject then
                print(notif.subject.title .. " | href=" .. (notif.url or ""))
            end
        end
    else
        print("No unread notifications")
    end
    
    print("---")
    print("Open GitHub | href=https://github.com/notifications")
else
    print("? | color=gray")
    print("---")
    print("Unexpected response format")
end

print("---")
print("Refresh | refresh=true")