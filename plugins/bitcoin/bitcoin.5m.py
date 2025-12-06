#!/usr/bin/env python3
"""Bitcoin Price Plugin - Uses Crossbar API for HTTP requests"""
import subprocess
import json

def crossbar(cmd):
    try:
        result = subprocess.run(['crossbar'] + cmd, capture_output=True, text=True, timeout=10)
        return result.stdout.strip() if result.returncode == 0 else None
    except Exception:
        return None

url = "https://api.coinbase.com/v2/prices/BTC-USD/spot"
response = crossbar(['--web', url, '--json'])

if not response:
    print("₿ Error")
    print("---")
    print("Failed to fetch price")
    exit(0)

try:
    data = json.loads(response)
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
except json.JSONDecodeError:
    print("₿ Parse Error")

print("---")
print("Refresh | refresh=true")
