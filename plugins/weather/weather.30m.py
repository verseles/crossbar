#!/usr/bin/env python3
"""Weather Plugin - Uses Crossbar API for HTTP requests"""
import subprocess
import json
import os

def crossbar(cmd):
    try:
        result = subprocess.run(['crossbar'] + cmd, capture_output=True, text=True, timeout=10)
        return result.stdout.strip() if result.returncode == 0 else None
    except Exception:
        return None

API_KEY = os.environ.get('WEATHER_API_KEY', '')
CITY = os.environ.get('WEATHER_CITY', 'London')

if not API_KEY:
    print("🌡️ No API Key")
    print("---")
    print("Set WEATHER_API_KEY in configuration")
    exit(0)

url = f"https://api.openweathermap.org/data/2.5/weather?q={CITY}&appid={API_KEY}&units=metric"
response = crossbar(['--web', url, '--json'])

if not response:
    print("🌡️ Error")
    print("---")
    print("Failed to fetch weather data")
    exit(0)

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

print("---")
print("Refresh | refresh=true")
