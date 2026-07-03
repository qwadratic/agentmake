# site-forge review report

## Per-component verdicts

| Component | Verdict | Evidence |
|---|---|---|
| cli-scaffold | PASS | `check.sh` green: CLI contract `build <src> <out> [--theme]`, bad src-dir → nonzero + stderr, theme precedence `--theme > site.json > classic` verified live |
| md-core (F1) | PASS | `check.sh` green: h1–h3, bold/italic/links/inline code/fenced blocks (lang + no-lang)/lists; edge cases: empty file → valid full doc w/ filename title; unclosed fence → rest-as-code no crash; raw `<script>` escaped, no leak |
| site-assembly (F2) | PASS | `check.sh` green: index lists all pages, `index.md` body above page-list, nav on every page incl. index, exactly one `class="active"` per page, correct active target, single-page fixture works, programmatic dead-link scan = zero |
| plugin-subsystem (F3) | PASS | Real subsystem (own goal.md, Makefile, 5 sub-components, own build report `VERDICT: PASS`). All sub-checks green: loader (hook order, unknown plugin → nonzero + name in stderr, raising plugin → nonzero + name, empty list no-op), highlight (tok-kw/str/com/num for python, generic str+num fallback, untagged block byte-identical, no double-escape, balanced spans), rss (RSS 2.0 parses via ElementTree, channel from config, first-`<p>` descriptions, no pubDate, byte-deterministic across runs), hook-contract docs in `plugins/README.md`, integration check covers all 3 F3 acceptance scenarios (both-on / opt-out / broken) |
| themes (F4) | PASS | `check.sh` green incl. **screenshot evals: evalshot ssim=1.000 vs committed goldens for both themes at 480x640**. Shots visually inspected: classic = white bg, serif headings, dark text; midnight = #0b0e14-ish dark bg, light text, blue accent on links/active nav. Both style nav, headings, lists, links, and tok-* colors visibly. CSS shipped locally (`style.css` in out-dir, no remote URLs), byte-identical to theme source |
| self-demo (F5) | PASS | 4 real docs pages (index/usage/plugin-api/themes), `site.json` enables both plugins + midnight; `check.sh` green: 4 htmls + nav everywhere + tok- spans + feed.xml with 4 valid items + zero dead hrefs |

## Acceptance criteria

- **A1** pipeline + escaping — PASS (md-core + site-assembly checks)
- **A2** nav/active/no dead links — PASS (site-assembly + self-demo link scans)
- **A3** plugin subsystem scenarios — PASS (subsystem-integration check: both-on, opt-out yields no tok-/no feed.xml, boomer plugin → nonzero with name in stderr; re-verified against self-demo forge)
- **A4** themes + goldens — PASS (both evalshot green, shots visually confirmed)
- **A5** self-demo — PASS (builds clean, valid feed, ≥4 pages)
- **A6** checks — PASS (all 11 `check.sh` executable, `set -eu`, mktemp + trap cleanup, non-interactive, all <60s)

## Integration verdict

PASS. Every component honors the shared CLI seam; self-demo composes mdcore + loader + both plugins + theme in one run. Live spot-checks confirmed default theme = classic, `--theme` override, unknown theme/plugin rejected loudly.

Nits (non-blocking): stray leftover file `src/site-assembly-tmp-does-not-exist` (duplicate mdcore copy); `__pycache__` dirs committed in tree. Neither affects any criterion.

VERDICT: PASS
