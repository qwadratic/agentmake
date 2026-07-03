const fs = require("fs");
const path = require("path");

const css = fs.readFileSync(path.join(__dirname, "polish.css"), "utf8");

const required = [
  "@media",
  "transition",
  "@keyframes",
  "font-variant-numeric",
  "prefers-reduced-motion: reduce",
];
for (const rule of required) {
  if (!css.includes(rule)) {
    console.error("MISSING rule: " + rule);
    process.exit(1);
  }
  console.log("ok: " + rule);
}

// no keyframe may animate opacity (entry animation must never hide content)
const keyframeBlocks = css.match(/@keyframes[^{]+\{(?:[^{}]*\{[^{}]*\})*[^{}]*\}/g) || [];
if (keyframeBlocks.length === 0) {
  console.error("MISSING: no @keyframes blocks parsed");
  process.exit(1);
}
for (const block of keyframeBlocks) {
  if (/opacity\s*:/.test(block)) {
    console.error("FAIL: opacity animated in keyframes:\n" + block);
    process.exit(1);
  }
}
console.log("ok: no opacity in any @keyframes (" + keyframeBlocks.length + " blocks)");

console.log("polish-pass selftest passed");
