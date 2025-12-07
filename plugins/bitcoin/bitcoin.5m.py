#!/usr/bin/env python3
"""Bitcoin Price Plugin - Uses Crossbar web API"""
import subprocess
import json

def crossbar_web(url):
    """Execute crossbar web command"""
    try:
        result = subprocess.run(['crossbar', 'web', url], capture_output=True, text=True, timeout=10)
        if result.returncode == 0:
            return result.stdout.strip()
    except Exception:
        pass
    return None

# Try Crossbar API first
response = crossbar_web('api.coinbase.com/v2/prices/BTC-USD/spot')

# Fallback to urllib
if not response:
    import urllib.request
    try:
        with urllib.request.urlopen('https://api.coinbase.com/v2/prices/BTC-USD/spot', timeout=10) as r:
            response = r.read().decode()
    except Exception:
        pass

if response:
    try:
        data = json.loads(response)
        price = data.get('data', {}).get('amount', '--')
        
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
else:
    print("₿ Error")
    print("---")
    print("Failed to fetch price")

print("---")
print("Refresh | refresh=true")
