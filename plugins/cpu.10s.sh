#!/bin/bash
# CPU Usage Monitor
# Shows current CPU usage percentage

cpu=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1 2>/dev/null || echo "0")
if [ -z "$cpu" ] || [ "$cpu" = "0" ]; then
    cpu=$(vmstat 1 2 | tail -1 | awk '{print 100-$15}' 2>/dev/null || echo "0")
fi

icon=""
if (( $(echo "$cpu > 80" | bc -l 2>/dev/null || echo 0) )); then
    color="red"
elif (( $(echo "$cpu > 50" | bc -l 2>/dev/null || echo 0) )); then
    color="yellow"
else
    color="green"
fi

echo "$icon ${cpu}% | color=$color"
echo "---"
echo "CPU Usage: ${cpu}%"
echo "Refresh | refresh=true"
