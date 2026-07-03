# Eval patterns: golden picture/file gates for make-driven agent pipelines

Mechanics for near-realtime smoke evals so agent-built projects get a visual /
structural quality loop without a human checking every render. Slots into the
existing lab shape: each component's `check.sh` gate can call these; make's
`.DELETE_ON_ERROR` + exit codes do the rest.

Verified locally on this machine: ffmpeg 8.1.1 ✓, ffprobe ✓, python3 ✓.
ImageMagick NOT installed here — its section is documented but untested locally.

---

## 1. Screenshot goldens via ffmpeg SSIM (primary, verified)

### Command + parse

```bash
ffmpeg -hide_banner -i shot.png -i golden.png -lavfi ssim -f null - 2>&1 \
  | sed -n 's/.*All:\([0-9][0-9.]*\).*/\1/p'
```

The ssim filter prints to **stderr**:

```
[Parsed_ssim_0 @ 0x...] SSIM Y:0.9871 U:0.9954 V:0.9948 All:0.989123 (19.63)
```

Grab `All:` (luma+chroma combined). Identical images → `1.000000` (dB is inf —
parse the ratio, not the dB).

### Threshold

Bash has no floats — compare in awk:

```bash
awk -v s="$ssim" -v t="$thr" 'BEGIN{ exit !(s >= t) }'
```

Guidance (empirical, same-host renders):

| threshold | tolerates | catches |
|-----------|-----------|---------|
| 0.999     | nothing (near byte-identical) | any pixel drift — use only for pure-code renders |
| 0.99      | AA/subpixel jitter | small layout shifts, color changes |
| **0.97**  | font hinting, minor AA (default) | moved/missing elements, wrong colors, blank regions |
| 0.90      | large benign variance | only gross breakage (blank page, error screen) |

Measured here: identical PNGs → 1.000000; 320×240 testsrc with a 100×100 red
box painted over → 0.906944; so 0.97 has clear margin on real breakage while
absorbing render noise.

### Gotchas

- **Dimension mismatch**: ssim filter errors out unhelpfully. `ffprobe` both
  images first and fail loudly — never auto-rescale to force a pass (rescale
  hides viewport regressions).
- SSIM ignores metadata, so PNG timestamp/chunks noise is a non-issue (unlike
  byte-diff on PNGs — never `diff` PNGs directly).

### Turnkey wrapper

`./evalshot <shot.png> <golden.png> [threshold=0.97]` (this dir). Exit 0/1,
bootstraps golden on first run with a loud NOTE, writes `<shot>.diff.png`
(difference blend — bright pixels = mismatch) on fail.

---

## 2. ImageMagick compare (fallback — NOT installed here, untested locally)

If `magick` (IM7) or `compare` (IM6) is present:

```bash
# SSIM metric (IM7+)
magick compare -metric SSIM shot.png golden.png null: 2>&1
# → prints "0.98912" to stderr; exit 0 similar / 1 dissimilar / 2 error

# Pixel-count metric with fuzz tolerance (older IMs, very robust)
compare -metric AE -fuzz 2% shot.png golden.png diff.png 2>&1
# → prints count of differing pixels; threshold on the count, e.g. < 0.5% of pixels
```

IM's exit codes are metric-dependent and version-dependent — always parse the
stderr number yourself rather than trusting exit status. Prefer ffmpeg SSIM
when both exist: one tool, one parse, already required for screenshots/video.

---

## 3. Pure-file goldens (no pixels involved)

### Plain text / config / generated code

```bash
diff -u golden/output.txt build/output.txt
```

Exit code is the gate. `-u` output is agent-readable feedback for the fix loop.

### JSON APIs (e.g. the twitter lab http-api)

Raw diff on JSON is flaky (key order, whitespace, volatile fields). Normalize
with jq first — sort keys, strip volatile fields:

```bash
norm() { jq -S 'del(.. | .timestamp?, .created_at?, .id?)' "$1"; }
diff -u <(norm golden/timeline.json) <(curl -s localhost:8080/timeline/1 | norm /dev/stdin)
```

- `-S` sorts object keys → order-insensitive.
- `del(.. | .field?)` strips volatile fields recursively.
- If array order is nondeterministic and irrelevant: `.items |= sort_by(.text)`.

Shape-only variant (schema smoke, zero golden maintenance):

```bash
curl -s localhost:8080/timeline/1 | jq -e 'type=="array" and (.[0] | has("text") and has("user_id"))'
```

`jq -e` exits 1 on false/null — direct make gate, no golden file at all.
Verified locally: both jq patterns behave as described.

---

## 4. Flaky-render mitigation

Goldens die by a thousand innocent diffs. Kill nondeterminism at the source:

- **Fonts**: font rasterization differs per OS/version → goldens are
  machine-scoped. Same-host CI or container pins it. For web renders, ship a
  bundled webfont and wait for `document.fonts.ready` before shooting.
- **Animation freeze**: inject before screenshot:
  ```css
  *, *::before, *::after {
    animation: none !important;
    transition: none !important;
    caret-color: transparent !important; /* kills blinking text cursor */
  }
  ```
  Also emulate `prefers-reduced-motion: reduce` if the tool supports it.
- **Deterministic viewport**: fixed window size, device-scale-factor 1,
  scrollbars hidden (overlay scrollbars flicker in/out). evalshot fails hard on
  dimension mismatch precisely so viewport drift can't hide.
- **Volatile content**: clocks, relative timestamps ("2s ago"), random avatars
  → freeze the clock in the app under test, or mask regions before compare
  (ffmpeg `drawbox=...:color=black:t=fill` over the volatile rect on BOTH
  images).
- **Settling**: wait for network-idle / two rAF ticks, not `sleep 2`. Sleeps
  are both flaky and slow; the eval loop should be near-realtime.
- **GPU/AA jitter**: leftover ~0.5–1% SSIM noise even when "identical" —
  that's what the 0.97 default absorbs. If you need 0.999, render with a
  software rasterizer.

---

## 5. Golden update protocol

The one rule: **a failing eval never auto-updates the golden.** Bootstrap-only
writes (first run) are loud; every later change is a human/agent decision.

**Regression (unintended diff)** — the normal case:
1. evalshot fails, look at `<shot>.diff.png`.
2. Fix code until eval passes. Golden untouched.

**Intentional change** — UI/output legitimately changed:
1. Eyeball the new shot (this is the actual review — don't skip).
2. `rm golden.png && ./evalshot shot.png golden.png` → re-bootstraps with the
   loud NOTE.
3. Commit the new golden **in the same commit as the change that caused it**,
   message says why. A golden changing in a commit that "shouldn't affect
   output" is itself a review red flag — `git log --stat -- '*.golden*' evals/`
   is the audit trail.

**In the agent loop**: builder agents get eval failure output (SSIM score +
diff.png path) as fix-loop feedback. Only the reviewer gate / human is allowed
to delete a golden. Never give the builder `rm`-the-golden as an action, or
every regression becomes an "intentional change".

---

## 6. Make integration

Pattern matching the twitter lab's per-component `check.sh` gate:

```make
# in generated components.mk recipe, after build:
#   bash src/ui-dashboard/check.sh
```

```bash
# src/ui-dashboard/check.sh
set -euo pipefail
python3 src/ui-dashboard/render.py > build/ui-dashboard/shot.png   # deterministic render
../../evals/evalshot build/ui-dashboard/shot.png src/ui-dashboard/golden.png 0.97
```

Notes:
- `.DELETE_ON_ERROR` (already set in the lab Makefile) discards the `.done`
  stamp on eval failure → rebuild reruns the eval. Correct by default.
- Golden lives in `src/<id>/` (committed), shot in `build/` (cleaned). First
  `make` bootstraps goldens loudly; second `make` is the real gate.
- Serial evals against a live server: give the check exclusive port use or
  make targets `.NOTPARALLEL` for that component.
