-- simple.1s.lua
-- Test plugin for Lua execution

-- Use the crossbar API to check the platform
local platform = crossbar.platform()

if platform then
    print("Lua: OK")
    print("---")
    print("Platform: " .. platform)
else
    print("Lua: Error")
    print("---")
    print("Could not get platform from crossbar API")
end
