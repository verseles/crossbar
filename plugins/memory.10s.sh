#!/bin/bash
# Memory Usage Monitor
# Shows RAM usage

memory_info=$(crossbar memory) # Example: "8.2/16.0 GB"

# Extract used and total size, then calculate percentage
read -r used_mem_gb total_mem_gb <<< $(echo "$memory_info" | sed 's/GB//g' | awk -F'/' '{print $1, $2}')
used_percent=$(echo "scale=0; ($used_mem_gb / $total_mem_gb) * 100" | bc)

icon=""
color="green"

echo " ${mem}/${total}GB | color=$color"
echo "---"
echo "Used: ${mem}GB"
echo "Total: ${total}GB"
echo "Usage: ${percent}%"
echo "---"
echo "Refresh | refresh=true"
