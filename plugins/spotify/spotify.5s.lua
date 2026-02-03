-- spotify.5s.lua
-- Media Now Playing (uses crossbar media)

-- Uses Crossbar JSON helper
local function env(name, default)
    local value = crossbar.env(name, default)
    if value == nil or value == '' then
        return default
    end
    return value
end

local function env_num(name, default)
    local value = env(name, tostring(default))
    local num = tonumber(value)
    if num == nil then
        return default
    end
    return num
end

-- 1. Get media info from Crossbar CLI
local result = crossbar.exec('crossbar media playing --json')
if result == nil or result == '' or result == 'null' then
    print('🎵 | color=gray')
    print('---')
    print('No media player detected')
    print('Refresh | refresh=true')
    return
end
local data, err = crossbar.jsonDecode(result)
if data == nil then
    print('🎵 | color=gray')
    print('---')
    print(err or 'Invalid response')
    print('Refresh | refresh=true')
    return
end

if type(data) ~= 'table' then
    print('🎵 | color=gray')
    print('---')
    print('Invalid response')
    print('Refresh | refresh=true')
    return
end

local status = data.status
local artist = data.artist
local track = data.title
local max_len = env_num('MEDIA_MAX_LEN', 40)

-- 3. Display info based on status
if status == 'playing' and artist and track then
    local display_text = track .. " - " .. artist
    -- Truncate if too long
    if #display_text > max_len then
        display_text = display_text:sub(1, math.max(1, max_len - 3)) .. "..."
    end

    print('▶️ ' .. display_text)
    print('---')
    print('Artist: ' .. artist)
    print('Track: ' .. track)
    print('---')
    print('Play/Pause | bash="crossbar media toggle" terminal=false refresh=true')
    print('Next | bash="crossbar media next" terminal=false refresh=true')
    print('Prev | bash="crossbar media prev" terminal=false refresh=true')
else
    print('⏸️ | color=gray')
    print('---')
    if status == 'stopped' then
        print('Playback stopped')
    elseif status == 'unavailable' or status == 'unsupported' then
        print('Media status unavailable')
    else
        print('Paused or not playing')
    end
end

print('---')
print('Refresh | refresh=true')
