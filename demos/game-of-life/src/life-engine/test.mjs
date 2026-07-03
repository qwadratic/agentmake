import { createGrid, set, step, get } from "./engine.js";
import assert from "node:assert";

// blinker oscillates period 2
let g = createGrid(5, 5);
[[1, 2], [2, 2], [3, 2]].forEach(([x, y]) => set(g, x, y, 1));
const orig = g.cells.slice();
const g1 = step(g);
assert.notDeepStrictEqual([...g1.cells], [...orig], "blinker changed after 1 step");
assert(get(g1, 2, 1) && get(g1, 2, 2) && get(g1, 2, 3), "blinker vertical");
assert.deepStrictEqual([...step(g1).cells], [...orig], "blinker back after 2 steps");

// glider translates (+1,+1) after 4 steps
g = createGrid(10, 10);
const glider = [[1, 0], [2, 1], [0, 2], [1, 2], [2, 2]];
glider.forEach(([x, y]) => set(g, x, y, 1));
let s = g;
for (let i = 0; i < 4; i++) s = step(s);
const expected = createGrid(10, 10);
glider.forEach(([x, y]) => set(expected, x + 1, y + 1, 1));
assert.deepStrictEqual([...s.cells], [...expected.cells], "glider translated");

// toroidal wrap: cell at edge counts neighbors across border
g = createGrid(4, 4);
[[0, 0], [3, 0], [0, 3]].forEach(([x, y]) => set(g, x, y, 1));
assert(get(step(g), 3, 3), "corner born via wrap");

console.log("life-engine: all tests pass");
