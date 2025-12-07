#!/bin/bash
# CPU Usage Monitor
# Shows current CPU usage percentage

cpu=$(crossbar cpu) # Use the Crossbar CLI API to get CPU usage

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
