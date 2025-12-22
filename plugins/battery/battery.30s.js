#!/usr/bin/env node
// battery.30s.js
const { execSync } = require('child_process');

function getBattery() {
    try {
        const out = execSync('crossbar battery --json', { encoding: 'utf8', timeout: 5000 });
        return JSON.parse(out);
    } catch { return null; }
}

const data = getBattery();
if (!data || data.level === undefined || data.level === null) {
    console.log("🔋 --");
    console.log("---");
    console.log("No battery detected");
    process.exit(0);
}

const { level, charging } = data;
let icon = "🔋", color = "green";

if (charging) {
    icon = "⚡"; color = "blue";
} else if (level <= 20) {
    icon = "🪫"; color = "red";
} else if (level <= 50) {
    color = "yellow";
}

console.log(`${icon} ${level}% | color=${color}`);
console.log("---");
console.log(`Battery Level: ${level}%`);
console.log(`Status: ${charging ? 'Charging' : 'Discharging'}`);
console.log("---");
console.log("Refresh | refresh=true");