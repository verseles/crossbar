#!/usr/bin/env node
/**
 * Bitcoin Price Plugin - Uses Crossbar web API
 */
const { execSync } = require('child_process');
const https = require('https');

function crossbarWeb(url) {
    try {
        return execSync(`crossbar web ${url}`, { encoding: 'utf8', timeout: 10000 }).trim();
    } catch {
        return null;
    }
}

// Try Crossbar API first
let response = crossbarWeb('api.coinbase.com/v2/prices/BTC-USD/spot');

if (response) {
    try {
        const data = JSON.parse(response);
        const price = data.data?.amount || '--';
        const formatted = parseFloat(price).toLocaleString('en-US', { maximumFractionDigits: 0 });
        
        console.log(`₿ $${formatted}`);
        console.log('---');
        console.log(`BTC/USD: $${price}`);
        console.log('Source: Coinbase');
        console.log('---');
        console.log('Refresh | refresh=true');
    } catch {
        console.log('₿ Parse Error');
    }
} else {
    // Fallback to native https
    https.get('https://api.coinbase.com/v2/prices/BTC-USD/spot', (res) => {
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
}
