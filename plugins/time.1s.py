#!/usr/bin/env python3
"""Time Plugin - Shows current time"""
from datetime import datetime

now = datetime.now()
time_str = now.strftime("%H:%M:%S")
date_str = now.strftime("%Y-%m-%d")
day_name = now.strftime("%A")

print(f" {time_str}")
print("---")
print(f"Time: {time_str}")
print(f"Date: {date_str}")
print(f"Day: {day_name}")
print("---")
print("Refresh | refresh=true")
