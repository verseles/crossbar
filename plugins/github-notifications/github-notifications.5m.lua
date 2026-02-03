-- github-notifications.5m.lua
-- GitHub Notifications (desktop via CLI)

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
if is_mobile then
    print('GH N/A | color=gray')
    print('---')
    print('GitHub notifications via CLI are limited on mobile')
    print('---')
    print('Refresh | refresh=true')
    return
end

local token = env('GITHUB_TOKEN', '')
if token == '' then
    print('GH -- | color=gray')
    print('---')
    print('Set GITHUB_TOKEN (config uses CROSSBAR_PLUGIN_GITHUB_TOKEN)')
    print('---')
    print('Refresh | refresh=true')
    return
end

local max_items = env_num('GITHUB_MAX_ITEMS', 5)
local response, err = crossbar.web('https://api.github.com/notifications', {
    headers = {
        Authorization = 'token ' .. token,
        Accept = 'application/vnd.github.v3+json',
    },
    timeout = 20,
})

if response == nil then
    print('GH Error | color=red')
    print('---')
    print('Error: ' .. (err or 'API error'))
    print('---')
    print('Refresh | refresh=true')
    return
end

if response.error or (response.status and response.status >= 400) then
    local message = response.message or ('HTTP ' .. tostring(response.status))
    print('GH Error | color=red')
    print('---')
    print('Error: ' .. message)
    print('---')
    print('Refresh | refresh=true')
    return
end

local data = response.data
if type(data) ~= 'table' then
    print('GH Error | color=red')
    print('---')
    print('Error: Invalid response')
    print('---')
    print('Refresh | refresh=true')
    return
end

local count = #data

local color = count > 0 and 'blue' or 'gray'
print(count .. ' | color=' .. color)
print('---')

if count > 0 then
    print(count .. ' unread notifications')
    local shown = 0
    for i = 1, #data do
        local item = data[i]
        local title = nil
        if type(item) == 'table' then
            if type(item.subject) == 'table' then
                title = item.subject.title
            end
            if title == nil then
                title = item.title
            end
        end
        if title == nil or title == '' then
            title = 'Notification ' .. tostring(i)
        end
        print(title)
        shown = shown + 1
        if shown >= max_items then
            break
        end
    end
else
    print('No unread notifications')
end

print('---')
print('Open GitHub | href=https://github.com/notifications')
print('Refresh | refresh=true')
