-- cpu.10s.lua
-- CPU usage monitor using embedded Lua interpreter
-- Works on ALL platforms (Linux, macOS, Windows, Android, iOS)

-- Note: crossbar.cpu() is async, so we use sync time for demo
local time = crossbar.time()
local platform = crossbar.platform()

-- For now, display platform info until async is supported
print("💻 " .. platform)
