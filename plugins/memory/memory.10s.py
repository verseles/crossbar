#!/usr/bin/env python3
"""Memory Monitor Plugin - Uses Crossbar API for portability"""
import subprocess

def crossbar(cmd):
    try:
        result = subprocess.run(['crossbar'] + cmd.split(), capture_output=True, text=True, timeout=5)
        return result.stdout.strip() if result.returncode == 0 else None
    except Exception:
        return None

memory_str = crossbar('--memory')

if not memory_str:
    try:
        import psutil
        memory_str = str(int(psutil.virtual_memory().percent))
    except ImportError:
        memory_str = "N/A"

try:
    memory = int(memory_str.replace('%', ''))
    if memory > 80:
        color = "red"
    elif memory > 60:
        color = "yellow"
    else:
        color = "green"
except ValueError:
    color = "gray"

print(f"🧠 {memory_str}% | color={color}")
print("---")
print(f"Memory Usage: {memory_str}%")
print("---")
print("Refresh | refresh=true")
