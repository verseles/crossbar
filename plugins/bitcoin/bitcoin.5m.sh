#!/bin/bash
# Bitcoin Price Plugin - Uses curl for HTTP requests

# Use curl
response=$(curl -s "https://api.coinbase.com/v2/prices/BTC-USD/spot")

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
