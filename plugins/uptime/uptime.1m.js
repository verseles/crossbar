#!/usr/bin/env node
// uptime.1m.js
const { execSync } = require('child_process');

function getUptime() {
    try {
        return execSync('crossbar uptime', { encoding: 'utf8', timeout: 5000 }).trim();
    } catch { return null; }
}

const uptime = getUptime();
if (uptime) {
    console.log(`⬆️ ${uptime}`);
    console.log("---");
    console.log(`System Uptime: ${uptime}`);
    console.log("Refresh | refresh=true");
} else {
    console.log("⬆️ --");
    console.log("---");
    console.log("Unable to get uptime");
}