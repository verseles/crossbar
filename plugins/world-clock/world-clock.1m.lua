-- world-clock.1m.lua
-- Shows time in multiple timezones

-- 1. Configuration of timezones (name, UTC offset, flag)
local timezones = {
  { name = 'New York', offset = -5, flag = '🇺🇸' },
  { name = 'London',   offset = 0,  flag = '🇬🇧' },
  { name = 'Tokyo',    offset = 9,  flag = '🇯🇵' },
  { name = 'Sydney',   offset = 11, flag = '🇦🇺' },
  { name = 'Dubai',    offset = 4,  flag = '🇦🇪' },
}

-- 2. Get current local and UTC time
local local_time = os.date('%H:%M')
local utc_time = os.time(os.date('!*t')) -- Get current UTC timestamp

-- 3. Main status bar display
print("🌍 " .. local_time)
print("---")
print("World Clock")
print("---")

-- 4. Iterate and display time for each timezone
for _, tz in ipairs(timezones) do
    -- Calculate the time in the target timezone by adding the offset
    local target_timestamp = utc_time + (tz.offset * 3600)
    -- Format the timestamp into HH:MM
    local tz_time = os.date('%H:%M', target_timestamp)
    print(string.format("%s %s: %s", tz.flag, tz.name, tz_time))
end

-- 5. Footer
print("---")
print("Refresh | refresh=true")
