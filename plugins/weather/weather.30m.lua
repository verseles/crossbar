-- weather.30m.lua
-- Weather plugin in Lua using Crossbar API
-- Fetches weather from wttr.in

-- Location can be customized. Empty string uses auto-detection based on IP.
local location = ""
local cmd = "curl -s 'https://wttr.in/" .. location .. "?format=3'"

local success, result = crossbar.exec(cmd)

if success then
    -- Example output: "New York: ☀️ +15°C"
    -- Just print the result directly
    print(result)
else
    print("? | color=gray")
    print("---")
    print("Error fetching weather")
    if result and result ~= '' then
        print(result) -- Show stderr from curl if available
    end
end

print("---")
print("Full forecast | href=https://wttr.in/" .. location)
print("Refresh | refresh=true")
