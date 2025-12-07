-- battery.1m.lua
-- Battery status monitor using embedded Lua interpreter
-- Works on ALL platforms (Linux, macOS, Windows, Android, iOS)

local platform = crossbar.platform()
local isMobile = crossbar.isMobile()

if isMobile == 1 then
    print("🔋 Mobile Device")
else
    print("🔌 Desktop: " .. platform)
end
