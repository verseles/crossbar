#!/usr/bin/env python3
"""Bitcoin Price Plugin - Uses urllib for HTTP requests"""
import urllib.request
import json

url = "https://api.coinbase.com/v2/prices/BTC-USD/spot"

try:
    with urllib.request.urlopen(url, timeout=10) as response:
        data = json.loads(response.read().decode())
        price = data.get('data', {}).get('amount', '--')
        
        # Format with thousands separator
        try:
            formatted = f"{float(price):,.0f}"
        except (ValueError, TypeError):
            formatted = price
        
        print(f"₿ ${formatted}")
        print("---")
        print(f"BTC/USD: ${price}")
        print("Source: Coinbase")
except Exception:
    print("₿ Error")
    print("---")
    print("Failed to fetch price")

print("---")
print("Refresh | refresh=true")
