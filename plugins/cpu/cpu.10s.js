#!/usr/bin/env node
/**
 * CPU Monitor Plugin - Uses Crossbar API for portability
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

// Get CPU from Crossbar API
let cpuStr = crossbar('--cpu');

// Fallback to Node.js os module
if (!cpuStr) {
    const cpus = os.cpus();
    const total = cpus.reduce((acc, cpu) => {
        const times = cpu.times;
        return acc + times.user + times.nice + times.sys + times.idle + times.irq;
    }, 0);
    const idle = cpus.reduce((acc, cpu) => acc + cpu.times.idle, 0);
    cpuStr = ((1 - idle / total) * 100).toFixed(1);
}

const cpu = parseFloat(cpuStr) || 0;
let color = 'green';
if (cpu > 80) color = 'red';
else if (cpu > 50) color = 'yellow';

console.log(`⚡ ${cpuStr}% | color=${color}`);
console.log('---');
console.log(`CPU Usage: ${cpuStr}%`);
console.log('---');
console.log('Refresh | refresh=true');
