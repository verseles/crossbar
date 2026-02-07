-- site-check.1m.lua
-- Site Check via Crossbar web

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

local url = env('SITE_URL', 'https://www.google.com')
local timeout = env_num('SITE_TIMEOUT', 5)
if timeout < 1 then timeout = 1 end
if timeout > 60 then timeout = 60 end

if not url:match('^https?://') then
    print('⚠️ Invalid URL | color=red')
    print('---')
    print('URL must start with http:// or https://')
    print('Current: ' .. url)
    print('---')
    print('Refresh | refresh=true')
    return
end

local response, err = crossbar.web(url, { timeout = timeout })
local status_code = nil
local error_message = nil

if response == nil then
    error_message = err or 'No response'
elseif type(response) ~= 'table' then
    error_message = 'Invalid response'
else
    if response.status ~= nil then
        status_code = tonumber(response.status)
    end
    if response.error then
        error_message = response.message or 'Request failed'
    end
end

local icon = '✅'
local color = 'green'
local status_text = 'Up'

if error_message ~= nil then
    if error_message == 'Fetching...' then
        icon = '⏳'
        color = 'gray'
        status_text = 'Fetching'
    elseif status_code ~= nil and status_code >= 400 then
        icon = '❌'
        color = 'red'
        status_text = 'Down (HTTP ' .. status_code .. ')'
    else
        icon = '⚠️'
        color = 'orange'
        status_text = status_code ~= nil
            and ('Error (HTTP ' .. status_code .. ')')
            or 'Error'
    end
elseif status_code == nil then
    icon = '⚠️'
    color = 'orange'
    status_text = 'Unknown'
elseif status_code >= 200 and status_code < 300 then
    status_text = 'Up (HTTP ' .. status_code .. ')'
elseif status_code >= 400 then
    icon = '❌'
    color = 'red'
    status_text = 'Down (HTTP ' .. status_code .. ')'
else
    icon = '⚠️'
    color = 'orange'
    status_text = 'Degraded (HTTP ' .. status_code .. ')'
end

print(icon .. ' ' .. status_text .. ' | color=' .. color)
print('---')
print('Site: ' .. url)
print('Timeout: ' .. tostring(timeout) .. 's')
if error_message ~= nil then
    print('Error: ' .. error_message)
end
print('---')
print('Open Site | href=' .. url)
print('Refresh | refresh=true')
