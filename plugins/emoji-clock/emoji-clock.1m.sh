#!/bin/bash
# emoji-clock.1m.sh

HOUR=$(date +%I) # 01-12
MIN=$(date +%M)
AMPM=$(date +%p)

# Remove leading zero
HOUR=$((10#$HOUR))
MIN=$((10#$MIN))

# Determine half-hour
if [ $MIN -ge 15 ] && [ $MIN -lt 45 ]; then
    KEY="${HOUR}:30"
else
    KEY="$HOUR"
fi

# Simple mapping (associative arrays are bash 4+, trying to be compatible)
case "$KEY" in
    "12") EMOJI="🕛";; "12:30") EMOJI="🕧";;
    "1") EMOJI="🕐";; "1:30") EMOJI="🕜";;
    "2") EMOJI="🕑";; "2:30") EMOJI="🕝";;
    "3") EMOJI="🕒";; "3:30") EMOJI="🕞";;
    "4") EMOJI="🕓";; "4:30") EMOJI="🕟";;
    "5") EMOJI="🕔";; "5:30") EMOJI="🕠";;
    "6") EMOJI="🕕";; "6:30") EMOJI="🕡";;
    "7") EMOJI="🕖";; "7:30") EMOJI="🕢";;
    "8") EMOJI="🕗";; "8:30") EMOJI="🕣";;
    "9") EMOJI="🕘";; "9:30") EMOJI="🕤";;
    "10") EMOJI="🕙";; "10:30") EMOJI="🕥";;
    "11") EMOJI="🕚";; "11:30") EMOJI="🕦";;
    *) EMOJI="🕒";;
esac

TIME_STR=$(date '+%I:%M %p')

echo "$EMOJI $TIME_STR"
echo "---"
echo "Time: $TIME_STR"
echo "Date: $(date '+%Y-%m-%d')"
echo "---"
echo "Refresh | refresh=true"
