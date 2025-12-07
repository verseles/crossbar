#!/usr/bin/env python3
"""Bitcoin/Crypto Price - Shows current cryptocurrency price

Configure via Crossbar settings or environment variables:
- CROSSBAR_PLUGIN_CURRENCY: Display currency (usd, eur, gbp, brl, jpy)
- CROSSBAR_PLUGIN_CRYPTO: Coin to track (bitcoin, ethereum, solana, cardano)
"""
import json
import os
import subprocess # Add subprocess for calling crossbar CLI

# Configuration from Crossbar settings
CURRENCY = os.environ.get('CROSSBAR_PLUGIN_CURRENCY', 'usd')
CRYPTO = os.environ.get('CROSSBAR_PLUGIN_CRYPTO', 'bitcoin')

# Currency symbols
SYMBOLS = {'usd': '$', 'eur': '€', 'gbp': '£', 'brl': 'R$', 'jpy': '¥'}
CRYPTO_NAMES = {'bitcoin': 'BTC', 'ethereum': 'ETH', 'solana': 'SOL', 'cardano': 'ADA'}

def get_crypto_price():
    try:
        url = f"https://api.coingecko.com/api/v3/simple/price?ids={CRYPTO}&vs_currencies={CURRENCY}&include_24hr_change=true"
        result = subprocess.run(
            ['crossbar', 'web', url, '--json'],
            capture_output=True,
            text=True,
            check=True
        )
        data = json.loads(result.stdout)
        price = data[CRYPTO][CURRENCY]
        change = data[CRYPTO].get(f'{CURRENCY}_24h_change', 0)
        return price, change
    except subprocess.CalledProcessError as e:
        return None, f"Crossbar web command failed: {e.stderr.strip()}"
    except json.JSONDecodeError as e:
        return None, f"Failed to parse JSON response: {e}"
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

