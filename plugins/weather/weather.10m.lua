-- weather.10m.lua
-- Weather display using embedded Lua interpreter
-- Works on ALL platforms (Linux, macOS, Windows, Android, iOS)

-- Note: web() is async and not yet supported in embedded Lua
-- For now, show placeholder with sync data

local date = crossbar.date()
local platform = crossbar.platform()

print("☀️ Weather | " .. date .. " | " .. platform)
