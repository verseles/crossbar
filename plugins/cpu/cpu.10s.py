#!/usr/bin/env python3
"""CPU Monitor Plugin - Uses Crossbar API for portability"""
import subprocess

def crossbar(cmd):
    try:
        result = subprocess.run(['crossbar'] + cmd.split(), capture_output=True, text=True, timeout=5)
        return result.stdout.strip() if result.returncode == 0 else None
    except Exception:
        return None

# Get CPU from Crossbar API
cpu_str = crossbar('--cpu')

# Fallback to psutil if available
if not cpu_str:
    try:
        import psutil
        cpu_str = str(round(psutil.cpu_percent(interval=0.1), 1))
    except ImportError:
        cpu_str = "N/A"

try:
    cpu = float(cpu_str)
    if cpu > 80:
        color = "red"
    elif cpu > 50:
        color = "yellow"
    else:
        color = "green"
except ValueError:
    cpu = 0
    color = "gray"

print(f"⚡ {cpu_str}% | color={color}")
print("---")
print(f"CPU Usage: {cpu_str}%")
print("---")
print("Refresh | refresh=true")
