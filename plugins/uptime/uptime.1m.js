#!/usr/bin/env node
const { execSync } = require('child_process');

try {
  const uptime = execSync('crossbar uptime').toString().trim();
  console.log(`⬆️ ${uptime} | size=12`);
  console.log("---");
  console.log("Refresh | refresh=true");
} catch (error) {
  console.log("⬆️ Error");
}
