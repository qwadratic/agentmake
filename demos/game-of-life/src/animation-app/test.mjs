import assert from "node:assert";
import { createApp, tick, advance, TICK_MS, STAGNANT_TICKS } from "./app.js";

// 100 headless ticks: generation advances
const app = createApp(40, 30);
for (let i = 0; i < 100; i++) tick(app);
assert.strictEqual(app.generation, 100, "generation count advances");

// advance() converts elapsed time to ticks
const app2 = createApp(20, 20);
advance(app2, TICK_MS * 5);
assert.strictEqual(app2.generation, 5, "advance runs ticks at ~10 gen/s");

// stagnation reseed: seed a still life (block) on otherwise empty grid
const app3 = createApp(10, 10, () => 0); // rand=0 -> randomize clears; put block manually
app3.grid.cells.fill(0);
[[2,2],[2,3],[3,2],[3,3]].forEach(([x,y]) => app3.grid.cells[y * 10 + x] = 1);
app3.rand = Math.random; // real reseed when triggered
let reseeded = false;
for (let i = 0; i < STAGNANT_TICKS + 5 && !reseeded; i++) reseeded = tick(app3);
assert.ok(reseeded, "stagnation triggers reseed");
assert.strictEqual(app3.reseeds, 1);

console.log("animation-app: all tests passed");
