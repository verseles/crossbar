#!/usr/bin/env node
/**
 * Clock Plugin - Shows current time using Crossbar API
 */
const { execSync } = require('child_process');

function crossbar(cmd) {
    try {
        return execSync(`crossbar ${cmd}`, { encoding: 'utf8', timeout: 5000 }).trim();
    } catch {
        return null;
    }
}

const now = new Date();
const timeStr = crossbar('--time') || now.toLocaleTimeString('en-GB');
const dateStr = crossbar('--time --format date') || now.toISOString().split('T')[0];
const tz = crossbar('--timezone') || Intl.DateTimeFormat().resolvedOptions().timeZone;

console.log(`🕐 ${timeStr}`);
console.log('---');
console.log(`Time: ${timeStr}`);
console.log(`Date: ${dateStr}`);
console.log(`Timezone: ${tz}`);
console.log('---');
console.log('Refresh | refresh=true');
