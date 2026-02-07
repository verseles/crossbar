-- countdown.1s.lua
-- Countdown Timer in Lua

local function env(name, default)
    local value = crossbar.env(name, default)
    if value == nil or value == '' then
        return default
    end
    return value
end

local target_str = env('COUNTDOWN_TARGET', '2026-12-31T23:59:59+00:00')
local label = env('COUNTDOWN_LABEL', 'Countdown')
local done_text = env('COUNTDOWN_DONE_TEXT', 'Countdown complete!')

local function get_local_offset_seconds(ts)
    local local_t = os.date('*t', ts)
    local utc_t = os.date('!*t', ts)
    return os.difftime(os.time(local_t), os.time(utc_t))
end

local function parse_target(raw)
    -- RFC3339 with explicit timezone: YYYY-MM-DDTHH:MM:SS+HH:MM
    local y, mo, d, h, mi, s, sign, off_h, off_m = raw:match(
        '^(%d%d%d%d)%-(%d%d)%-(%d%d)T(%d%d):(%d%d):(%d%d)([+-])(%d%d):(%d%d)$'
    )
    if y then
        local local_ts = os.time({
            year = tonumber(y),
            month = tonumber(mo),
            day = tonumber(d),
            hour = tonumber(h),
            min = tonumber(mi),
            sec = tonumber(s),
        })
        local specified_offset = tonumber(off_h) * 3600 + tonumber(off_m) * 60
        if sign == '-' then
            specified_offset = -specified_offset
        end
        local local_offset = get_local_offset_seconds(local_ts)
        return local_ts + (local_offset - specified_offset), raw
    end

    -- RFC3339 UTC suffix
    y, mo, d, h, mi, s = raw:match(
        '^(%d%d%d%d)%-(%d%d)%-(%d%d)T(%d%d):(%d%d):(%d%d)Z$'
    )
    if y then
        local local_ts = os.time({
            year = tonumber(y),
            month = tonumber(mo),
            day = tonumber(d),
            hour = tonumber(h),
            min = tonumber(mi),
            sec = tonumber(s),
        })
        local local_offset = get_local_offset_seconds(local_ts)
        return local_ts + local_offset, raw
    end

    return nil, raw
end

local target_time, normalized = parse_target(target_str)
if target_time == nil then
    print('! | color=red')
    print('---')
    print('Error: Invalid datetime format')
    print('Expected: YYYY-MM-DDTHH:MM:SS+00:00')
    return
end

local now = os.time()
local diff_seconds = target_time - now

if diff_seconds <= 0 then
    print('Done!')
    print('---')
    print(done_text)
else
    local days = math.floor(diff_seconds / 86400)
    local remainder = diff_seconds % 86400
    local hours = math.floor(remainder / 3600)
    remainder = remainder % 3600
    local minutes = math.floor(remainder / 60)
    local seconds = remainder % 60

    local display = ""
    if days > 0 then
        display = string.format("%dd %dh", days, hours)
    elseif hours > 0 then
        display = string.format("%dh %dm", hours, minutes)
    else
        display = string.format("%dm %ds", minutes, seconds)
    end

    print('⏳ ' .. display)
    print('---')
    print(label .. ': ' .. normalized)
end

print('---')
print('Refresh | refresh=true')
