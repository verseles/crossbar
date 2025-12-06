#!/bin/bash
# CPU Monitor Plugin - Uses Crossbar API for portability

cpu=$(crossbar --cpu 2>/dev/null)

# Fallback if crossbar not available
if [ -z "$cpu" ]; then
    cpu=$(top -bn1 2>/dev/null | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1 || echo "0")
fi

# Determine color based on usage
if [ "$(echo "$cpu > 80" | bc -l 2>/dev/null)" = "1" ]; then
    color="red"
elif [ "$(echo "$cpu > 50" | bc -l 2>/dev/null)" = "1" ]; then
    color="yellow"
else
    color="green"
fi

echo "⚡ ${cpu}% | color=$color"
echo "---"
echo "CPU Usage: ${cpu}%"
echo "---"
echo "Refresh | refresh=true"
