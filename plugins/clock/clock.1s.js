#!/usr/bin/env node
/**
 * Clock Plugin - Shows current time using Crossbar API
 */
const { execSync } = require('child_process');

function crossbar(...args) {
    try {
        return execSync(`crossbar ${args.join(' ')}`, { encoding: 'utf8', timeout: 5000 }).trim();
    } catch {
        return null;
    }
}

const now = new Date();
const timeStr = crossbar('time') || now.toLocaleTimeString('en-GB');
const dateStr = crossbar('date') || now.toISOString().split('T')[0];

console.log(`🕐 ${timeStr}`);
console.log('---');
console.log(`Time: ${timeStr}`);
console.log(`Date: ${dateStr}`);
console.log('---');
console.log('Refresh | refresh=true');
