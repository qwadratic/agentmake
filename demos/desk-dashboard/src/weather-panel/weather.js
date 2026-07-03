// weather-panel: open-meteo current weather, no API key.
// Works as browser script AND node module (for self-test).

var WEATHER_CONFIG = { lat: 52.52, lon: 13.405, label: "Berlin" }; // ponytail: hardcoded default, edit here

// WMO weather code -> emoji + label. Ranges collapsed to nearest sensible icon.
function weatherCodeToDisplay(code) {
  var map = {
    0: ["☀️", "Clear sky"],
    1: ["🌤️", "Mainly clear"],
    2: ["⛅", "Partly cloudy"],
    3: ["☁️", "Overcast"],
    45: ["🌫️", "Fog"],
    48: ["🌫️", "Rime fog"],
    51: ["🌦️", "Light drizzle"],
    53: ["🌦️", "Drizzle"],
    55: ["🌧️", "Dense drizzle"],
    61: ["🌧️", "Light rain"],
    63: ["🌧️", "Rain"],
    65: ["🌧️", "Heavy rain"],
    66: ["🌧️", "Freezing rain"],
    67: ["🌧️", "Freezing rain"],
    71: ["🌨️", "Light snow"],
    73: ["🌨️", "Snow"],
    75: ["❄️", "Heavy snow"],
    77: ["❄️", "Snow grains"],
    80: ["🌦️", "Rain showers"],
    81: ["🌧️", "Rain showers"],
    82: ["⛈️", "Violent showers"],
    85: ["🌨️", "Snow showers"],
    86: ["🌨️", "Snow showers"],
    95: ["⛈️", "Thunderstorm"],
    96: ["⛈️", "Thunderstorm + hail"],
    99: ["⛈️", "Thunderstorm + hail"],
  };
  var hit = map[code];
  return hit
    ? { emoji: hit[0], label: hit[1] }
    : { emoji: "❓", label: "Unknown" };
}

// node export for self-test
if (typeof module !== "undefined" && module.exports) {
  module.exports = { weatherCodeToDisplay: weatherCodeToDisplay };
}

// browser mount
if (typeof document !== "undefined") {
  document.addEventListener("DOMContentLoaded", function () {
    var body = document.querySelector("#weather-panel .panel-body");
    if (!body) return;
    body.textContent = "Loading…";

    var url =
      "https://api.open-meteo.com/v1/forecast?latitude=" +
      WEATHER_CONFIG.lat +
      "&longitude=" +
      WEATHER_CONFIG.lon +
      "&current_weather=true";

    fetch(url)
      .then(function (r) {
        if (!r.ok) throw new Error("HTTP " + r.status);
        return r.json();
      })
      .then(function (data) {
        var cw = data.current_weather;
        var d = weatherCodeToDisplay(cw.weathercode);
        body.innerHTML =
          '<div class="weather-emoji">' + d.emoji + "</div>" +
          '<div class="weather-temp">' + Math.round(cw.temperature) + "°C</div>" +
          '<div class="weather-label">' + d.label + " · " + WEATHER_CONFIG.label + "</div>";
      })
      .catch(function () {
        body.textContent = "Weather unavailable (offline?)";
      });
  });
}
