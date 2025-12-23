-- site-check.1m.lua
-- Site Check using Crossbar API

local url = "https://www.google.com"
local result = crossbar.web(url, timeout=5)

local status_code = 0
local error_msg = nil

if type(result) == 'table' and result.statusCode then
    status_code = result.statusCode
elseif type(result) == 'table' and result.error then
    error_msg = result.message
elseif type(result) == 'string' then
    -- If it returns raw string, likely 200 OK HTML
    status_code = 200
end

local icon = "✅"
local color = "green"
local status_text = "Up"

if error_msg then
    icon = "❌"
    color = "red"
    status_text = "Error: " .. error_msg
elseif status_code >= 200 and status_code < 300 then
    icon = "✅"
    color = "green"
    status_text = "Up (HTTP " .. status_code .. ")"
else
    icon = "⚠️"
    color = "orange"
    status_text = "Down (HTTP " .. status_code .. ")"
end

print(icon .. " " .. status_text .. " | color=" .. color)
print("---")
print("Site: " .. url)
print("Refresh | refresh=true")
