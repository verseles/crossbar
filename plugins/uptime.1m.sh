#!/bin/bash
# System Uptime
# Shows how long the system has been running

uptime_str=$(uptime | awk -F'up ' '{print $2}' | awk -F',' '{print $1}')

echo " $uptime_str"
echo "---"
echo "Uptime: $uptime_str"
echo "---"
echo "Refresh | refresh=true"
