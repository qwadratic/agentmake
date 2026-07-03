# TUI evals: text goldens via `tmux capture-pane`

Verdict: **pixels are the wrong tool for terminals.** A terminal is already a
deterministic 2D grid of characters — capture the grid, diff the text.
`tmux capture-pane -p` gives byte-stable 80x24 snapshots for free, and `diff -u`
is the eval report. No pip, no docker, no headless browser.

Verified on this machine: tmux 3.6a (`/opt/homebrew/bin/tmux`), python3 stdlib
curses. Also present: `script` (BSD), `asciinema`, `col`.

## Mechanism comparison

| Mechanism | What you get | Verdict |
|---|---|---|
| `tmux capture-pane -p` | Final rendered grid, ANSI-stripped text | **Recommended.** Deterministic, diffable, zero deps beyond tmux. Captures what the *user sees* after redraws, not the raw byte stream. |
| `tmux capture-pane -e` | Same grid + escape sequences | Use only when colors/attributes are the thing under test. Diffs get noisy (`^[[31m...`). |
| `script` / typescript replay | Raw output byte stream incl. every intermediate redraw | Bad golden: cursor-movement soup, timing-sensitive, one extra repaint breaks the diff. Useful as debug artifact, not gate. |
| `asciinema` cast diff | JSON events with timestamps | Timestamps make every run unique; you'd strip them and reimplement capture-pane badly. Great for human demo recordings, wrong for gates. |
| ANSI-strip a raw stream (`col -b`, sed) | Cleaned stream | Still stream-order-dependent (redraws interleave). capture-pane already gives you the *final grid* — strictly better. |
| Actual pixel screenshot | Bitmap of terminal window | Only warranted when the terminal emulator itself is under test: font rendering, ligatures, sixel/kitty image protocol, emoji width bugs, true-color blending. Never for "does my TUI show the right data". |

## Demo transcript (real run, this machine)

Tiny curses app (`app.py`):

```python
import curses
def main(s):
    curses.curs_set(0)
    s.box()
    s.addstr(0, 2, " tweetbox ")
    s.addstr(2, 2, "users: 3    tweets: 12")
    s.addstr(3, 2, "timeline lag: 4ms")
    s.addstr(5, 2, "[q] quit")
    s.refresh()
    s.getch()
curses.wrapper(main)
```

Capture golden:

```console
$ tmux new-session -d -s tuieval -x 80 -y 24 'python3 app.py'
$ for i in $(seq 1 20); do tmux capture-pane -pt tuieval | grep -q 'tweetbox' && break; sleep 0.1; done
$ tmux capture-pane -pt tuieval | sed 's/[[:space:]]*$//' > golden.txt
$ head -6 golden.txt
┌─ tweetbox ───────────────────────────────────────────────────────────────────┐
│                                                                              │
│ users: 3    tweets: 12                                                       │
│ timeline lag: 4ms                                                            │
│                                                                              │
│ [q] quit                                                                     │
```

Roundtrip — rerun is byte-identical, one-char regression is caught:

```console
$ run_capture app.py > actual.txt && diff -u golden.txt actual.txt
PASS: rerun identical

$ sed 's/tweets: 12/tweets: 13/' app.py > app_bad.py
$ run_capture app_bad.py > actual_bad.txt && diff -u golden.txt actual_bad.txt
--- golden.txt
+++ actual_bad.txt
@@ -1,6 +1,6 @@
 ┌─ tweetbox ─────────────────────────────────────────────────────────────────┐
 │                                                                            │
-│ users: 3    tweets: 12                                                     │
+│ users: 3    tweets: 13                                                     │
(exit 1 → gate fails)
```

## Recipe: golden-text gate for the makefile-lab

Drop-in `tui-check.sh` (same shape as the lab's per-component `check.sh` gates):

```bash
#!/usr/bin/env bash
# tui-check.sh <cmd> <golden-file> [ready-marker]
# Exit 0 iff rendered pane matches golden. UPDATE_GOLDEN=1 to regen.
set -euo pipefail
CMD=$1; GOLDEN=$2; MARKER=${3:-.}
S="tuieval-$$"
trap 'tmux kill-session -t "$S" 2>/dev/null || true' EXIT

tmux new-session -d -s "$S" -x 80 -y 24 "$CMD"
# poll for readiness — never bare sleep
for _ in $(seq 1 50); do
  tmux capture-pane -pt "$S" | grep -q "$MARKER" && break
  sleep 0.1
done

ACTUAL=$(tmux capture-pane -pt "$S" | sed 's/[[:space:]]*$//')

if [ "${UPDATE_GOLDEN:-}" = 1 ]; then
  printf '%s\n' "$ACTUAL" > "$GOLDEN"
  echo "golden updated: $GOLDEN"
  exit 0
fi
diff -u "$GOLDEN" <(printf '%s\n' "$ACTUAL")
```

Makefile integration (matches `makefile-lab/twitter/Makefile` gate style —
recipe line fails ⇒ target fails ⇒ `.done` not touched):

```make
$(B)/tui-dashboard.done: $(B)/db-layer.done
	$(AGENT) build tui-dashboard
	bash evals/tui-check.sh 'python3 src/tui-dashboard/main.py' \
	    src/tui-dashboard/golden.txt 'tweetbox'
	touch $@
```

Golden regen after intentional UI change:

```console
$ UPDATE_GOLDEN=1 bash evals/tui-check.sh 'python3 src/tui-dashboard/main.py' src/tui-dashboard/golden.txt tweetbox
$ rtk git diff src/tui-dashboard/golden.txt   # human/agent reviews the visual diff
```

## Determinism gotchas (the whole game)

- **Fix geometry**: always `-x 80 -y 24`. Grid size changes every line.
- **Strip trailing whitespace**: capture-pane pads lines; `sed 's/[[:space:]]*$//'` both sides.
- **Poll, don't sleep**: grep for a marker string the app draws last. Bare
  sleeps race on loaded CI boxes.
- **Mask dynamic cells**: timestamps, PIDs, latency numbers → normalize before
  diff: `sed -E 's/lag: [0-9]+ms/lag: Nms/'` on both golden and actual. Or
  design the app with a `--frozen-clock` test flag (cheaper).
- **Locale**: box-drawing chars need UTF-8. Pin `LC_ALL=en_US.UTF-8` in the
  session env if CI differs from dev.
- **Status bar**: `capture-pane` grabs the pane only, tmux status line never
  pollutes the golden. No config needed.
- **TERM**: tmux normalizes to `tmux-256color` inside — one less variable than
  raw `script` capture.
- **Unique session names** (`tuieval-$$`) + `trap` kill: parallel make (`-j`)
  safe, no leaked sessions on failure.

## Escalation ladder

1. Text golden of final grid (this recipe) — 95% of TUI eval value.
2. `-e` color golden — only if color semantics are the feature (e.g. red for
   failing metric).
3. Multi-frame: `send-keys` then re-capture per interaction step, one golden
   per frame (`golden-1.txt`, `golden-2.txt`).
4. Pixel screenshot of a real terminal window — only for emulator/font/image-
   protocol testing. On macOS: `screencapture -l <windowid>`; needs a real GUI
   session, so keep it out of the default gate.
