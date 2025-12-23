-- npm-downloads.1h.lua
-- NPM Downloads using Crossbar API

local package_name = crossbar.env('CROSSBAR_NPM_PACKAGE') or 'lodash'
local url = 'https://api.npmjs.org/downloads/point/last-week/' .. package_name

local result = crossbar.web(url)

if type(result) == 'table' and not result.error then
    local downloads = result.downloads or 0
    -- Simple number formatting (no locale support in Lua 5.3 stdlib easily)
    local formatted = tostring(downloads):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")

    print("📦 " .. formatted)
    print("---")
    print("Package: " .. package_name)
    print("Weekly Downloads: " .. formatted)
    print("---")
    print("Open NPM | href=https://www.npmjs.com/package/" .. package_name)
else
    print("📦 N/A | color=gray")
    print("---")
    print("Error fetching data")
end

print("---")
print("Refresh | refresh=true")
