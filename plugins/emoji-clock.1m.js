#!/usr/bin/env node
/**
 * Emoji Clock - Shows time as emoji clock face
 */

const clockEmojis = {
  '12': '🕛', '12:30': '🕧',
  '1': '🕐', '1:30': '🕜',
  '2': '🕑', '2:30': '🕝',
  '3': '🕒', '3:30': '🕞',
  '4': '🕓', '4:30': '🕟',
  '5': '🕔', '5:30': '🕠',
  '6': '🕕', '6:30': '🕡',
  '7': '🕖', '7:30': '🕢',
  '8': '🕗', '8:30': '🕣',
  '9': '🕘', '9:30': '🕤',
  '10': '🕙', '10:30': '🕥',
  '11': '🕚', '11:30': '🕦',
};

const now = new Date();
let hour = now.getHours() % 12 || 12;
const minute = now.getMinutes();

// Round to nearest clock face
let key = hour.toString();
if (minute >= 15 && minute < 45) {
  key = `${hour}:30`;
}

const emoji = clockEmojis[key] || '🕐';
const timeStr = now.toLocaleTimeString('en-US', {
  hour: '2-digit',
  minute: '2-digit',
  hour12: true
});

console.log(`${emoji} ${timeStr}`);
console.log('---');
console.log(`Time: ${timeStr}`);
console.log(`Date: ${now.toLocaleDateString()}`);
console.log(`Day: ${now.toLocaleDateString('en-US', { weekday: 'long' })}`);
console.log('---');
console.log('Refresh | refresh=true');
