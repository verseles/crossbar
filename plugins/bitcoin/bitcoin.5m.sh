#!/bin/bash
# Bitcoin Price Plugin - Uses Crossbar API for HTTP requests

# Use Crossbar web API - no API key needed for Coinbase
response=$(crossbar --web "https://api.coinbase.com/v2/prices/BTC-USD/spot" --json 2>/dev/null)

if [ -z "$response" ]; then
    echo "₿ Error"
    echo "---"
    echo "Failed to fetch price"
    exit 0
fi

price=$(echo "$response" | grep -oP '"amount":\s*"\K[0-9.]+' | head -1)

if [ -n "$price" ]; then
    # Format price with comma separator
    formatted=$(printf "%'.0f" "${price%.*}" 2>/dev/null || echo "$price")
    echo "₿ \$${formatted}"
    echo "---"
    echo "BTC/USD: \$${price}"
    echo "Source: Coinbase"
else
    echo "₿ --"
fi
echo "---"
echo "Refresh | refresh=true"
