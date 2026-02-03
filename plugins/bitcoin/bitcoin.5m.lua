-- bitcoin.5m.lua
-- Crypto price tracker using Crossbar CLI (CoinGecko)

local function env(name, default)
    local value = crossbar.env(name, default)
    if value == nil or value == '' then
        return default
    end
    return value
end

local is_mobile = crossbar.isMobile()
if is_mobile then
    print('₿ N/A | color=gray')
    print('---')
    print('Crypto prices via CLI are limited on mobile')
    print('---')
    print('Refresh | refresh=true')
    return
end

local crypto = env('CRYPTO_ID', 'bitcoin')
local currency = env('CRYPTO_CURRENCY', 'usd')

local url = 'https://api.coingecko.com/api/v3/simple/price?ids=' .. crypto .. '&vs_currencies=' .. currency .. '&include_24hr_change=true'
local response, err = crossbar.web(url)
if response == nil then
    print('₿ -- | color=gray')
    print('---')
    print(err or 'Failed to fetch price')
    print('---')
    print('Refresh | refresh=true')
    return
end

if response.error or (response.status and response.status >= 400) then
    print('₿ -- | color=gray')
    print('---')
    print(response.message or ('HTTP ' .. tostring(response.status)))
    print('---')
    print('Refresh | refresh=true')
    return
end

local data = response.data
local price = nil
local change = nil
if type(data) == 'table' and type(data[crypto]) == 'table' then
    local coin = data[crypto]
    price = tonumber(coin[currency])
    change = tonumber(coin[currency .. '_24h_change'])
end

if price == nil then
    print('₿ -- | color=gray')
    print('---')
    print('Failed to fetch price')
    print('---')
    print('Refresh | refresh=true')
    return
end

local color = 'gray'
local change_text = '0.0%'
if change ~= nil then
    if change > 0 then color = 'green' end
    if change < 0 then color = 'red' end
    change_text = string.format('%.2f%%', change)
end

print('₿ ' .. tostring(price) .. ' | color=' .. color)
print('---')
print('Asset: ' .. crypto)
print('Currency: ' .. currency)
if change ~= nil then
    local sign = change > 0 and '+' or ''
    print('24h Change: ' .. sign .. change_text)
end
print('---')
print('Open CoinGecko | href=https://www.coingecko.com')
print('Refresh | refresh=true')
