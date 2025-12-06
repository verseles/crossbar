#!/usr/bin/env node
/**
 * Battery Monitor Plugin - Uses Crossbar API for portability
 */
const { execSync } = require('child_process');

function crossbar(...args) {
    try {
        return execSync(`crossbar ${args.join(' ')}`, { encoding: 'utf8', timeout: 5000 }).trim();
    } catch {
        return null;
    }
}

let batteryStr = crossbar('battery') || 'N/A';
let charging = false;

const jsonStr = crossbar('battery', '--json');
if (jsonStr) {
    try {
        const data = JSON.parse(jsonStr);
        charging = data.charging || false;
    } catch {}
}

const battery = parseInt(batteryStr) || 0;
let icon, color;

if (charging) {
    icon = '🔌'; color = 'blue';
} else if (battery < 20) {
    icon = '🪫'; color = 'red';
} else if (battery < 50) {
    icon = '🔋'; color = 'yellow';
} else {
    icon = '🔋'; color = 'green';
}

console.log(`${icon} ${batteryStr}% | color=${color}`);
console.log('---');
console.log(`Battery: ${batteryStr}%`);
if (charging) console.log('Status: Charging ⚡');
console.log('---');
console.log('Refresh | refresh=true');
