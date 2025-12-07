-- memory.10s.lua
-- Memory usage monitor using embedded Lua interpreter
-- Works on ALL platforms (Linux, macOS, Windows, Android, iOS)

local platform = crossbar.platform()
local home = crossbar.homeDir()

print("🧠 " .. platform .. " | " .. home)
