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

local response, err = crossbar.web(url, { timeout = timeout })
local status_code = nil
if response == nil then
    status_code = nil
elseif response.status ~= nil then
    status_code = tonumber(response.status)
end

local icon = '✅'
local color = 'green'
local status_text = 'Up'

if status_code == nil then
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
print('---')
print('Open Site | href=' .. url)
print('Refresh | refresh=true')
