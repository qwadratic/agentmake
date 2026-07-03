Report written to `build/report.md`; root composite gate now green.

## Review: plugin-subsystem vs goal.md

**Checks run:** all 5 `src/*/check.sh` fresh — all exit 0, each <1s, own tmp dirs, trap cleanup, `-j2`-safe.

| Component | Verdict | Key evidence |
|---|---|---|
| plugin-loader | PASS | hook order proven; unknown/raising plugin → nonzero + name on stderr; extra check confirms cross-plugin list order (`["b","a"]` → `x[B][A]`) |
| hook-contract-docs | PASS | README has exact signatures, dict keys, order, optionality, fail-loud semantics |
| highlight-plugin | PASS | py: all 4 tok classes; unknown lang: str+num only; untagged byte-identical; no double-escape; span validity via html.parser |
| rss-plugin | PASS | RSS 2.0 parses, channel meta, item/page, first-para descriptions, byte-identical rebuilds, no pubDate |
| subsystem-integration | PASS | both-on run (tok- spans + valid feed.xml), opt-out run (zero tok-, no feed), broken-plugin run (nonzero, name in stderr) |

**Evals:** no visual/TUI surface in this subtree (screenshot goldens belong to sibling theme component in parent PRD) — visual evals N/A; all applicable checks executed.

**Integration:** loader + both plugins + host pipeline compose end-to-end against sibling `mdcore.py`; all three subsystem acceptance scenarios hold. Minor non-blocking cosmetic: unpaired apostrophe in python block can mislabel trailing text `tok-com`.

VERDICT: PASS
 (title fallback), parses with ElementTree.
- Deterministic: no pubDate; two consecutive builds `cmp` byte-identical.

### subsystem-integration — PASS
- forge.py wired to loader at all three hook points; `on_html` runs
  post-nav-injection per contract.
- Scenario 1 (both plugins): tok- spans present AND feed.xml parses.
- Scenario 2 (`"plugins": []`): zero tok- spans anywhere, no feed.xml —
  genuinely opt-in.
- Scenario 3 (raising plugin): nonzero exit, name in stderr.

## Evals
No visual/TUI surface in this subtree (themes/screenshot goldens are sibling
scope in parent PRD). Visual evals N/A here; all applicable checks executed
and green.

## Integration verdict — PASS
Loader + both shipped plugins + host pipeline compose in one run; all three
subsystem acceptance scenarios pass end-to-end against sibling `mdcore.py`.

Minor (non-blocking): unpaired apostrophe inside a python block can mislabel
trailing text as `tok-com` (alternation order artifact) — cosmetic only, not
a spec'd edge case, output remains valid HTML.

VERDICT: PASS
