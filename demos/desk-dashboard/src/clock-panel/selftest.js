const assert = require("assert");
const { formatTime } = require("./clock.js");

// midnight
let t = formatTime(new Date(2026, 0, 1, 0, 0, 0));
assert.strictEqual(t.hhmm, "00:00");
assert.strictEqual(t.seconds, "00");

// noon
t = formatTime(new Date(2026, 6, 3, 12, 0, 30));
assert.strictEqual(t.hhmm, "12:00");
assert.strictEqual(t.seconds, "30");

// single-digit minutes/hours
t = formatTime(new Date(2026, 6, 3, 9, 5, 7));
assert.strictEqual(t.hhmm, "09:05");
assert.strictEqual(t.seconds, "07");

// date line non-empty, contains year
t = formatTime(new Date(2026, 6, 3, 9, 5, 7));
assert.ok(t.dateLine.includes("2026"));

console.log("clock-panel selftest OK");
