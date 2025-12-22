#!/bin/bash
# Disk Usage Monitor
# Shows root partition usage

disk_info=$(crossbar disk /) # Example: "8.2/16.0 GB"

# Extract used and total size, then calculate percentage
# Ensure 'bc -l' is used for floating point arithmetic if awk cannot handle it well,
# or for more precision. Here, we'll assume the output format for disk is reliable
# and calculate percentage.
read -r used_size_gb total_size_gb <<< $(echo "$disk_info" | sed 's/GB//g' | awk -F'/' '{print $1, $2}')
# Use bc for floating point arithmetic
used_percent=$(echo "scale=0; ($used_size_gb / $total_size_gb) * 100" | bc)

icon=""
color="green"

echo "$icon ${usage}% | color=$color"
echo "---"
echo "Used: $used / $total"
echo "---"
echo "Open Disk Utility | bash='open -a \"Disk Utility\"' terminal=false"
echo "Refresh | refresh=true"
