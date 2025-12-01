#!/usr/bin/env node
/**
 * NPM Downloads - Shows download count for a package
 */
const https = require('https');

const PACKAGE = process.env.CROSSBAR_NPM_PACKAGE || 'lodash';

function fetchDownloads(pkg) {
  return new Promise((resolve, reject) => {
    const url = `https://api.npmjs.org/downloads/point/last-week/${pkg}`;
    https.get(url, (res) => {
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
    const data = await fetchDownloads(PACKAGE);
    const downloads = data.downloads || 0;
    const formatted = downloads.toLocaleString();

    console.log(`📦 ${formatted}`);
    console.log('---');
    console.log(`Package: ${PACKAGE}`);
    console.log(`Weekly Downloads: ${formatted}`);
    console.log('---');
    console.log(`Open NPM | href=https://www.npmjs.com/package/${PACKAGE}`);
  } catch (e) {
    console.log('📦 N/A | color=gray');
    console.log('---');
    console.log(`Error: ${e.message}`);
  }

  console.log('---');
  console.log('Refresh | refresh=true');
}

main();
