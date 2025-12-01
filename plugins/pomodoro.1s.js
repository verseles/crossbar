#!/usr/bin/env node
/**
 * Pomodoro Timer - Focus timer with work/break cycles
 */
const fs = require('fs');
const path = require('path');
const os = require('os');

const STATE_FILE = path.join(os.homedir(), '.crossbar', 'pomodoro.json');

const WORK_DURATION = 25 * 60; // 25 minutes
const BREAK_DURATION = 5 * 60; // 5 minutes

function loadState() {
  try {
    if (fs.existsSync(STATE_FILE)) {
      return JSON.parse(fs.readFileSync(STATE_FILE, 'utf8'));
    }
  } catch (e) {}
  return { running: false, startTime: null, isBreak: false, completed: 0 };
}

function saveState(state) {
  const dir = path.dirname(STATE_FILE);
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
  fs.writeFileSync(STATE_FILE, JSON.stringify(state, null, 2));
}

const state = loadState();

if (state.running && state.startTime) {
  const elapsed = Math.floor((Date.now() - state.startTime) / 1000);
  const duration = state.isBreak ? BREAK_DURATION : WORK_DURATION;
  const remaining = Math.max(0, duration - elapsed);

  if (remaining === 0) {
    // Timer finished
    state.running = false;
    if (!state.isBreak) {
      state.completed++;
    }
    saveState(state);
    console.log(state.isBreak ? '🎉 Break done!' : '🍅 Work done!');
  } else {
    const mins = Math.floor(remaining / 60);
    const secs = remaining % 60;
    const icon = state.isBreak ? '☕' : '🍅';
    const color = state.isBreak ? 'green' : 'red';
    console.log(`${icon} ${mins}:${secs.toString().padStart(2, '0')} | color=${color}`);
  }
} else {
  console.log(`🍅 ${state.completed}`);
}

console.log('---');
console.log(`Completed: ${state.completed} pomodoros`);
console.log('---');
if (state.running) {
  console.log('Stop | bash=\'echo "{\\"running\\":false}" > "' + STATE_FILE + '"\' terminal=false refresh=true');
} else {
  console.log('Start Work (25m) | bash=\'echo "{\\"running\\":true,\\"startTime\\":' + Date.now() + ',\\"isBreak\\":false,\\"completed\\":' + state.completed + '}" > "' + STATE_FILE + '"\' terminal=false refresh=true');
  console.log('Start Break (5m) | bash=\'echo "{\\"running\\":true,\\"startTime\\":' + Date.now() + ',\\"isBreak\\":true,\\"completed\\":' + state.completed + '}" > "' + STATE_FILE + '"\' terminal=false refresh=true');
}
console.log('Reset Counter | bash=\'echo "{\\"running\\":false,\\"completed\\":0}" > "' + STATE_FILE + '"\' terminal=false refresh=true');
console.log('---');
console.log('Refresh | refresh=true');
