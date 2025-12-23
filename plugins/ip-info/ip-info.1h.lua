-- ip-info.1h.lua
-- IP Info using Crossbar API web function

-- Use Crossbar bridge to make HTTPS request (returns a Lua table if JSON)
local result = crossbar.web('https://ipinfo.io/json')

-- Check if result is a table (JSON parsed) or string (error/raw)
if type(result) == 'table' and not result.error then
    local ip = result.ip or 'N/A'
    print("🌐 " .. ip)
    print("---")
    print("IP: " .. ip)
    print("City: " .. (result.city or 'N/A'))
    print("Region: " .. (result.region or 'N/A'))
    print("Country: " .. (result.country or 'N/A'))
    print("ISP: " .. (result.org or 'N/A'))
    print("Timezone: " .. (result.timezone or 'N/A'))
    
    print("---")
    -- Using bash for clipboard copy as Lua clipboard API is basic
    if crossbar.isDesktop() then
        print("Copy IP | bash='echo -n " .. ip .. " | pbcopy' terminal=false") -- macOS
        -- Ideally we should detect OS and use xclip/powershell, but pbcopy is a common alias
    end
else
    local msg = "Error"
    if type(result) == 'table' then msg = result.message or "Unknown" end
    
    print("🌐 N/A | color=gray")
    print("---")
    print("Error: " .. msg)
end

print("---")
print("Refresh | refresh=true")
