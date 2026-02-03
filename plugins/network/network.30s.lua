-- network.30s.lua
-- Network Status - Shows connection status and IP

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

local function trim(value)
    if value == nil then return '' end
    return (value:gsub('^%s+', ''):gsub('%s+$', ''))
end

local is_mobile = crossbar.isMobile()
local show_public = env_bool('NET_SHOW_PUBLIC_IP', false)
local ping_host = env('NET_PING_HOST', '1.1.1.1')
local show_ping = env_bool('NET_SHOW_PING', false)

if is_mobile then
    print('NET Mobile | color=gray')
    print('---')
    print('Network details via CLI are limited on mobile')
    print('---')
    print('Refresh | refresh=true')
    return
end

local status = trim(crossbar.exec('crossbar net status'))
if status == '' then status = 'unknown' end

local local_ip = trim(crossbar.exec('crossbar net ip'))
if local_ip == '' then local_ip = 'N/A' end

local public_ip = ''
if show_public then
    public_ip = trim(crossbar.exec('crossbar net ip --public'))
    if public_ip == '' then public_ip = 'N/A' end
end

local ping = ''
if show_ping then
    ping = trim(crossbar.exec('crossbar net ping ' .. ping_host))
end

local color = 'yellow'
if status == 'online' then
    color = 'green'
elseif status == 'offline' then
    color = 'red'
end

print('NET ' .. status .. ' | color=' .. color)
print('---')
print('Status: ' .. status)
print('Local IP: ' .. local_ip)
if show_public then
    print('Public IP: ' .. public_ip)
end
if show_ping then
    print('Ping (' .. ping_host .. '): ' .. (ping ~= '' and ping or 'timeout'))
end
print('---')
print('Refresh | refresh=true')
