#!/bin/bash
# SSH Connections - Shows active SSH connections

connections=$(who | grep -c "pts" 2>/dev/null || echo "0")
ssh_procs=$(pgrep -c sshd 2>/dev/null || echo "0")

if [ "$connections" -gt 0 ]; then
    icon=""
    color="orange"
else
    icon=""
    color="green"
fi

echo "$icon $connections | color=$color"
echo "---"
echo "Active Sessions: $connections"
echo "SSH Processes: $ssh_procs"
echo "---"

if [ "$connections" -gt 0 ]; then
    echo "Connected:"
    who | grep "pts" | while read line; do
        echo "  $line"
    done
fi

echo "---"
echo "Refresh | refresh=true"
