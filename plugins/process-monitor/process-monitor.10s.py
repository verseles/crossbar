#!/usr/bin/env python3
"""Process Monitor - Shows top CPU/Memory processes"""
import subprocess
import platform

def get_top_processes():
    try:
        if platform.system() == 'Darwin':
            # macOS
            cmd = "ps aux | sort -nrk 3 | head -6 | tail -5"
        else:
            # Linux
            cmd = "ps aux --sort=-%cpu | head -6 | tail -5"

        result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        lines = result.stdout.strip().split('\n')

        processes = []
        for line in lines:
            parts = line.split()
            if len(parts) >= 11:
                cpu = parts[2]
                mem = parts[3]
                cmd = ' '.join(parts[10:])[:30]
                processes.append({'cpu': cpu, 'mem': mem, 'cmd': cmd})

        return processes
    except:
        return []

processes = get_top_processes()
total_processes = subprocess.run(['sh', '-c', 'ps aux | wc -l'], capture_output=True, text=True)
count = int(total_processes.stdout.strip()) - 1

print(f" {count}")
print("---")
print(f"Running Processes: {count}")
print("---")
print("Top by CPU:")

for p in processes:
    cpu = float(p['cpu'])
    color = 'red' if cpu > 50 else 'yellow' if cpu > 20 else 'green'
    print(f"  {p['cpu']}% {p['cmd']} | color={color}")

print("---")
print("Open Activity Monitor | bash='open -a \"Activity Monitor\"' terminal=false")
print("Refresh | refresh=true")
