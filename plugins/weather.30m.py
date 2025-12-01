#!/usr/bin/env python3
"""Weather Plugin - Shows current weather"""
import json
import urllib.request
import os

# Configure your city here or use CITY env var
CITY = os.environ.get('CROSSBAR_WEATHER_CITY', 'London')

def get_weather():
    try:
        url = f"https://wttr.in/{CITY}?format=j1"
        with urllib.request.urlopen(url, timeout=5) as response:
            data = json.loads(response.read().decode())
            current = data['current_condition'][0]
            temp = current['temp_C']
            desc = current['weatherDesc'][0]['value']
            humidity = current['humidity']

            # Weather icons based on condition
            if 'sun' in desc.lower() or 'clear' in desc.lower():
                icon = ''
            elif 'cloud' in desc.lower():
                icon = ''
            elif 'rain' in desc.lower():
                icon = ''
            elif 'snow' in desc.lower():
                icon = ''
            else:
                icon = ''

            return {
                'icon': icon,
                'temp': temp,
                'desc': desc,
                'humidity': humidity,
                'city': CITY
            }
    except Exception as e:
        return {'error': str(e)}

weather = get_weather()

if 'error' in weather:
    print(f" N/A | color=gray")
    print("---")
    print(f"Error: {weather['error']}")
else:
    print(f"{weather['icon']} {weather['temp']}C")
    print("---")
    print(f"Location: {weather['city']}")
    print(f"Condition: {weather['desc']}")
    print(f"Temperature: {weather['temp']}C")
    print(f"Humidity: {weather['humidity']}%")
    print("---")
    print("Refresh | refresh=true")
