-- ip-info.1h.lua
-- Public IP and location info via Crossbar web

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

local show_region = env_bool('IPINFO_SHOW_REGION', true)
local show_country = env_bool('IPINFO_SHOW_COUNTRY', true)
local show_isp = env_bool('IPINFO_SHOW_ISP', true)
local show_timezone = env_bool('IPINFO_SHOW_TIMEZONE', false)
local show_map = env_bool('IPINFO_SHOW_MAP', true)
local enable_copy = env_bool('IPINFO_ENABLE_COPY', true)

local response, err = crossbar.web('https://ipinfo.io/json')
if response == nil then
    print('🌐 N/A | color=gray')
    print('---')
    print(err or 'Failed to fetch IP info')
    print('---')
    print('Refresh | refresh=true')
    return
end

if response.error or (response.status and response.status >= 400) then
    print('🌐 N/A | color=gray')
    print('---')
    print(response.message or ('HTTP ' .. tostring(response.status)))
    print('---')
    print('Refresh | refresh=true')
    return
end

local data = response.data
if type(data) ~= 'table' then
    print('🌐 N/A | color=gray')
    print('---')
    print('Invalid response')
    print('---')
    print('Refresh | refresh=true')
    return
end

local ip = data.ip
local city = data.city
local region = data.region
local country = data.country
local org = data.org
local timezone = data.timezone
local loc = data.loc

if ip == nil or ip == '' then
    print('🌐 N/A | color=gray')
    print('---')
    print('Failed to fetch IP info')
    print('---')
    print('Refresh | refresh=true')
    return
end

print('🌐 ' .. ip)
print('---')
print('IP: ' .. ip)
if city and city ~= '' then
    print('City: ' .. city)
end
if show_region and region and region ~= '' then
    print('Region: ' .. region)
end
if show_country and country and country ~= '' then
    print('Country: ' .. country)
end
if show_isp and org and org ~= '' then
    print('ISP: ' .. org)
end
if show_timezone and timezone and timezone ~= '' then
    print('Timezone: ' .. timezone)
end
print('---')
if enable_copy then
    print('Copy IP | bash="crossbar clipboard ' .. ip .. '" terminal=false')
end
if show_map and loc and loc ~= '' then
    print('Open Map | href=https://www.google.com/maps?q=' .. loc)
end
print('Open ipinfo | href=https://ipinfo.io/' .. ip)
print('---')
print('Refresh | refresh=true')
