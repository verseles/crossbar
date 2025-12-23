#!/bin/bash
# site-check.1m.sh

URL="https://www.google.com"
STATUS=$(curl -o /dev/null -s -w "% {http_code}\n" "$URL")

if [ "$STATUS" -ge 200 ] && [ "$STATUS" -lt 300 ]; then
    echo "✅ Up ($STATUS) | color=green"
else
    echo "❌ Down ($STATUS) | color=red"
fi

echo "---"
echo "Site: $URL"
echo "Refresh | refresh=true"

