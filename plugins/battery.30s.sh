#!/bin/bash
# Battery Status
# Shows battery level and charging state

if [[ "$OSTYPE" == "darwin"* ]]; then
    battery=$(pmset -g batt | grep -Eo "\d+%" | head -1 | tr -d '%')
    charging=$(pmset -g batt | grep -q "AC Power" && echo "true" || echo "false")
else
    battery=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1 || echo "N/A")
    charging=$(cat /sys/class/power_supply/BAT*/status 2>/dev/null | grep -qi "charging" && echo "true" || echo "false")
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
