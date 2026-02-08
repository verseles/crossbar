#!/bin/bash
# countdown.1s.sh
# Countdown Timer in Bash

TARGET="${CROSSBAR_COUNTDOWN_TARGET:-2025-12-31 23:59:59}"

# Try to get timestamp in a cross-platform way
if date -d "2025-01-01" >/dev/null 2>&1; then
    # GNU date
    TARGET_SEC=$(date -d "$TARGET" +%s)
    NOW_SEC=$(date +%s)
else
    # BSD date (macOS)
    TARGET_SEC=$(date -j -f "%Y-%m-%d %H:%M:%S" "$TARGET" +%s 2>/dev/null)
    NOW_SEC=$(date +%s)
fi

if [ -z "$TARGET_SEC" ]; then
    echo "! | color=red"
    echo "---"
    echo "Error: Invalid date format"
    echo "Set CROSSBAR_COUNTDOWN_TARGET"
    echo "Format: YYYY-MM-DD HH:MM:SS"
    exit 1
fi

DIFF=$((TARGET_SEC - NOW_SEC))

if [ $DIFF -le 0 ]; then
    echo "Done!"
    echo "---"
    echo "Countdown complete!"
else
    DAYS=$((DIFF / 86400))
    REMAINDER=$((DIFF % 86400))
    HOURS=$((REMAINDER / 3600))
    REMAINDER=$((REMAINDER % 3600))
    MINS=$((REMAINDER / 60))
    SECS=$((REMAINDER % 60))

    if [ $DAYS -gt 0 ]; then
        DISPLAY="${DAYS}d ${HOURS}h"
    elif [ $HOURS -gt 0 ]; then
        DISPLAY="${HOURS}h ${MINS}m"
    else
        DISPLAY="${MINS}m ${SECS}s"
    fi

    echo "⏳ $DISPLAY"
    echo "---"
    echo "Target: $TARGET"
fi

echo "---"
echo "Refresh | refresh=true"
