#!/bin/bash
# battery.30s.sh
# Battery monitor using Crossbar CLI API

# Get battery data in JSON format
BAT_JSON=$(crossbar battery --json)

if [ $? -ne 0 ] || [ -z "$BAT_JSON" ]; then
    echo "🔋 --"
    echo "---"
    echo "Error fetching battery info"
    exit 1
fi

# Extract values using simple string manipulation (portable alternative to jq)
LEVEL=$(echo "$BAT_JSON" | grep -oP '"level":\s*\K\d+')
CHARGING=$(echo "$BAT_JSON" | grep -oP '"charging":\s*\K\w+')

if [ -z "$LEVEL" ]; then
    echo "🔋 --"
    echo "---"
    echo "No battery detected"
    exit 0
fi

ICON="🔋"
COLOR="green"

if [ "$CHARGING" = "true" ]; then
    ICON="⚡"
    COLOR="blue"
elif [ "$LEVEL" -le 20 ]; then
    ICON="🪫"
    COLOR="red"
elif [ "$LEVEL" -le 50 ]; then
    COLOR="yellow"
fi

echo "$ICON $LEVEL% | color=$COLOR"
echo "---"
echo "Battery Level: $LEVEL%"
if [ "$CHARGING" = "true" ]; then
    echo "Status: Charging"
else
    echo "Status: Discharging"
fi
echo "---"
echo "Refresh | refresh=true"