-- world-clock.1m.lua
-- Shows time in multiple timezones

local function env(name, default)
    local value = crossbar.env(name, default)
    if value == nil or value == '' then
        return default
    end
    return value
end

local function parse_timezones(raw)
    local zones = {}
    if raw == nil then
        return zones
    end

    -- Prefer one-entry-per-line, but keep comma compatibility.
    raw = raw:gsub(',', '\n')

    for line in raw:gmatch('[^\r\n]+') do
        local trimmed = line:gsub('^%s+', ''):gsub('%s+$', '')
        if trimmed ~= '' then
            local name, offset, flag = trimmed:match('^(.-)|([%-%d%.]+)|?(.*)$')
            if name and offset then
                name = name:gsub('^%s+', ''):gsub('%s+$', '')
                local parsed_offset = tonumber(offset)
                if parsed_offset ~= nil and name ~= '' then
                    local parsed_flag = (flag or ''):gsub('^%s+', ''):gsub('%s+$', '')
                    if parsed_flag == '' then
                        parsed_flag = '🕒'
                    end
                    table.insert(zones, {
                        name = name,
                        offset = parsed_offset,
                        flag = parsed_flag,
                    })
                end
            end
        end
    end
    return zones
end

local default_zones = 'New York|-5|🇺🇸\nLondon|0|🇬🇧\nTokyo|9|🇯🇵\nSydney|11|🇦🇺\nDubai|4|🇦🇪'
local timezones = parse_timezones(env('WORLD_CLOCK_ZONES', default_zones))

if #timezones == 0 then
    print('🌍 Invalid config | color=red')
    print('---')
    print('Expected one zone per line:')
    print('Name|Offset|Flag')
    print('Example: London|0|🇬🇧')
    print('---')
    print('Refresh | refresh=true')
    return
end

local local_time = os.date('%H:%M')
local utc_time = os.time(os.date('!*t')) -- Get current UTC timestamp

-- 3. Main status bar display
print('🌍 ' .. local_time)
print('---')
print('World Clock')
print('---')

-- 4. Iterate and display time for each timezone
for _, tz in ipairs(timezones) do
    -- Calculate the time in the target timezone by adding the offset
    local target_timestamp = utc_time + (tz.offset * 3600)
    -- Format the timestamp into HH:MM
    local tz_time = os.date('%H:%M', target_timestamp)
    print(string.format('%s %s: %s', tz.flag, tz.name, tz_time))
end

-- 5. Footer
print('---')
print('Refresh | refresh=true')
