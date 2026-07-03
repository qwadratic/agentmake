// app-shell: panel modules mount into these containers.
// Contract: clock-panel, weather-panel, todo-panel each own their .panel-body.
document.addEventListener("DOMContentLoaded", () => {
  for (const id of ["clock-panel", "weather-panel", "todo-panel"]) {
    const el = document.querySelector(`#${id} .panel-body`);
    if (el && !el.hasChildNodes()) el.textContent = "…";
  }
});
