#!/bin/bash
# quotes.1h.sh

QUOTE_DATA=$(curl -s https://api.quotable.io/random)

if [ -z "$QUOTE_DATA" ]; then
    echo " Quote Error"
    exit 0
fi

# Parsing JSON in bash without jq is hard, use regex
CONTENT=$(echo "$QUOTE_DATA" | grep -o '"content":"[^"]*"' | sed 's/"content":"//;s/"$//')
AUTHOR=$(echo "$QUOTE_DATA" | grep -o '"author":"[^"]*"' | sed 's/"author":"//;s/"$//')

DISPLAY=${CONTENT:0:40}
[ ${#CONTENT} -gt 40 ] && DISPLAY="$DISPLAY..."

echo " $DISPLAY"
echo "---"
echo "\"$CONTENT\""
echo "  - $AUTHOR"
echo "---"
echo "Refresh | refresh=true"
