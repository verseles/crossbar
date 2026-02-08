#!/bin/bash
# Clock Plugin - Shows current time using Crossbar API

time=$(crossbar time 2>/dev/null || date +%H:%M:%S)
date_str=$(crossbar date 2>/dev/null || date +%Y-%m-%d)

echo "🕐 $time"
echo "---"
echo "Time: $time"
echo "Date: $date_str"
echo "---"
echo "Refresh | refresh=true"
