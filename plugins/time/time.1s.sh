#!/bin/bash
# time.1s.sh

HOUR=$(date +%H)
TIME_STR=$(date '+%H:%M:%S')
DATE_STR=$(date '+%Y-%m-%d')

if [ $HOUR -ge 6 ] && [ $HOUR -lt 12 ]; then
    ICON="☀️"
    COLOR="lightblue"
elif [ $HOUR -ge 12 ] && [ $HOUR -lt 18 ]; then
    ICON="🏙️"
    COLOR="lightgreen"
elif [ $HOUR -ge 18 ] && [ $HOUR -lt 22 ]; then
    ICON="🌆"
    COLOR="orange"
else
    ICON="🌙"
    COLOR="purple"
fi

echo "$ICON $TIME_STR | color=$COLOR"
echo "---"
echo "Time: $TIME_STR"
echo "Date: $DATE_STR"
echo "---"
echo "Refresh | refresh=true"
