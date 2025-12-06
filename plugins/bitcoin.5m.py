#!/usr/bin/env python3
"""Bitcoin/Crypto Price - Shows current cryptocurrency price

Configure via Crossbar settings or environment variables:
- CROSSBAR_PLUGIN_CURRENCY: Display currency (usd, eur, gbp, brl, jpy)
- CROSSBAR_PLUGIN_CRYPTO: Coin to track (bitcoin, ethereum, solana, cardano)
"""
import json
import urllib.request
import os

# Configuration from Crossbar settings
CURRENCY = os.environ.get('CROSSBAR_PLUGIN_CURRENCY', 'usd')
CRYPTO = os.environ.get('CROSSBAR_PLUGIN_CRYPTO', 'bitcoin')

# Currency symbols
SYMBOLS = {'usd': '$', 'eur': '€', 'gbp': '£', 'brl': 'R$', 'jpy': '¥'}
CRYPTO_NAMES = {'bitcoin': 'BTC', 'ethereum': 'ETH', 'solana': 'SOL', 'cardano': 'ADA'}

def get_crypto_price():
    try:
        url = f"https://api.coingecko.com/api/v3/simple/price?ids={CRYPTO}&vs_currencies={CURRENCY}&include_24hr_change=true"
        with urllib.request.urlopen(url, timeout=5) as response:
            data = json.loads(response.read().decode())
            price = data[CRYPTO][CURRENCY]
            change = data[CRYPTO].get(f'{CURRENCY}_24h_change', 0)
            return price, change
    except Exception as e:
        return None, str(e)

price, change = get_crypto_price()
symbol = SYMBOLS.get(CURRENCY, '$')
crypto_name = CRYPTO_NAMES.get(CRYPTO, CRYPTO.upper())

if price is None:
    print(f"₿ N/A | color=gray")
    print("---")
    print(f"Error: {change}")
else:
    icon = '' if change >= 0 else ''
    color = 'green' if change >= 0 else 'red'
    change_str = f"+{change:.2f}" if change >= 0 else f"{change:.2f}"

    print(f"₿ {symbol}{price:,.0f} | color={color}")
    print("---")
    print(f"{CRYPTO.title()} ({crypto_name})")
    print(f"Price: {symbol}{price:,.2f}")
    print(f"24h Change: {change_str}% {icon}")
    print("---")
    print(f"Open CoinGecko | href=https://www.coingecko.com/en/coins/{CRYPTO}")

print("---")
print("Refresh | refresh=true")

