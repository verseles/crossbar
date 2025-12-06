#!/usr/bin/env node
/**
 * Weather Plugin - Uses https for HTTP requests
 */
const https = require('https');

const API_KEY = process.env.WEATHER_API_KEY || '';
const CITY = process.env.WEATHER_CITY || 'London';

if (!API_KEY) {
    console.log('🌡️ No API Key');
    console.log('---');
    console.log('Set WEATHER_API_KEY');
    process.exit(0);
}

const url = `https://api.openweathermap.org/data/2.5/weather?q=${CITY}&appid=${API_KEY}&units=metric`;

https.get(url, (res) => {
    let data = '';
    res.on('data', (chunk) => data += chunk);
    res.on('end', () => {
        try {
            const json = JSON.parse(data);
            const temp = json.main?.temp || '--';
            const desc = json.weather?.[0]?.description || '';
            
            console.log(`🌡️ ${temp}°C`);
            console.log('---');
            console.log(`Location: ${CITY}`);
            console.log(`Temperature: ${temp}°C`);
            console.log(`Condition: ${desc}`);
        } catch {
            console.log('🌡️ Parse Error');
        }
        console.log('---');
        console.log('Refresh | refresh=true');
    });
}).on('error', () => {
    console.log('🌡️ Error');
    console.log('---');
    console.log('Failed to fetch data');
});
