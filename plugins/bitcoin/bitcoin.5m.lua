-- bitcoin.5m.lua
-- Bitcoin price tracker using embedded Lua interpreter
-- Works on ALL platforms (Linux, macOS, Windows, Android, iOS)

-- Note: web() is async and not yet supported in embedded Lua
-- For now, show a placeholder with sync data

local time = crossbar.time()
local uuid = crossbar.uuid()

print("₿ BTC | Updated: " .. time)
