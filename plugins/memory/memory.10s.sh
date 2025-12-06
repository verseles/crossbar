#!/bin/bash
# Memory Monitor Plugin - Uses Crossbar API for portability

memory=$(crossbar --memory 2>/dev/null)

# Fallback if crossbar not available
if [ -z "$memory" ]; then
    total=$(grep MemTotal /proc/meminfo 2>/dev/null | awk '{print $2}')
    avail=$(grep MemAvailable /proc/meminfo 2>/dev/null | awk '{print $2}')
    if [ -n "$total" ] && [ -n "$avail" ]; then
        used=$((total - avail))
        percent=$((used * 100 / total))
        memory="$percent"
    else
        memory="N/A"
    fi
fi

# Determine color
if [ "$memory" != "N/A" ]; then
    if [ "$memory" -gt 80 ]; then
        color="red"
    elif [ "$memory" -gt 60 ]; then
        color="yellow"
    else
        color="green"
    fi
else
    color="gray"
fi

echo "🧠 ${memory}% | color=$color"
echo "---"
echo "Memory Usage: ${memory}%"
echo "---"
echo "Refresh | refresh=true"
