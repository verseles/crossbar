#!/usr/bin/env python3
import subprocess
import sys

def get_uptime():
    try:
        result = subprocess.run(['crossbar', 'uptime'], capture_output=True, text=True)
        return result.stdout.strip()
    except Exception:
        return "Unknown"

uptime = get_uptime()
print(f"⬆️ {uptime} | size=12")
print("---")
print("Refresh | refresh=true")
