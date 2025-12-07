-- clock.1s.lua
-- Simple clock plugin using embedded Lua interpreter
-- Works on ALL platforms (Linux, macOS, Windows, Android, iOS)

local time = crossbar.time()
print("🕐 " .. time)
