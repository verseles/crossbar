-- emoji-clock.1m.lua
-- Shows time as an emoji clock face

-- 1. Emoji mapping table
local clock_emojis = {
  ['12'] = '🕛', ['12:30'] = '🕧',
  ['1'] = '🕐', ['1:30'] = '🕜',
  ['2'] = '🕑', ['2:30'] = '🕝',
  ['3'] = '🕒', ['3:30'] = '🕞',
  ['4'] = '🕓', ['4:30'] = '🕟',
  ['5'] = '🕔', ['5:30'] = '🕠',
  ['6'] = '🕕', ['6:30'] = '🕡',
  ['7'] = '🕖', ['7:30'] = '🕢',
  ['8'] = '🕗', ['8:30'] = '🕣',
  ['9'] = '🕘', ['9:30'] = '🕤',
  ['10'] = '🕙', ['10:30'] = '🕥',
  ['11'] = '🕚', ['11:30'] = '🕦'
}

-- 2. Get current time
local now = os.date('*t')
local hour_24 = now.hour
local min = now.min

-- 3. Convert 24-hour to 12-hour format
local hour_12 = hour_24 % 12
if hour_12 == 0 then
    hour_12 = 12
end

-- 4. Determine the emoji key by rounding to the nearest half-hour
local key = tostring(hour_12)
if min >= 15 and min < 45 then
    -- It's closer to the half-hour mark
    key = tostring(hour_12) .. ":30"
end

-- 5. Get the emoji and format the time string
local emoji = clock_emojis[key]
local time_str = os.date('%I:%M %p')

-- 6. Print the output
print(emoji .. " " .. time_str)
print("---")
print("Time: " .. time_str)
print("Date: " .. os.date('%Y-%m-%d'))
print("---")
print("Refresh | refresh=true")
