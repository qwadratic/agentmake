# renderer-bench: html → lowres PNG, local paths measured

Machine: macOS 26.5 (arm64), node v24.18. Test page: `.bench/test.html` (cards + gradients + SVG).
All shots 480×640 unless noted. `/usr/bin/time -p` wall clock.

## Measured

| path | cold (first) | warm per-shot | notes |
|---|---|---|---|
| full Chrome one-shot `--headless=new --screenshot` | 3.41 s | **2.16 s** | profile/startup tax every shot. avoid. |
| chrome-headless-shell one-shot (playwright cache, standalone CLI) | 2.85 s | **0.19–0.23 s** | no npm pkg needed, binary runs bare |
| chrome-headless-shell one-shot @ 1920×1080 | — | 0.23–0.28 s | +encode cost, 2× PNG bytes (51 KB vs 25 KB) |
| **persistent headless-shell + raw CDP** (node built-in WebSocket, zero deps) | 248 ms browser-up + 79 ms first shot | **25 ms median** (10 shots) | navigate→loadEventFired→captureScreenshot |
| sips downscale 1920→640 (post-step) | — | +40 ms + double PNG IO | pure waste vs native lowres |
| wkhtmltoimage | absent | — | not installed, skipped |
| Safari/WebKit | — | — | no headless screenshot without safaridriver+WebDriver client; not worth it here |
| npx playwright | — | — | pkg not installed, would download → skipped per constraints |

## Key insight — validated

**Render natively at target lowres.** 480×640 native is *faster* than 1920×1080
(less raster + PNG encode), smaller output, and skips the downscale step entirely.
Downscale-after costs +40 ms (sips) — small alone, but at persistent-CDP speed
(25 ms/shot) it would 2.6× the pipeline. Never render big then shrink for smoke evals.

## Chosen approach (`snap`)

One-shot **chrome-headless-shell** from playwright cache (glob newest version dir),
fallback full Chrome. ~0.2 s/shot, zero deps, zero daemon state, works now.

## ffmpeg-pipeline note

ffmpeg present (`/opt/homebrew/bin/ffmpeg`). When html→lowres-PNG→ffmpeg is
**universal**: stitching N snaps into a timelapse/contact-sheet for one-glance
review (`ffmpeg -pattern_type glob -i 'snap_*.png' -vf tile=4x4 sheet.png`),
or diff-video across agent iterations. When **overkill**: single-shot smoke
gates — PNG already lowres natively, nothing to transcode; sips covers any
one-off resize. Rule: ffmpeg enters when *aggregating many frames*, never for
producing one.

## Ceiling + upgrade path

- **ponytail ceiling:** `snap` is one-shot → pays ~190 ms browser boot per call.
  Fine ≤ ~5 shots per eval run.
- **Upgrade: persistent CDP pool.** Proven in `.bench/cdp_bench.mjs` (zero-dep:
  node built-in WebSocket + `Target.createTarget`/`Page.captureScreenshot`):
  25 ms/shot = **~8× faster** than one-shot. Shape: `snapd` daemon holding one
  headless-shell + N tabs, `snap` becomes thin client (unix socket or HTTP),
  falls back to one-shot when daemon absent. Worth it once eval loops take
  dozens of shots per iteration.
- Beyond that: `captureBeyondViewport` for full-page shots, jpeg quality knob
  for even smaller eval payloads.

## Repro

```
cd makefile-lab/evals
./snap .bench/test.html /tmp/out.png            # 480x640 default
./snap .bench/test.html /tmp/out.png 320 240    # custom dims
node .bench/cdp_bench.mjs <shell-bin> file://$PWD/.bench/test.html   # persistent bench
```
