# demoscene — forth-forth evolution session, rendered

> **HONESTY (read first):** every "attention" surface in this directory is an
> **interpretive proxy — not model internals**. Weights derive from forth
> grammar structure, token categories, and session recency (spec:
> [ATTN-SPEC.md](ATTN-SPEC.md) §0). Hosted models expose no internals. The
> exact label is burned into every frame legend, every JSON sidecar, and the
> pixels of every exported video. No flag disables it; consumers reject
> unlabeled sidecars.

A live pi session evolved `demos/forth-forth` using **only the `forth` tool**
([forth-tool/](forth-tool/), persistent stage0 VM) — details in
[SESSION.md](SESSION.md). This directory turns that session into a graded
demoscene cut keyed to the proxy-attention timeline.

## Artifact map

| file | what | committed |
|---|---|---|
| `session.cast` / `session-trace.jsonl` | raw asciinema v3 recording + raw pi session JSONL | ✅ |
| `attn` | CLI renderer: `view` (static file) + `session` (per-tool-call frames); `--json` emits the spec-§5 sidecar shape | ✅ |
| `attn-session.py` | trace → `out/session.attn.json` — **extended** sidecar (spec-§5 + per-frame `dominant_cat`/`cat_weights`/`decision_junctions`/`attn_label`); the shape `mk-timeline.py` requires | ✅ |
| `mk-timeline.py` | cast + sidecar → `out/session-capped.cast` + `out/timeline.json` (idle-capped, /2.3 speed clock) | ✅ |
| `mk-grade.py` | `out/raw.mp4` + timeline → `out/final-v1.mp4` / `final-v2.mp4` (v2 adds junction pulses) | ✅ |
| `out/session.attn.json`, `out/compiler.attn.json` | proxy-attention sidecars (contract: ATTN-SPEC §5) | ✅ |
| `out/*.mp4`, `out/raw.gif`, `out/*.filter`, `out/*.pgm`, `out/*.cast`, `out/timeline.json` | render products | ❌ gitignored, regenerate below |

## Regenerate everything (repo root)

```sh
cd demoscene
python3 attn-session.py                          # trace -> out/session.attn.json
python3 mk-timeline.py                           # cast + sidecar -> capped cast + timeline.json
agg --speed 2.3 out/session-capped.cast out/raw.gif
ffmpeg -y -i out/raw.gif -vf "pad=iw:ih+mod(ih\,2)" \
  -c:v libx264 -pix_fmt yuv420p out/raw.mp4      # gif -> even-height mp4
python3 mk-grade.py v2                           # graded cut (v1 for calm grade)
python3 mk-grade.py v2 --probe                   # 12s slice for iteration
```

Static / interactive views (no video needed):

```sh
./attn view ../demos/forth-forth/src/stage1/compiler.fs --focus ind | less -R
./attn session session-trace.jsonl               # 11 frames, one per tool call
```

## Checks

```sh
python3 attn-proxy-check.py    # executable weight definition (ATTN-SPEC §3 invariants)
python3 attn-selfcheck.py      # golden-text eval + honesty assertions, all modes
node forth-tool/check.mjs      # forth-tool protocol/persistence self-check
```

Both attn checks assert the disclaimer string in **every** output mode;
`mk-timeline.py` / `mk-grade.py` refuse sidecars/timelines missing it.
