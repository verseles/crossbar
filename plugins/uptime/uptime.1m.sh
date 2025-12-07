#!/bin/bash
# System Uptime
# Shows how long the system has been running

uptime_output=$(crossbar uptime)
icon="⬆️"

echo "$icon $uptime_output | size=12"
echo "---"
echo "Refresh | refresh=true"
