#!/bin/bash
# npm-downloads.1h.sh

PACKAGE="${CROSSBAR_NPM_PACKAGE:-lodash}"
URL="https://api.npmjs.org/downloads/point/last-week/$PACKAGE"

DATA=$(curl -s "$URL")
DOWNLOADS=$(echo "$DATA" | grep -o '"downloads": *[0-9]*' | awk -F': ' '{print $2}')

if [ -z "$DOWNLOADS" ]; then
    echo "📦 N/A | color=gray"
    echo "---"
    echo "Error fetching data"
else
    # Format number with commas (Linux/BSD compatible usually requires printf or sed)
    FORMATTED=$(printf "%'d" $DOWNLOADS)
    
    echo "📦 $FORMATTED"
    echo "---"
    echo "Package: $PACKAGE"
    echo "Weekly Downloads: $FORMATTED"
    echo "---"
    echo "Open NPM | href=https://www.npmjs.com/package/$PACKAGE"
fi

echo "---"
echo "Refresh | refresh=true"
