#!/usr/bin/env python3
"""Countdown Timer - Shows time remaining to a target date"""
import os
from datetime import datetime

# Configure target date via env var (format: YYYY-MM-DD HH:MM:SS)
target_str = os.environ.get('CROSSBAR_COUNTDOWN_TARGET', '2025-12-31 23:59:59')

try:
    target = datetime.strptime(target_str, '%Y-%m-%d %H:%M:%S')
    now = datetime.now()
    diff = target - now

    if diff.total_seconds() <= 0:
        print(" Done!")
        print("---")
        print("Countdown completed!")
    else:
        days = diff.days
        hours, remainder = divmod(diff.seconds, 3600)
        minutes, seconds = divmod(remainder, 60)

        if days > 0:
            display = f"{days}d {hours}h"
        elif hours > 0:
            display = f"{hours}h {minutes}m"
        else:
            display = f"{minutes}m {seconds}s"

        print(f" {display}")
        print("---")
        print(f"Target: {target_str}")
        print(f"Days: {days}")
        print(f"Hours: {hours}")
        print(f"Minutes: {minutes}")
        print(f"Seconds: {seconds}")
except Exception as e:
    print(f" Error | color=red")
    print("---")
    print(f"Error: {e}")
    print("Set CROSSBAR_COUNTDOWN_TARGET env var")
    print("Format: YYYY-MM-DD HH:MM:SS")

print("---")
print("Refresh | refresh=true")
