-- spotify.5s.lua
-- Spotify Now Playing in Lua (macOS and Linux with playerctl)

-- Helper function to extract a value from a JSON string without a full parser
-- Example: extract_json_value('{"name":"test"}', "name") -> "test"
local function extract_json_value(json_str, key)
    if json_str == nil then return nil end
    -- Look for "key":"value" or "key": "value"
    local pattern = '"' .. key .. '"%s*:%s*"(.-)"'
    local match = json_str:match(pattern)
    return match
end

-- 1. Get media info from Crossbar CLI
local success, result = crossbar.exec('crossbar media playing --json')

if not success or result == "null" or result == "" then
    print("🎵 | color=gray")
    print("---")
    print("Spotify not running or no track playing")
    print("Refresh | refresh=true")
    return
end

-- 2. Extract details from the JSON output
local status = extract_json_value(result, "status")
local artist = extract_json_value(result, "artist")
local track = extract_json_value(result, "title")

-- 3. Display info based on status
if status == "playing" and artist and track then
    local display_text = track .. " - " .. artist
    -- Truncate if too long
    if #display_text > 40 then
        display_text = display_text:sub(1, 37) .. "..."
    end

    print("▶️ " .. display_text)
    print("---")
    print("Artist: " .. artist)
    print("Track: " .. track)
    print("---")
    print("Play/Pause | bash='crossbar media toggle' terminal=false")
    print("Next | bash='crossbar media next' terminal=false")
    print("Prev | bash='crossbar media prev' terminal=false")
else
    print("⏸️ | color=gray")
    print("---")
    print("Spotify is paused or stopped")
end

print("---")
print("Refresh | refresh=true")
