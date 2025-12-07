#!/usr/bin/env python3
"""Weather Plugin - Uses Crossbar web API"""
import subprocess
import json
import os

def crossbar_web(url):
    """Execute crossbar web command"""
    try:
        result = subprocess.run(['crossbar', 'web', url], capture_output=True, text=True, timeout=10)
        if result.returncode == 0:
            return result.stdout.strip()
    except Exception:
        pass
    return None

API_KEY = os.environ.get('WEATHER_API_KEY', '')
CITY = os.environ.get('WEATHER_CITY', 'London')

if not API_KEY:
    print("🌡️ No API Key")
    print("---")
    print("Set WEATHER_API_KEY")
    exit(0)

url = f"api.openweathermap.org/data/2.5/weather?q={CITY}&appid={API_KEY}&units=metric"

# Try Crossbar web first
response = crossbar_web(url)

# Fallback to urllib
if not response:
    import urllib.request
    try:
        with urllib.request.urlopen(f"https://{url}", timeout=10) as r:
            response = r.read().decode()
    except Exception:
        pass

if response:
    try:
        data = json.loads(response)
        temp = data.get('main', {}).get('temp', '--')
        desc = data.get('weather', [{}])[0].get('description', '')
        
        print(f"🌡️ {temp}°C")
        print("---")
        print(f"Location: {CITY}")
        print(f"Temperature: {temp}°C")
        print(f"Condition: {desc}")
    except json.JSONDecodeError:
        print("🌡️ Parse Error")
else:
    print("🌡️ Error")
    print("---")
    print("Failed to fetch weather data")

print("---")
print("Refresh | refresh=true")
