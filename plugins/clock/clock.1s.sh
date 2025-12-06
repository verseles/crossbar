#!/bin/bash
# Clock Plugin - Shows current time
# Uses Crossbar API for portability

time=$(crossbar --time 2>/dev/null || date +%H:%M:%S)

echo "🕐 $time"
echo "---"
echo "Time: $time"
echo "Date: $(crossbar --time --format date 2>/dev/null || date +%Y-%m-%d)"
echo "Timezone: $(crossbar --timezone 2>/dev/null || date +%Z)"
echo "---"
echo "Refresh | refresh=true"
