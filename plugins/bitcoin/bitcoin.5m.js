#!/usr/bin/env node
/**
 * Bitcoin Price Plugin - Uses https for HTTP requests
 */
const https = require('https');

const url = 'https://api.coinbase.com/v2/prices/BTC-USD/spot';

https.get(url, (res) => {
    let data = '';
    res.on('data', (chunk) => data += chunk);
    res.on('end', () => {
        try {
            const json = JSON.parse(data);
            const price = json.data?.amount || '--';
            const formatted = parseFloat(price).toLocaleString('en-US', { maximumFractionDigits: 0 });
            
            console.log(`₿ $${formatted}`);
            console.log('---');
            console.log(`BTC/USD: $${price}`);
            console.log('Source: Coinbase');
        } catch {
            console.log('₿ Parse Error');
        }
        console.log('---');
        console.log('Refresh | refresh=true');
    });
}).on('error', () => {
    console.log('₿ Error');
    console.log('---');
    console.log('Failed to fetch price');
});
