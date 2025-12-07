#!/bin/bash
# Battery Status
# Shows battery level and charging state

# Use Crossbar CLI API to get battery status
battery_info=$(crossbar battery) # Example: "87% ⚡" or "50%"

battery_level=$(echo "$battery_info" | grep -oE '[0-9]+' | head -1) # Extract percentage
battery_status="?"
battery_icon="" # Unknown icon

if echo "$battery_info" | grep -q "⚡"; then
    battery_status="charging"
elif [ "$battery_level" == "100" ]; then
    battery_status="full"
else
    battery_status="discharging"
fi

if [ "$battery" = "N/A" ]; then
    echo " N/A"
    exit 0
fi

if [ "$charging" = "true" ]; then
    icon=""
    color="blue"
elif [ "$battery" -le 20 ]; then
    icon=""
    color="red"
elif [ "$battery" -le 50 ]; then
    icon=""
    color="yellow"
else
    icon=""
    color="green"
fi

echo "$icon ${battery}% | color=$color"
echo "---"
echo "Battery: ${battery}%"
[ "$charging" = "true" ] && echo "Status: Charging" || echo "Status: Discharging"
echo "---"
echo "Refresh | refresh=true"
