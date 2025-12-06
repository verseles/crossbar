#!/bin/bash
# Battery Monitor Plugin - Uses Crossbar API for portability

battery=$(crossbar --battery 2>/dev/null)

# Fallback if crossbar not available
if [ -z "$battery" ]; then
    battery=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1 || echo "N/A")
fi

# Check charging status
charging=$(crossbar --battery --json 2>/dev/null | grep -o '"charging":true' || cat /sys/class/power_supply/BAT*/status 2>/dev/null | grep -qi "charging" && echo "true" || echo "false")

# Icon and color based on level
if [ "$battery" = "N/A" ]; then
    icon="🔋"
    color="gray"
elif [ "$charging" = "true" ]; then
    icon="🔌"
    color="blue"
elif [ "$battery" -lt 20 ]; then
    icon="🪫"
    color="red"
elif [ "$battery" -lt 50 ]; then
    icon="🔋"
    color="yellow"
else
    icon="🔋"
    color="green"
fi

echo "$icon ${battery}% | color=$color"
echo "---"
echo "Battery: ${battery}%"
[ "$charging" = "true" ] && echo "Status: Charging ⚡"
echo "---"
echo "Refresh | refresh=true"
