#!/bin/bash
# CPU Usage Monitor
# Shows current CPU usage percentage

cpu=$(crossbar cpu 2>/dev/null) # Use the Crossbar CLI API to get CPU usage

if [ -z "$cpu" ]; then
    # Fallback using top if crossbar is not available
    if command -v top >/dev/null 2>&1; then
        if [ "$(uname)" = "Darwin" ]; then
            cpu=$(top -l 1 | grep "CPU usage" | awk '{print $3}' | sed 's/%//')
        else
            cpu=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
        fi
    else
        cpu="N/A"
    fi
fi

icon="⚡"

if [ "$cpu" = "N/A" ]; then
    color="gray"
else
    if (( $(echo "$cpu > 80" | bc -l 2>/dev/null || echo 0) )); then
        color="red"
    elif (( $(echo "$cpu > 50" | bc -l 2>/dev/null || echo 0) )); then
        color="yellow"
    else
        color="green"
    fi
fi

echo "$icon ${cpu}% | color=$color"
echo "---"
echo "CPU Usage: ${cpu}%"
echo "Refresh | refresh=true"
