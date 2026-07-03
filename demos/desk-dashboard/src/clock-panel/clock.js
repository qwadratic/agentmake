// clock-panel: mounts into #clock-panel .panel-body (app-shell contract).
// Pure formatters exported for node self-test; DOM code only runs in browser.

function pad(n) {
  return String(n).padStart(2, "0");
}

function formatTime(date) {
  return {
    hhmm: pad(date.getHours()) + ":" + pad(date.getMinutes()),
    seconds: pad(date.getSeconds()),
    dateLine: date.toLocaleDateString(undefined, {
      weekday: "long",
      year: "numeric",
      month: "long",
      day: "numeric",
    }),
  };
}

if (typeof module !== "undefined" && module.exports) {
  module.exports = { formatTime, pad };
}

if (typeof document !== "undefined") {
  document.addEventListener("DOMContentLoaded", () => {
    const body = document.querySelector("#clock-panel .panel-body");
    if (!body) return;
    body.innerHTML =
      '<div class="clock-time"><span class="clock-hhmm"></span>' +
      '<span class="clock-seconds"></span></div>' +
      '<div class="clock-date"></div>';
    const hhmmEl = body.querySelector(".clock-hhmm");
    const secEl = body.querySelector(".clock-seconds");
    const dateEl = body.querySelector(".clock-date");
    const tick = () => {
      const t = formatTime(new Date());
      hhmmEl.textContent = t.hhmm;
      secEl.textContent = t.seconds;
      dateEl.textContent = t.dateLine;
    };
    tick();
    setInterval(tick, 1000);
  });
}
