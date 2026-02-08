#!/bin/bash
# ip-info.1h.sh

# Requires curl
DATA=$(curl -s https://ipinfo.io/json)

if [ -z "$DATA" ]; then
    echo "🌐 N/A | color=gray"
    echo "---"
    echo "Error fetching IP info"
    exit 0
fi

# Simple parsing with grep/sed (avoiding jq dependency if possible, but jq is better)
IP=$(echo "$DATA" | grep -o '"ip": *"[^"]*"' | cut -d'"' -f4)
CITY=$(echo "$DATA" | grep -o '"city": *"[^"]*"' | cut -d'"' -f4)
COUNTRY=$(echo "$DATA" | grep -o '"country": *"[^"]*"' | cut -d'"' -f4)

echo "🌐 $IP"
echo "---"
echo "IP: $IP"
echo "City: $CITY"
echo "Country: $COUNTRY"
echo "---"
echo "Copy IP | bash='echo -n $IP | pbcopy' terminal=false"
echo "---"
echo "Refresh | refresh=true"
