-- weather.30m.lua
-- Weather display using embedded Lua interpreter
-- Works on ALL platforms (Linux, macOS, Windows, Android, iOS)

-- Note: web() is async and not yet supported in embedded Lua
-- For now, show placeholder

local date = crossbar.date()

print("☀️ Weather")
print("---")
print("Status: Loading...")
print("Date: " .. date)
print("Note: Embedded Lua lacks async web access")
