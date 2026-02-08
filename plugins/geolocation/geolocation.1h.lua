-- geolocation.1h.lua
-- Geographic location via IP using ipapi.co

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

-- Regional Indicator Symbol lookup (A-Z) for flag emoji construction.
-- Uses Lua 5.3 \u{XXXX} escape (supported by lua_dardo) to embed
-- Unicode codepoints U+1F1E6..U+1F1FF directly.
local ri = {
    A = "\u{1F1E6}", B = "\u{1F1E7}", C = "\u{1F1E8}", D = "\u{1F1E9}",
    E = "\u{1F1EA}", F = "\u{1F1EB}", G = "\u{1F1EC}", H = "\u{1F1ED}",
    I = "\u{1F1EE}", J = "\u{1F1EF}", K = "\u{1F1F0}", L = "\u{1F1F1}",
    M = "\u{1F1F2}", N = "\u{1F1F3}", O = "\u{1F1F4}", P = "\u{1F1F5}",
    Q = "\u{1F1F6}", R = "\u{1F1F7}", S = "\u{1F1F8}", T = "\u{1F1F9}",
    U = "\u{1F1FA}", V = "\u{1F1FB}", W = "\u{1F1FC}", X = "\u{1F1FD}",
    Y = "\u{1F1FE}", Z = "\u{1F1FF}",
}

local function country_to_flag(code)
    if type(code) ~= 'string' or string.len(code) ~= 2 then
        return ''
    end
    code = code:upper()
    local a = ri[code:sub(1, 1)]
    local b = ri[code:sub(2, 2)]
    if a and b then
        return a .. b
    end
    return ''
end

local show_coords = env_bool('GEOLOCATION_SHOW_COORDINATES', true)
local show_tz = env_bool('GEOLOCATION_SHOW_TIMEZONE', true)
local show_postal = env_bool('GEOLOCATION_SHOW_POSTAL', false)
local show_map = env_bool('GEOLOCATION_SHOW_MAP', true)

local response, err = crossbar.web('https://ipapi.co/json/')
if response == nil then
    print('GEO N/A | color=gray')
    print('---')
    print(err or 'Failed to fetch location')
    print('---')
    print('Refresh | refresh=true')
    return
end

if response.error or (response.status and response.status >= 400) then
    print('GEO N/A | color=gray')
    print('---')
    print(response.message or ('HTTP ' .. tostring(response.status)))
    print('---')
    print('Refresh | refresh=true')
    return
end

local data = response.data
if type(data) ~= 'table' then
    print('GEO N/A | color=gray')
    print('---')
    print('Invalid response')
    print('---')
    print('Refresh | refresh=true')
    return
end

local city = data.city or ''
local region = data.region or ''
local country_name = data.country_name or ''
local country_code = data.country_code or ''
local latitude = data.latitude
local longitude = data.longitude
local timezone = data.timezone or ''
local postal = data.postal or ''

if city == '' and country_name == '' then
    print('GEO N/A | color=gray')
    print('---')
    print('Location not available')
    print('---')
    print('Refresh | refresh=true')
    return
end

local flag = country_to_flag(country_code)
local title = city
if title == '' then
    title = country_name
end
if flag ~= '' then
    title = flag .. ' ' .. title
end

print(title)
print('---')

if city ~= '' then
    print('City: ' .. city)
end
if region ~= '' then
    print('Region: ' .. region)
end
if country_name ~= '' then
    local country_line = 'Country: ' .. country_name
    if country_code ~= '' then
        country_line = country_line .. ' (' .. country_code .. ')'
    end
    print(country_line)
end

if show_coords and latitude and longitude then
    print('Coordinates: ' .. tostring(latitude) .. ', ' .. tostring(longitude))
end
if show_tz and timezone ~= '' then
    print('Timezone: ' .. timezone)
end
if show_postal and postal ~= '' then
    print('Postal: ' .. postal)
end

print('---')

if show_map and latitude and longitude then
    local coords = tostring(latitude) .. ',' .. tostring(longitude)
    print('Open in Google Maps | href=https://www.google.com/maps?q=' .. coords)
    print('Open in OpenStreetMap | href=https://www.openstreetmap.org/?mlat=' .. tostring(latitude) .. '&mlon=' .. tostring(longitude) .. '#map=12/' .. tostring(latitude) .. '/' .. tostring(longitude))
end

if show_coords and latitude and longitude then
    local coords_text = tostring(latitude) .. ', ' .. tostring(longitude)
    print('Copy Coordinates | bash="crossbar clipboard ' .. coords_text .. '" terminal=false')
end

print('Refresh | refresh=true')
