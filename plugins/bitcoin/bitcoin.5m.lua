-- bitcoin.5m.lua
-- Bitcoin price tracker using embedded Lua interpreter
-- Works on ALL platforms (Linux, macOS, Windows, Android, iOS)

-- Note: web() is async and not yet supported in embedded Lua
-- For now, show a placeholder 

local time = crossbar.time()

print("₿ BTC")
print("---")
print("Price: Loading...")
print("Updated: " .. time)
print("Note: Embedded Lua lacks async web access")
