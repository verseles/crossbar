#!/bin/bash
# world-clock.1m.sh

# Dependencies: requires GNU date for TZ support easily
# macOS 'date' is different. Using TZ variable is portable.

# Helper function
get_time() {
    TZ="$1" date +'%H:%M'
}

LOCAL_TIME=$(date +'%H:%M')

echo "🌍 $LOCAL_TIME"
echo "---"
echo "World Clock"
echo "---"

# Define zones manually
echo "🇺🇸 New York: $(get_time 'America/New_York')"
echo "🇬🇧 London: $(get_time 'Europe/London')"
echo "🇯🇵 Tokyo: $(get_time 'Asia/Tokyo')"
echo "🇦🇺 Sydney: $(get_time 'Australia/Sydney')"
echo "🇦🇪 Dubai: $(get_time 'Asia/Dubai')"

echo "---"
echo "Refresh | refresh=true"
