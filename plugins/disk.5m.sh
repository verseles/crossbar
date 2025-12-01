#!/bin/bash
# Disk Usage Monitor
# Shows root partition usage

usage=$(df -h / | awk 'NR==2 {print $5}' | tr -d '%')
used=$(df -h / | awk 'NR==2 {print $3}')
total=$(df -h / | awk 'NR==2 {print $2}')

if [ "$usage" -gt 90 ]; then
    color="red"
    icon=""
elif [ "$usage" -gt 70 ]; then
    color="yellow"
    icon=""
else
    color="green"
    icon=""
fi

echo "$icon ${usage}% | color=$color"
echo "---"
echo "Used: $used / $total"
echo "---"
echo "Open Disk Utility | bash='open -a \"Disk Utility\"' terminal=false"
echo "Refresh | refresh=true"
