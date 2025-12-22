#!/usr/bin/env node
/**
 * World Clock - Shows time in multiple timezones
 */

const timezones = [
  { name: 'New York', offset: -5, flag: '🇺🇸' },
  { name: 'London', offset: 0, flag: '🇬🇧' },
  { name: 'Tokyo', offset: 9, flag: '🇯🇵' },
  { name: 'Sydney', offset: 11, flag: '🇦🇺' },
  { name: 'Dubai', offset: 4, flag: '🇦🇪' },
];

function getTimeInTimezone(offset) {
  const now = new Date();
  const utc = now.getTime() + (now.getTimezoneOffset() * 60000);
  const time = new Date(utc + (3600000 * offset));
  return time.toLocaleTimeString('en-US', {
    hour: '2-digit',
    minute: '2-digit',
    hour12: false
  });
}

const localTime = new Date().toLocaleTimeString('en-US', {
  hour: '2-digit',
  minute: '2-digit',
  hour12: false
});

console.log(`🌍 ${localTime}`);
console.log('---');
console.log('World Clock');
console.log('---');

for (const tz of timezones) {
  const time = getTimeInTimezone(tz.offset);
  console.log(`${tz.flag} ${tz.name}: ${time}`);
}

console.log('---');
console.log('Refresh | refresh=true');
