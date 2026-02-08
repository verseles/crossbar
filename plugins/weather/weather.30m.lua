-- weather.30m.lua
-- Weather plugin in Lua using Crossbar web (OpenWeather)

local function env(name, default)
    local value = crossbar.env(name, default)
    if value == nil or value == '' then
        return default
    end
    return value
end

local api_key = env('WEATHER_API_KEY', '')
local city = env('WEATHER_CITY', 'London')
local units = env('WEATHER_UNITS', 'metric')
if units ~= 'metric' and units ~= 'imperial' then
    units = 'metric'
end

if api_key == '' then
    print('WX No API Key | color=gray')
    print('---')
    print('Set WEATHER_API_KEY')
    print('---')
    print('Refresh | refresh=true')
    return
end

-- Parse comma-separated multiselect into a set
local show_fields_raw = env('WEATHER_SHOW_FIELDS', 'description')
local show_fields = {}
for field in show_fields_raw:gmatch('[^,]+') do
    local trimmed = field:gsub('^%s+', ''):gsub('%s+$', '')
    if trimmed ~= '' then
        show_fields[trimmed] = true
    end
end

local city_encoded = city:gsub(' ', '%%20')
local url = 'https://api.openweathermap.org/data/2.5/weather?q=' .. city_encoded .. '&appid=' .. api_key .. '&units=' .. units
local response, err = crossbar.web(url)
if response == nil then
    print('WX Error | color=red')
    print('---')
    print(err or 'Failed to fetch data')
    return
end

if response.error or (response.status and response.status >= 400) then
    print('WX Error | color=red')
    print('---')
    print(response.message or ('HTTP ' .. tostring(response.status)))
    return
end

local data = response.data
if type(data) == 'string' then
    data = crossbar.jsonDecode(data)
end

local temp = nil
local desc = nil
local humidity = nil
local pressure = nil
local feels_like = nil
local wind_speed = nil
if type(data) == 'table' then
    if type(data.main) == 'table' then
        temp = tonumber(data.main.temp)
        humidity = tonumber(data.main.humidity)
        pressure = tonumber(data.main.pressure)
        feels_like = tonumber(data.main.feels_like)
    end
    if type(data.weather) == 'table' and type(data.weather[1]) == 'table' then
        desc = data.weather[1].description
    end
    if type(data.wind) == 'table' then
        wind_speed = tonumber(data.wind.speed)
    end
end

if temp == nil then
    print('WX -- | color=gray')
    print('---')
    print('Invalid response')
    return
end

local unit_symbol = units == 'imperial' and 'F' or 'C'
print('WX ' .. tostring(temp) .. '°' .. unit_symbol)
print('---')
print('Location: ' .. city)
print('Temperature: ' .. tostring(temp) .. '°' .. unit_symbol)
if show_fields['description'] and desc and desc ~= '' then
    print('Condition: ' .. desc)
end
if show_fields['feels_like'] and feels_like then
    print('Feels Like: ' .. tostring(feels_like) .. '°' .. unit_symbol)
end
if show_fields['humidity'] and humidity then
    print('Humidity: ' .. tostring(humidity) .. '%')
end
if show_fields['wind'] and wind_speed then
    local wind_unit = units == 'imperial' and 'mph' or 'm/s'
    print('Wind: ' .. tostring(wind_speed) .. ' ' .. wind_unit)
end
if show_fields['pressure'] and pressure then
    print('Pressure: ' .. tostring(pressure) .. ' hPa')
end
print('---')
print('OpenWeather | href=https://openweathermap.org/find?q=' .. city_encoded)
print('Refresh | refresh=true')
