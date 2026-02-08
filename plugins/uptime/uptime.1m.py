#!/usr/bin/env python3
# uptime.1m.py
import subprocess
import sys

def get_uptime():
    try:
        res = subprocess.run(['crossbar', 'uptime'], capture_output=True, text=True, timeout=5)
        if res.returncode == 0:
            return res.stdout.strip()
    except: pass
    return None

uptime = get_uptime()
if uptime:
    print(f"⬆️ {uptime}")
    print("---")
    print(f"System Uptime: {uptime}")
    print("Refresh | refresh=true")
else:
    print("⬆️ --")
    print("---")
    print("Unable to get uptime")