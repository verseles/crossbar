#!/usr/bin/env node
/**
 * Weather Plugin - Uses Crossbar API for HTTP requests
 */
const { execSync } = require('child_process');

function crossbar(args) {
    try {
        return execSync(`crossbar ${args.join(' ')}`, { encoding: 'utf8', timeout: 10000 }).trim();
    } catch {
        return null;
    }
}

const API_KEY = process.env.WEATHER_API_KEY || '';
const CITY = process.env.WEATHER_CITY || 'London';

if (!API_KEY) {
    console.log('🌡️ No API Key');
    console.log('---');
    console.log('Set WEATHER_API_KEY in configuration');
    process.exit(0);
}

const url = `https://api.openweathermap.org/data/2.5/weather?q=${CITY}&appid=${API_KEY}&units=metric`;
const response = crossbar(['--web', `"${url}"`, '--json']);

if (!response) {
    console.log('🌡️ Error');
    console.log('---');
    console.log('Failed to fetch weather data');
    process.exit(0);
}

try {
    const data = JSON.parse(response);
    const temp = data.main?.temp || '--';
    const desc = data.weather?.[0]?.description || '';
    
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
