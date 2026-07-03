const assert = require("assert");
const { weatherCodeToDisplay } = require("./weather.js");

assert.deepStrictEqual(weatherCodeToDisplay(0), { emoji: "☀️", label: "Clear sky" });
assert.deepStrictEqual(weatherCodeToDisplay(3), { emoji: "☁️", label: "Overcast" });
assert.deepStrictEqual(weatherCodeToDisplay(61), { emoji: "🌧️", label: "Light rain" });
assert.deepStrictEqual(weatherCodeToDisplay(75), { emoji: "❄️", label: "Heavy snow" });
assert.deepStrictEqual(weatherCodeToDisplay(95), { emoji: "⛈️", label: "Thunderstorm" });
// unknown code fallback
assert.deepStrictEqual(weatherCodeToDisplay(1234), { emoji: "❓", label: "Unknown" });
assert.deepStrictEqual(weatherCodeToDisplay(undefined), { emoji: "❓", label: "Unknown" });

console.log("weather-panel selftest OK");
