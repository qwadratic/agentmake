// Main loop logic, DOM-free so node can test it. Browser glue in index.html.
import { createGrid, step, randomize, population } from "../life-engine/engine.js";
import { createAges, updateAges } from "../canvas-renderer/renderer.js";

export const TICK_MS = 100;        // ~10 gen/s
export const STAGNANT_TICKS = 30;  // reseed if population unchanged this long

export function createApp(w, h, rand = Math.random) {
  const app = {
    grid: randomize(createGrid(w, h), 0.3, rand),
    ages: null,
    generation: 0,
    reseeds: 0,
    lastPop: -1,
    stagnant: 0,
    acc: 0,
    rand,
  };
  app.ages = createAges(app.grid);
  return app;
}

// One engine generation. Returns true if reseeded.
export function tick(app) {
  app.grid = step(app.grid);
  app.generation++;
  updateAges(app.grid, app.ages);
  const pop = population(app.grid);
  app.stagnant = pop === app.lastPop ? app.stagnant + 1 : 0;
  app.lastPop = pop;
  if (app.stagnant >= STAGNANT_TICKS || pop === 0) {
    randomize(app.grid, 0.3, app.rand);
    app.reseeds++;
    app.stagnant = 0;
    app.lastPop = -1;
    return true;
  }
  return false;
}

// Call every animation frame with elapsed ms; runs 0+ ticks.
export function advance(app, dtMs) {
  app.acc += Math.min(dtMs, 500); // clamp tab-away spikes
  while (app.acc >= TICK_MS) {
    app.acc -= TICK_MS;
    tick(app);
  }
}
