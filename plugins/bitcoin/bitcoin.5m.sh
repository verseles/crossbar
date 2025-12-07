#!/bin/bash
# Bitcoin Price Plugin - Uses Crossbar web API

response=$(crossbar web api.coinbase.com/v2/prices/BTC-USD/spot 2>/dev/null)

# Fallback to curl if crossbar fails
if [ -z "$response" ]; then
    response=$(curl -s "https://api.coinbase.com/v2/prices/BTC-USD/spot")
fi

if [ -z "$response" ]; then
    echo "₿ Error"
    echo "---"
    echo "Failed to fetch price"
    exit 0
fi

price=$(echo "$response" | grep -oP '"amount":\s*"\K[0-9.]+' | head -1)

if [ -n "$price" ]; then
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
