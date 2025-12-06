#!/usr/bin/env node
/**
 * Bitcoin Price Plugin - Uses Crossbar API for HTTP requests
 */
const { execSync } = require('child_process');

function crossbar(args) {
    try {
        return execSync(`crossbar ${args.join(' ')}`, { encoding: 'utf8', timeout: 10000 }).trim();
    } catch {
        return null;
    }
}

const url = 'https://api.coinbase.com/v2/prices/BTC-USD/spot';
const response = crossbar(['--web', `"${url}"`, '--json']);

if (!response) {
    console.log('₿ Error');
    console.log('---');
    console.log('Failed to fetch price');
    process.exit(0);
}

try {
    const data = JSON.parse(response);
    const price = data.data?.amount || '--';
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
