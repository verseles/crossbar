#!/usr/bin/env python3
"""Clock Plugin - Shows current time using Crossbar API"""
import subprocess
from datetime import datetime

def crossbar(*args):
    """Execute crossbar command and return output"""
    try:
        result = subprocess.run(['crossbar'] + list(args), capture_output=True, text=True, timeout=5)
        return result.stdout.strip() if result.returncode == 0 else None
    except Exception:
        return None

# Get time from Crossbar API or fallback to Python
time_str = crossbar('time') or datetime.now().strftime('%H:%M:%S')
date_str = crossbar('date') or datetime.now().strftime('%Y-%m-%d')

print(f"🕐 {time_str}")
print("---")
print(f"Time: {time_str}")
print(f"Date: {date_str}")
print("---")
print("Refresh | refresh=true")
