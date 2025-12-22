#!/bin/bash
# uptime.1m.sh
# System uptime monitor using Crossbar CLI API

UPTIME=$(crossbar uptime)

if [ $? -eq 0 ] && [ -n "$UPTIME" ]; then
    echo "⬆️ $UPTIME"
    echo "---"
    echo "System Uptime: $UPTIME"
    echo "Refresh | refresh=true"
else
    echo "⬆️ --"
    echo "---"
    echo "Unable to get uptime"
fi