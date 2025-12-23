-- quotes.1h.lua
-- Daily Quote using Crossbar API

local result = crossbar.web('https://api.quotable.io/random')

if type(result) == 'table' and not result.error then
    local text = result.content or "No quote found"
    local author = result.author or "Unknown"
    
    local display_text = text
    if #display_text > 40 then
        display_text = string.sub(display_text, 1, 40) .. "..."
    end
    
    print(" " .. display_text)
    print("---")
    print('"' .. text .. '"')
    print("  - " .. author)
else
    print(" Quote Error")
    print("---")
    print("Failed to fetch quote")
end

print("---")
print("Refresh | refresh=true")
