// Canvas renderer with age-based fade trail. ES module, browser + node-testable.

// Ages: alive cells accumulate age (capped), dead cells decay toward 0.
// createAges(grid) -> Float32Array; updateAges mutates each engine tick.

export const MAX_AGE = 1;      // alive brightness cap
export const FADE = 0.15;      // decay per update when dead
export const GROW = 0.35;      // growth per update when alive

export function createAges(grid) {
  return new Float32Array(grid.w * grid.h);
}

export function updateAges(grid, ages) {
  for (let i = 0; i < ages.length; i++) {
    ages[i] = grid.cells[i]
      ? Math.min(MAX_AGE, ages[i] + GROW)
      : Math.max(0, ages[i] - FADE);
  }
  return ages;
}

// age (0..1) -> fill color. Young cells hot green, fading trail dims to teal.
export function ageToColor(age) {
  if (age <= 0) return null; // skip draw
  const a = Math.min(1, age);
  const g = Math.round(120 + 135 * a);
  const b = Math.round(80 + 100 * (1 - a));
  return `rgba(40,${g},${b},${a.toFixed(3)})`;
}

// ctx: CanvasRenderingContext2D (or stub). cellSize px per cell.
export function render(ctx, grid, ages, cellSize) {
  ctx.fillStyle = "#0a0f14";
  ctx.fillRect(0, 0, grid.w * cellSize, grid.h * cellSize);
  const pad = Math.max(0.5, cellSize * 0.08);
  for (let y = 0; y < grid.h; y++)
    for (let x = 0; x < grid.w; x++) {
      const c = ageToColor(ages[y * grid.w + x]);
      if (!c) continue;
      ctx.fillStyle = c;
      ctx.fillRect(x * cellSize + pad, y * cellSize + pad, cellSize - 2 * pad, cellSize - 2 * pad);
    }
}
