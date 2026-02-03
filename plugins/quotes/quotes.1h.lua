-- quotes.1h.lua
-- Daily Quote using Crossbar CLI

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
    print('QUOTE N/A | color=gray')
    print('---')
    print('Quotes via CLI are limited on mobile')
    print('---')
    print('Refresh | refresh=true')
    return
end

local max_len = env_num('QUOTE_MAX_LEN', 40)
local response, err = crossbar.web('https://api.quotable.io/random')
if response == nil then
    print('QUOTE Error | color=gray')
    print('---')
    print(err or 'Failed to fetch quote')
    print('---')
    print('Refresh | refresh=true')
    return
end

if response.error or (response.status and response.status >= 400) then
    print('QUOTE Error | color=gray')
    print('---')
    print(response.message or ('HTTP ' .. tostring(response.status)))
    print('---')
    print('Refresh | refresh=true')
    return
end

local data = response.data
local text = nil
local author = nil
if type(data) == 'table' then
    text = data.content
    author = data.author
end

if text == nil then
    print('QUOTE Error | color=gray')
    print('---')
    print('Failed to fetch quote')
    print('---')
    print('Refresh | refresh=true')
    return
end

local display_text = text
if #display_text > max_len then
    display_text = string.sub(display_text, 1, max_len) .. '...'
end

print('QUOTE ' .. display_text)
print('---')
print('"' .. text .. '"')
if author and author ~= '' then
    print('  - ' .. author)
end
print('---')
print('Refresh | refresh=true')
