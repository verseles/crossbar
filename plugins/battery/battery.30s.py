#!/usr/bin/env python3
"""Battery Monitor Plugin - Uses Crossbar API for portability"""
import subprocess
import json

def crossbar(*args):
    try:
        result = subprocess.run(['crossbar'] + list(args), capture_output=True, text=True, timeout=5)
        return result.stdout.strip() if result.returncode == 0 else None
    except Exception:
        return None

# Get battery from Crossbar API
battery_str = crossbar('battery')
battery_json = crossbar('battery', '--json')

charging = False
if battery_json:
    try:
        data = json.loads(battery_json)
        charging = data.get('charging', False)
    except json.JSONDecodeError:
        pass

# Fallback
if not battery_str:
    try:
        import psutil
        batt = psutil.sensors_battery()
        if batt:
            battery_str = str(int(batt.percent))
            charging = batt.power_plugged
    except ImportError:
        battery_str = "N/A"

try:
    battery = int(battery_str)
except (ValueError, TypeError):
    battery = 0

# Icon and color
if charging:
    icon, color = "🔌", "blue"
elif battery < 20:
    icon, color = "🪫", "red"
elif battery < 50:
    icon, color = "🔋", "yellow"
else:
    icon, color = "🔋", "green"

print(f"{icon} {battery_str}% | color={color}")
print("---")
print(f"Battery: {battery_str}%")
if charging:
    print("Status: Charging ⚡")
print("---")
print("Refresh | refresh=true")
