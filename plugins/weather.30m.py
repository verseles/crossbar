#!/usr/bin/env python3
"""Weather Plugin - Shows current weather

Configure via Crossbar settings or environment variables:
- CROSSBAR_PLUGIN_WEATHER_CITY: City name (default: London)
- CROSSBAR_PLUGIN_UNITS: celsius or fahrenheit (default: celsius)
"""
import json
import urllib.request
import urllib.parse
import os

# Configuration from Crossbar settings (injected as env vars)
CITY = os.environ.get('CROSSBAR_PLUGIN_WEATHER_CITY', os.environ.get('CROSSBAR_WEATHER_CITY', 'London'))
UNITS = os.environ.get('CROSSBAR_PLUGIN_UNITS', 'celsius')

def get_weather():
    try:
        encoded_city = urllib.parse.quote(CITY)
        url = f"https://wttr.in/{encoded_city}?format=j1"
        with urllib.request.urlopen(url, timeout=5) as response:
            data = json.loads(response.read().decode())
            current = data['current_condition'][0]
            
            # Get temp based on units preference
            if UNITS == 'fahrenheit':
                temp = current['temp_F']
                unit = 'F'
            else:
                temp = current['temp_C']
                unit = 'C'
            
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
                'unit': unit,
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
    print(f"{weather['icon']} {weather['temp']}°{weather['unit']}")
    print("---")
    print(f"Location: {weather['city']}")
    print(f"Condition: {weather['desc']}")
    print(f"Temperature: {weather['temp']}°{weather['unit']}")
    print(f"Humidity: {weather['humidity']}%")
    print("---")
    print("Refresh | refresh=true")

