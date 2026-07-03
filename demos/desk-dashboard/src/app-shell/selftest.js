// self-test: parse index.html, assert 3 panels + linked css/js exist on disk
const fs = require("fs");
const path = require("path");
const assert = require("assert");

const dir = __dirname;
const html = fs.readFileSync(path.join(dir, "index.html"), "utf8");

// 3 panel containers
for (const id of ["clock-panel", "weather-panel", "todo-panel"]) {
  assert(html.includes(`id="${id}"`), `missing panel container #${id}`);
}

// required integration assets: every one must be <link>/<script>-referenced AND exist on disk
const requiredCss = [
  "style.css",
  "../clock-panel/clock.css",
  "../todo-scratchpad/todo.css",
  "../polish-pass/polish.css",
];
const requiredJs = [
  "app.js",
  "../clock-panel/clock.js",
  "../weather-panel/weather.js",
  "../todo-scratchpad/store.js",
  "../todo-scratchpad/todo.js",
];

for (const href of requiredCss) {
  assert(html.includes(`<link rel="stylesheet" href="${href}">`), `missing stylesheet link: ${href}`);
  assert(fs.existsSync(path.join(dir, href)), `css file missing: ${href}`);
}
for (const src of requiredJs) {
  assert(html.includes(`<script src="${src}"></script>`), `missing script tag: ${src}`);
  assert(fs.existsSync(path.join(dir, src)), `js file missing: ${src}`);
}

// load order: store.js must come before todo.js (todo.js reads window.TodoStore)
assert(
  html.indexOf("store.js") < html.indexOf("todo.js"),
  "store.js must load before todo.js"
);

console.log("app-shell self-test OK");
