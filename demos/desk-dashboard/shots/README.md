# shots — desk-dashboard visual evals

| file | what | how |
|---|---|---|
| `dashboard.png` | desktop 960×600, first paint | `evals/snap src/app-shell/index.html shots/dashboard.png 960 600` |
| `dashboard-mobile.png` | responsive stack 420×700 | same, 420 700 — exercises polish-pass `@media (max-width:700px)` |
| `dashboard-hero.png` | desktop with live weather loaded | chrome-headless-shell direct + `--virtual-time-budget=8000` (snap has no wait flag; ponytail: upgrade = wait flag in snap) |
| `*.golden.png` | SSIM goldens (bootstrapped) | `evals/evalshot shots/X.png shots/X.golden.png` — pass @ ≥0.97 |

Determinism caveats (expected drift on re-shoot):
- clock renders live HH:MM:SS — seconds always differ; SSIM tolerates small text delta at 0.97, full re-golden after UI changes
- weather panel: first-paint shot shows "Loading…" (deterministic); hero shot shows live open-meteo data (network-dependent — NOT used as golden)

Eval history: first snap caught real bug — polish-pass entry animation faded opacity from 0 with staggered delays → panels invisible at first paint + todo card contrast too low. Fixed forward via component retry (transform-only animation, `prefers-reduced-motion` support, contrast bump).
