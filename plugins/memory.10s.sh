#!/bin/bash
# Memory Usage Monitor
# Shows RAM usage

if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    mem=$(vm_stat | awk '/Pages active/ {active=$3} /Pages wired/ {wired=$4} END {print int((active+wired)*4096/1024/1024/1024*10)/10}')
    total=$(sysctl -n hw.memsize | awk '{print int($1/1024/1024/1024)}')
else
    # Linux
    read -r total used <<< $(free -g | awk '/Mem:/ {print $2, $3}')
    mem=$used
fi

percent=$(echo "scale=0; $mem * 100 / $total" | bc 2>/dev/null || echo "0")

if [ "$percent" -gt 80 ]; then
    color="red"
elif [ "$percent" -gt 50 ]; then
    color="yellow"
else
    color="green"
fi

echo " ${mem}/${total}GB | color=$color"
echo "---"
echo "Used: ${mem}GB"
echo "Total: ${total}GB"
echo "Usage: ${percent}%"
echo "---"
echo "Refresh | refresh=true"
