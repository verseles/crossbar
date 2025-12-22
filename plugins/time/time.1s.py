#!/usr/bin/env python3
"""Time Plugin - Shows current time"""
import subprocess
import json
import os # For CROSSBAR_OS if needed, not directly used here

# Get current time using crossbar CLI
time_output = subprocess.run(['crossbar', 'time'], capture_output=True, text=True).stdout.strip()
current_time = time_output

# Try to extract hour for icon/color logic
current_hour = -1
try:
    # Assuming crossbar time returns HH:MM or HH:MM:SS
    parts = current_time.split(':')
    if len(parts) > 0:
        current_hour = int(parts[0])
except ValueError:
    pass # Keep current_hour as -1 if parsing fails

icon=""
color="white" # Default color

if current_hour >= 6 and current_hour < 12:
    icon="☀️" # Morning
    color="blue"
elif current_hour >= 12 and current_hour < 18:
    icon=" दोपहर" # Afternoon
    color="green"
elif current_hour >= 18 and current_hour < 22:
    icon="🌆" # Evening
    color="orange"
else:
    icon="🌙" # Night
    color="purple"

print(f"{icon} {current_time} | color={color}")
print("---")
print(f"Current Time: {current_time}")

# Get current date using crossbar CLI
date_output = subprocess.run(['crossbar', 'date'], capture_output=True, text=True).stdout.strip()
print(f"Current Date: {date_output}")
print("---")
print("Refresh | refresh=true")
