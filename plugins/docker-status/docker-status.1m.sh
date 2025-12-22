#!/bin/bash
# Docker Status - Shows running container count
# Works with both docker and podman

RUNTIME="docker"
which podman > /dev/null 2>&1 && RUNTIME="podman"

containers=$($RUNTIME ps -q 2>/dev/null | wc -l | tr -d ' ')
if [ "$containers" = "" ]; then
    containers="0"
fi

if [ "$containers" -eq 0 ]; then
    icon=""
    color="gray"
else
    icon=""
    color="blue"
fi

echo "$icon $containers | color=$color"
echo "---"
echo "Running Containers: $containers"
echo "---"

if [ "$containers" -gt 0 ]; then
    echo "Containers:"
    $RUNTIME ps --format "{{.Names}}: {{.Status}}" 2>/dev/null | while read line; do
        echo "  $line"
    done
    echo "---"
fi

echo "Stop All | bash='$RUNTIME stop \$($RUNTIME ps -q)' terminal=false"
echo "Refresh | refresh=true"
