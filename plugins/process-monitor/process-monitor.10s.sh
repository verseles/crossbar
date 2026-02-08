#!/bin/bash
# process-monitor.10s.sh

if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    CMD="ps aux | sort -nrk 3 | head -6 | tail -5"
else
    # Linux
    CMD="ps aux --sort=-%cpu | head -6 | tail -5"
fi

TOTAL=$(ps aux | wc -l)
TOTAL=$((TOTAL - 1))

echo " $TOTAL"
echo "---"
echo "Running Processes: $TOTAL"
echo "---"
echo "Top by CPU:"

eval "$CMD" | while read -r line; do
    # Extract fields. awk is good here.
    CPU=$(echo "$line" | awk '{print $3}')
    COMMAND=$(echo "$line" | awk '{$1=$2=$3=$4=$5=$6=$7=$8=$9=$10=""; print $0}' | xargs)
    COMMAND=${COMMAND:0:30}
    
    COLOR="green"
    # Floating point comparison in bash requires bc or hack
    if (( $(echo "$CPU > 50" | bc -l 2>/dev/null || echo 0) )); then
        COLOR="red"
    elif (( $(echo "$CPU > 20" | bc -l 2>/dev/null || echo 0) )); then
        COLOR="yellow"
    fi
    
    echo "  $CPU% $COMMAND | color=$COLOR"
done

echo "---"
echo "Refresh | refresh=true"
