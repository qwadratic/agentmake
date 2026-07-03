// Game of Life core. Pure functions. Grid: Uint8Array, row-major, toroidal.

export function createGrid(w, h) {
  return { w, h, cells: new Uint8Array(w * h) };
}

export function get(grid, x, y) {
  const { w, h } = grid;
  return grid.cells[((y + h) % h) * w + ((x + w) % w)];
}

export function set(grid, x, y, v) {
  const { w, h } = grid;
  grid.cells[((y + h) % h) * w + ((x + w) % w)] = v ? 1 : 0;
}

export function neighbors(grid, x, y) {
  let n = 0;
  for (let dy = -1; dy <= 1; dy++)
    for (let dx = -1; dx <= 1; dx++)
      if (dx || dy) n += get(grid, x + dx, y + dy);
  return n;
}

// B3/S23. Returns new grid.
export function step(grid) {
  const { w, h } = grid;
  const next = createGrid(w, h);
  for (let y = 0; y < h; y++)
    for (let x = 0; x < w; x++) {
      const n = neighbors(grid, x, y);
      next.cells[y * w + x] = n === 3 || (n === 2 && get(grid, x, y)) ? 1 : 0;
    }
  return next;
}

export function randomize(grid, density = 0.3, rand = Math.random) {
  for (let i = 0; i < grid.cells.length; i++)
    grid.cells[i] = rand() < density ? 1 : 0;
  return grid;
}

export function population(grid) {
  let p = 0;
  for (const c of grid.cells) p += c;
  return p;
}
