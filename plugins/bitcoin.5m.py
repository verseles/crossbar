#!/usr/bin/env python3
"""Bitcoin Price - Shows current BTC price"""
import json
import urllib.request

def get_btc_price():
    try:
        url = "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd&include_24hr_change=true"
        with urllib.request.urlopen(url, timeout=5) as response:
            data = json.loads(response.read().decode())
            price = data['bitcoin']['usd']
            change = data['bitcoin'].get('usd_24h_change', 0)
            return price, change
    except Exception as e:
        return None, str(e)

price, change = get_btc_price()

if price is None:
    print(f" N/A | color=gray")
    print("---")
    print(f"Error: {change}")
else:
    icon = '' if change >= 0 else ''
    color = 'green' if change >= 0 else 'red'
    change_str = f"+{change:.2f}" if change >= 0 else f"{change:.2f}"

    print(f" ${price:,.0f} | color={color}")
    print("---")
    print(f"Bitcoin (BTC)")
    print(f"Price: ${price:,.2f}")
    print(f"24h Change: {change_str}% {icon}")
    print("---")
    print("Open CoinGecko | href=https://www.coingecko.com/en/coins/bitcoin")

print("---")
print("Refresh | refresh=true")
