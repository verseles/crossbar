#!/usr/bin/env node
/**
 * Memory Monitor Plugin - Uses Crossbar API for portability
 */
const { execSync } = require('child_process');
const os = require('os');

function crossbar(cmd) {
    try {
        return execSync(`crossbar ${cmd}`, { encoding: 'utf8', timeout: 5000 }).trim();
    } catch {
        return null;
    }
}

let memoryStr = crossbar('--memory');

if (!memoryStr) {
    const total = os.totalmem();
    const free = os.freemem();
    const percent = Math.round(((total - free) / total) * 100);
    memoryStr = percent.toString();
}

const memory = parseInt(memoryStr) || 0;
let color = 'green';
if (memory > 80) color = 'red';
else if (memory > 60) color = 'yellow';

console.log(`🧠 ${memoryStr}% | color=${color}`);
console.log('---');
console.log(`Memory Usage: ${memoryStr}%`);
console.log('---');
console.log('Refresh | refresh=true');
