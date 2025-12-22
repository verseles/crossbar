#!/usr/bin/env python3
# battery.30s.py
import subprocess
import json
import sys

def get_battery():
    try:
        res = subprocess.run(['crossbar', 'battery', '--json'], capture_output=True, text=True, timeout=5)
        if res.returncode == 0:
            return json.loads(res.stdout)
    except: pass
    return None

data = get_battery()
if not data or data.get('level') is None:
    print("🔋 --")
    print("---")
    print("No battery detected")
    sys.exit(0)

level = data['level']
charging = data.get('charging', False)

icon, color = "🔋", "green"
if charging:
    icon, color = "⚡", "blue"
elif level <= 20:
    icon, color = "🪫", "red"
elif level <= 50:
    color = "yellow"

print(f"{icon} {level}% | color={color}")
print("---")
print(f"Battery Level: {level}%")
print(f"Status: {'Charging' if charging else 'Discharging'}")
print("---")
print("Refresh | refresh=true")