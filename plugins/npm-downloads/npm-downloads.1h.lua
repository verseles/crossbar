-- npm-downloads.1h.lua
-- NPM Downloads via Crossbar web

local function env(name, default)
    local value = crossbar.env(name, default)
    if value == nil or value == '' then
        return default
    end
    return value
end

local package_name = env('NPM_PACKAGE', 'lodash')
if not package_name:match('^[a-z0-9@._/%-]+$') then
    print('📦 N/A | color=red')
    print('---')
    print('Invalid package name')
    print('Allowed: a-z 0-9 @ . _ / -')
    print('---')
    print('Refresh | refresh=true')
    return
end
local url = 'https://api.npmjs.org/downloads/point/last-week/' .. package_name
local response, err = crossbar.web(url)
if response == nil then
    print('📦 N/A | color=gray')
    print('---')
    print(err or 'Error fetching data')
    print('---')
    print('Refresh | refresh=true')
    return
end

if response.error or (response.status and response.status >= 400) then
    print('📦 N/A | color=gray')
    print('---')
    print(response.message or ('HTTP ' .. tostring(response.status)))
    print('---')
    print('Refresh | refresh=true')
    return
end

local data = response.data
local downloads = nil
if type(data) == 'table' then
    downloads = tonumber(data.downloads)
end
if downloads == nil then
    print('📦 N/A | color=gray')
    print('---')
    print('Error fetching data')
    print('---')
    print('Refresh | refresh=true')
    return
end

local formatted = tostring(downloads):reverse():gsub('(%d%d%d)', '%1,'):reverse():gsub('^,', '')

print('📦 ' .. formatted)
print('---')
print('Package: ' .. package_name)
print('Weekly Downloads: ' .. formatted)
print('---')
print('Open NPM | href=https://www.npmjs.com/package/' .. package_name)
print('Refresh | refresh=true')
