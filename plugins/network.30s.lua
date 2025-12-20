-- network.30s.lua
-- Network Status - Shows connection status and IP

-- 1. Check internet connectivity by pinging Google's DNS
local success_ping, _ = crossbar.exec("ping -c 1 -W 1 8.8.8.8")
local status = ""
local color = ""

if success_ping then
    status = "Online"
    color = "green"
else
    status = "Offline"
    color = "red"
end

-- 2. Get local IP address based on platform
local platform = crossbar.platform()
local ip_cmd = ""
if platform == "macos" then
    ip_cmd = "ipconfig getifaddr en0 || ipconfig getifaddr en1"
elseif platform == "linux" then
    ip_cmd = "hostname -I | awk '{print $1}'"
else
    -- Fallback for other platforms (e.g., Windows), might need adjustment
    ip_cmd = "hostname -I 2>/dev/null"
end

local success_ip, ip_address = crossbar.exec(ip_cmd)
if not success_ip or ip_address == "" or ip_address == nil then
    ip_address = "N/A"
else
    -- Clean up the result
    ip_address = ip_address:match("^%s*(.-)%s*$")
end


-- 3. Print the main status line
print(string.format("%s | color=%s", status, color))
print("---")
print("Status: " .. status)
print("Local IP: " .. ip_address)
print("---")
print("Refresh | refresh=true")
