#!/usr/bin/env node
/**
 * IP Info - Shows public IP and location info
 */
const https = require('https');

function fetchIpInfo() {
  return new Promise((resolve, reject) => {
    https.get('https://ipinfo.io/json', (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          resolve(JSON.parse(data));
        } catch (e) {
          reject(e);
        }
      });
    }).on('error', reject);
  });
}

async function main() {
  try {
    const info = await fetchIpInfo();

    console.log(`🌐 ${info.ip}`);
    console.log('---');
    console.log(`IP: ${info.ip}`);
    console.log(`City: ${info.city || 'N/A'}`);
    console.log(`Region: ${info.region || 'N/A'}`);
    console.log(`Country: ${info.country || 'N/A'}`);
    console.log(`ISP: ${info.org || 'N/A'}`);
    console.log(`Timezone: ${info.timezone || 'N/A'}`);
    console.log('---');
    console.log('Copy IP | bash=\'echo "' + info.ip + '" | pbcopy\' terminal=false');
  } catch (e) {
    console.log('🌐 N/A | color=gray');
    console.log('---');
    console.log(`Error: ${e.message}`);
  }

  console.log('---');
  console.log('Refresh | refresh=true');
}

main();
