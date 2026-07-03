# ATTN-SPEC — interpretive attention rendering for forth-forth

Version: `attn-proxy/1`
Scope: forth-forth dialect (stage0 word set, `demos/forth-forth/src/stage0/stage0.py`)
+ agent-session timeline frames.

---

## 0. HONESTY CONTRACT (hard requirement, non-negotiable)

Everything this spec renders is an **INTERPRETIVE PROXY** — weights are derived
from forth grammar structure, token categories, and session recency. They are
**not** attention weights from any model. Hosted models expose no internals;
nothing here pretends otherwise.

Enforcement — the exact string

```
interpretive proxy — not model internals
```

MUST appear, verbatim:

1. In the **legend line of every rendered frame** (both modes, both color modes).
2. In the JSON sidecar as top-level `"disclaimer"` (consumers MUST refuse
   sidecars missing it — treat as corrupt).
3. **Burned into pixels** of any exported media (gif/mp4/svg) — not metadata,
   not a caption file. If a frame is cropped, the crop must keep the legend.

A renderer that drops the string in any output path is non-conforming. No flag
disables it. Judges treat unlabeled proxy output as critical dishonesty; so
does this spec.

---

## 1. Token categories (from the actual dialect)

Category is decided by exact token match against the stage0 word set, then
number regex `^[+-]?\d+$`, then dictionary lookup (was it defined by `:` /
`variable` / `constant` earlier in the file?).

| cat    | members (this dialect)                                                      | fg 256 | fg truecolor | glyph |
|--------|-----------------------------------------------------------------------------|--------|--------------|-------|
| `def`  | `:` `;` `variable` `constant` + the **name token** following `:`/`variable` | 213    | `#ff87ff`    | `■`   |
| `ctl`  | `if` `else` `then` `begin` `until` `do` `loop` `i`                          | 214    | `#ffaf00`    | `■`   |
| `stk`  | `dup` `drop` `swap` `over` `rot`                                            | 51     | `#00ffff`    | `■`   |
| `lit`  | numbers; string payloads of `." ..."` `s" ..."`                             | 255    | `#eeeeee`    | `■`   |
| `com`  | `\ ...` to EOL; `( ... )` inclusive                                         | 244    | `#808080`    | `■`   |
| `usr`  | any word found in the dictionary (defined-then-called)                      | 75     | `#5fafff`    | `■`   |
| `prim` | remaining builtins: `+ - * / mod negate = < > @ ! . emit cr token h. h= h>n ."  s"` | 114 | `#87d787` | `■` |

Unknown word (would crash stage0): cat `usr`, weight forced 0, rendered with
fg 196 (`#ff0000`) — it's a bug beacon, not attention.

ponytail: 7 cats not 6 — `prim` bucket keeps arith/io/compiler-support words
from polluting `usr`. Ceiling: split `prim` into arith/io/compsupport if a
demo ever needs it.

---

## 2. Attention types (what the proxy pretends to attend to)

All four are computable from a single tokenizer pass + one dictionary pass.
No execution required (stack effects are static per-word arities).

### 2.1 def-use edges — long-range attention
Edge from the **name token** at its definition site (`: foo` → token `foo`,
`variable bar` → token `bar`) to **every call site** of that word. This is the
"long-range head": in `compiler.fs`, `ind` is defined near the top and called
~22× across the file — those edges span the whole buffer.

### 2.2 stack-effect coupling — local attention
Per-word arity `(consumed, produced)` from the stage0 semantics
(e.g. `dup (1,2)`, `rot (3,3)`, `! (2,0)`, `token (0,1)`). Walk each
definition body simulating abstract stack cells; when word B pops a cell that
word A pushed, emit edge A→B. Edges are inherently short-range (same
definition body); this is the "local head". Cells crossing an `if`/`else`
boundary couple to the junction token instead (merge point is the honest
answer when static analysis can't pick a branch).

### 2.3 control junctions — high-salience nodes
`if` `else` `until` `loop` are **decision/back-edge points** → salience bonus
0.8. `begin` `do` `then` are structural anchors → bonus 0.4. Junctions also
get structural **pair edges**: `if↔then`(`↔else↔then`), `begin↔until`,
`do↔loop` — rendered as bracket ticks, they define nesting.

### 2.4 nesting depth — scalar field
Depth = count of open `if`/`begin`/`do` at the token. Modulates junction
salience (deeper branch = hotter) and is exported per token so replay can
draw indent-heat.

---

## 3. Weight heuristic (`attn-proxy/1`)

Per token:

```
w = clamp( (base + w_ref + w_stack + w_edge + w_junction + w_recency) / 1.6 , 0, 1 )
```

| term         | formula                                                            | applies to |
|--------------|--------------------------------------------------------------------|------------|
| `base`       | `lit`: 0.15 · `def`: 0.30 · else 0                                 | category   |
| `w_ref`      | `log2(1+refs(word)) / log2(1+max_refs_in_file)`                    | def-site name AND call sites of dictionary words |
| `w_stack`    | `(consumed+produced) / 6`   (6 = rot's 3+3, dialect max)           | words with arity |
| `w_edge`     | `min(1, ln(1+|line_use − line_def|) / ln(1+file_lines))`           | call sites (long-range edges glow hotter) |
| `w_junction` | `bonus × min(1.5, 1 + 0.15·depth)`; bonus 0.8 / 0.4 per §2.3       | ctl junctions |
| `w_recency`  | `exp(−Δframes / 6)`; Δframes = frames since a tool call touched this token's line span | **session mode only** |
| `com`        | weight pinned 0.05, all other terms ignored                        | comments |

Edge weights: def-use edge `w = w_edge(use site)`; stack edge `w = 0.4` flat;
pair edge `w = 0.6` flat.

Validated on a real `compiler.fs` fragment (`spaces`, `ind`; `ind` refcount 22,
one call site 56 lines from its def) by `attn-proxy-check.py` (this dir):

```
if 0.575 · else 0.650 · then 0.325 · until 0.575 · begin 0.250
dup 0.312 · drop 0.104 · literal 0.094 · : 0.187
ind@def 0.625 · ind@far-use 1.000 · spaces@def 0.138
```

Invariants asserted by the check (all hold):
branch junction > closer; loop test > loop opener; hot def (22 refs) > cold
def (1 ref); long-range use > its own def site; stack op > bare literal;
everything ≤ 1.0.

---

## 4. Rendering — textual, in-terminal, never leave the editor

Both modes emit plain ANSI to stdout; pipe into `less -R`, tmux pane, or
capture with asciinema. Detect truecolor via `$COLORTERM==truecolor`, else 256.

### 4.1 Common encoding

- **Background = weight.** Truecolor: bg = black→`#5f1f00`→`#af4500` linear ramp
  by `w`. 256-color: quantize `w` to 5 buckets → bg `{234, 237, 58, 130, 166}`.
- **Foreground = category hue** (table §1). Fg palette chosen to stay readable
  on all 5 bg buckets.
- **Junction markers:** decision junctions get SGR 4 (underline) on the token
  + `◆` in the line gutter; structural anchors get `‣` in the gutter. Gutter,
  not inline — inline glyphs break column alignment.
- **Accessibility / `--no-color`:** REQUIRED fallback. Weight rendered as
  intensity glyph column after each token: ` ` `░` `▒` `▓` `█` (5 buckets);
  category as one-letter tag in gutter on demand (`--tags`). Information is
  never color-only.
- **Legend (last line of every frame, mandatory, exact disclaimer string):**

```
attn ■def ■ctl ■stk ■lit ■com ■usr ■prim  bg=weight ◆=junction  [interpretive proxy — not model internals]
```

(each `■` printed in its category fg color; in `--no-color` mode the swatches
become the one-letter tags.)

### 4.2 Mode A — static file view

```
attn view file.fs [--focus WORD] [--no-color] [--tags] [--json out.attn.json]
```

- Line-numbered source, tokens colored/weighted per §3 (no `w_recency`).
- `--focus WORD`: re-weight — tokens on edges incident to WORD keep their `w`,
  everything else multiplied by 0.15. This is how def-use edges are *seen*
  without drawing arrows: focus `ind` and its 22 call sites light up across
  the scroll.
- Pager-friendly: one legend per screenful (repeat every 40 lines) so any
  visible viewport carries the disclaimer.

### 4.3 Mode B — session timeline view

```
attn session <session.jsonl> [--fps 2] [--no-color] [--json out.attn.json]
```

One **frame per tool call** in the agent session. Frame layout:

```
┌ frame 017/112  tool=edit  file=src/stage1/compiler.fs  Δ+6/−1 ┐
  …rendered source region touched by the call, weights include
  w_recency (touched lines glow, decay τ=6 frames)…
  …fixed 24-line viewport centered on the edit…
└ attn … [interpretive proxy — not model internals] ┘
```

- Header: frame index, tool name, target file, diffstat.
- Body: §4.1 encoding + `w_recency`; lines touched this frame get max recency,
  earlier touches decay `exp(−Δframes/6)`.
- Footer: full legend line (§4.1) — every frame self-labels.
- Frames separated by `\x1b[2J\x1b[H` (clear+home) when streaming to a tty;
  by literal line `--ATTN-FRAME <idx>--` when stdout is a pipe (replay
  production splits on it).
- Playback: `attn session … | asciinema rec`, or pipe frames to agg/ffmpeg via
  the JSON sidecar instead (preferred for media export — see §5 `frames`).

---

## 5. JSON sidecar (`*.attn.json`) — replay-production contract

Strict JSON (this is a contract — do not TOON it). One file per render.

```json
{
  "version": 1,
  "heuristic": "attn-proxy/1",
  "disclaimer": "interpretive proxy — not model internals",
  "source": "src/stage1/compiler.fs",
  "mode": "static | session",
  "generated": "2026-07-04T00:00:00Z",
  "params": { "tau": 6, "junction_bonus": [0.8, 0.4], "norm": 1.6 },
  "cats": ["def","ctl","stk","lit","com","usr","prim"],
  "tokens": [
    { "i": 0, "line": 4, "col": 1, "text": ":",   "cat": "def", "w": 0.187, "depth": 0, "junction": null },
    { "i": 1, "line": 4, "col": 3, "text": "ind", "cat": "def", "w": 0.625, "depth": 0, "junction": null },
    { "i": 9, "line": 2, "col": 9, "text": "if",  "cat": "ctl", "w": 0.575, "depth": 1, "junction": "decision" }
  ],
  "edges": [
    { "type": "defuse", "from": 1, "to": 88, "w": 0.82 },
    { "type": "stack",  "from": 3, "to": 4,  "w": 0.4  },
    { "type": "pair",   "from": 9, "to": 14, "w": 0.6  }
  ],
  "frames": [
    { "idx": 17, "tool": "edit", "ts": "2026-07-04T00:00:00Z",
      "file": "src/stage1/compiler.fs",
      "touched_lines": [40, 46],
      "recency": [[31, 1.0], [32, 1.0], [12, 0.717]] }
  ]
}
```

Rules for consumers:

- `disclaimer` missing or altered → reject file.
- `tokens[].i` is the stable id; `edges[]` and `frames[].recency` reference it.
- `frames` present only in session mode; static `w` in `tokens` **excludes**
  recency — frame weight = `clamp(w + recency/1.6, 0, 1)` recomputed at
  playback, so one sidecar drives any fps.
- `junction`: `"decision"` (if/else/until/loop), `"anchor"` (begin/do/then),
  or `null`.

---

## 6. Reference check

`demoscene/attn-proxy-check.py` — stdlib-only, runs the §3 formula over a real
`compiler.fs` fragment and asserts the invariants listed in §3. Run:

```sh
rtk python3 demoscene/attn-proxy-check.py   # prints table, "OK: all invariants hold"
```

Any change to §3 constants requires updating the check first (it is the
formula's executable definition).

ponytail: renderer itself not implemented here — this spec + sidecar contract
+ validated formula is the deliverable. Ceiling: `attn` CLI as a small python
(tokenizer already exists in stage0.py `next_token`; steal it).
