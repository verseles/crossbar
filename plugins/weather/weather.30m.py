#!/usr/bin/env python3
"""Weather Plugin - Uses urllib for HTTP requests"""
import urllib.request
import json
import os

API_KEY = os.environ.get('WEATHER_API_KEY', '')
CITY = os.environ.get('WEATHER_CITY', 'London')

if not API_KEY:
    print("🌡️ No API Key")
    print("---")
    print("Set WEATHER_API_KEY")
    exit(0)

url = f"https://api.openweathermap.org/data/2.5/weather?q={CITY}&appid={API_KEY}&units=metric"

try:
    with urllib.request.urlopen(url, timeout=10) as response:
        data = json.loads(response.read().decode())
        temp = data.get('main', {}).get('temp', '--')
        desc = data.get('weather', [{}])[0].get('description', '')
        
        print(f"🌡️ {temp}°C")
        print("---")
        print(f"Location: {CITY}")
        print(f"Temperature: {temp}°C")
        print(f"Condition: {desc}")
except Exception:
    print("🌡️ Error")
    print("---")
    print("Failed to fetch weather data")

print("---")
print("Refresh | refresh=true")
