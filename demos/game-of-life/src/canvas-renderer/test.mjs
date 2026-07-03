import { createGrid, set } from "../life-engine/engine.js";
import { createAges, updateAges, ageToColor, render, MAX_AGE, GROW, FADE } from "./renderer.js";
import assert from "node:assert";

// stub 2D context
const calls = [];
const ctx = {
  fillStyle: "",
  fillRect(x, y, w, h) { calls.push({ style: this.fillStyle, x, y, w, h }); },
};

const grid = createGrid(3, 3);
set(grid, 1, 1, 1);
const ages = createAges(grid);
updateAges(grid, ages);

assert.ok(Math.abs(ages[4] - GROW) < 1e-6, "alive cell grows"); // Float32 precision
assert.strictEqual(ages[0], 0, "dead cell stays 0");

// alive cell saturates
for (let i = 0; i < 10; i++) updateAges(grid, ages);
assert.strictEqual(ages[4], MAX_AGE, "age capped");

// kill cell -> decays, never negative
grid.cells[4] = 0;
updateAges(grid, ages);
assert.ok(Math.abs(ages[4] - (MAX_AGE - FADE)) < 1e-6, "decays by FADE");
for (let i = 0; i < 20; i++) updateAges(grid, ages);
assert.strictEqual(ages[4], 0, "clamped at 0");

// color mapping
assert.strictEqual(ageToColor(0), null);
assert.strictEqual(ageToColor(1), "rgba(40,255,80,1.000)");
assert.strictEqual(ageToColor(0.5), "rgba(40,188,130,0.500)");

// render: background + one cell at partial age
ages[4] = 0.5;
render(ctx, grid, ages, 10);
assert.strictEqual(calls.length, 2, "bg + 1 cell drawn");
assert.strictEqual(calls[0].style, "#0a0f14");
assert.strictEqual(calls[1].style, ageToColor(0.5));
assert.ok(calls[1].x > 10 && calls[1].y > 10, "cell at (1,1) offset");

console.log("canvas-renderer: all checks passed");
