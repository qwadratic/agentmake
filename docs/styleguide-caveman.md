# Prose styleguide: caveman at HIGH compression

Voice doc for every `.md` in this repo. Target level is **HIGH** — terse but
readable, not lobotomized. Calibrated below on five real paragraphs from
[README.md](../README.md) and [engine-internals.md](engine-internals.md).

## The three levels

| level | prose reduction | what it sounds like |
|---|---|---|
| mild | ~5–10% | original minus obvious filler; sentence structure intact |
| **HIGH (target)** | **30–40%** | short complete sentences dominate; fragments where meaning is instant; articles kept where dropping them creates ambiguity |
| maximal | ~40–55% | fragments and `→` arrows dominate; reads like notes, loses narrative — do not ship |

## The metric

Char reduction on **compressible prose**: paragraph chars minus inline code
spans and link destinations (those are untouchable, so counting them dilutes
the number). Headings, tables, code blocks: excluded entirely — never edited.

Measure: strip `` `...` `` spans and `](...)` link targets from before and
after, compare lengths. Target band **30–40%** per paragraph. A paragraph
already dense (short, no hedging) may land under 30% — do not force it past
meaning to hit the number.

## HIGH rules

**Cut, always:**

1. Filler openers — "This is", "There is", "Note that", "It's worth noting",
   "The part after X is" → "After X is".
2. Hedging — "would", "happily", "essentially", "basically", "in general",
   "for the most part". State what happens, not what would tend to happen.
3. Marketing adjectives — "powerful", "simple", "elegant", "seamless".
   Numbers and mechanisms already sell; adjectives dilute.
4. Redundant clauses — anything restating what an adjacent sentence, code
   block, or table already carries. One paraphrase max; the second dies.
5. Double qualification — "the finished run", "the untouched remainder",
   "sitting two directories up" → "the run", "the rest", "two dirs up".
6. Weak verb + noun → strong verb: "came back green" → "green",
   "make would see the file, consider the target up to date" →
   "make sees the file, calls it up to date".
7. `if X then Y` narration → cause list: "If an agent crashes, times out, or
   its gate rejects the result, the target file exists on disk but is
   garbage" → "Crash, timeout, or gate rejection leaves a garbage target on
   disk."

**Keep, always:**

8. Articles where removal creates ambiguity or telegraph-speak. "the failed
   one restarts" stays; "failed one restarts" is maximal-tier, not HIGH.
9. Complete sentences as the default. A fragment earns its place only when
   the meaning is instant ("Both were failures." / "Missing: agent
   thinking."). Roughly: fragments < ⅓ of sentences.
10. Narrative order in stories (dogfood, self-host). Compress the sentences,
    not the arc.
11. Repo idiom — "gate", "sentinel", "census", "swarm", "fan-out" are load
    bearing vocabulary, never synonymized away.

**Never touch (verbatim, any level):**

- Code blocks, inline code spans, commands, flags, paths.
- Numbers, scores, sizes, costs (33 bytes, 17/17, $0.27–$1.97, ~190 ms).
- Tables (structure and cells), headings, links (text may compress,
  destination never).
- Honesty labels and disclaimers, verbatim: **UNVERIFIED-LOCALLY**,
  "e2e blocked on creds", "designed, not default", "single-run trends",
  "interpretive proxy"-class caveats, the asciinema idle-cap note. These are
  trust artifacts; compressing them is lying by omission.
- Proper names (GNU make, Backlog.md, Claude Code, TOON, mermaid, ffmpeg).
- Quoted material (goal texts, `VERDICT: PASS`, the order-only aphorism).

## Calibrated pairs

Five real paragraphs. Percentages are prose-only reduction (metric above).
HIGH column is the ship target.

### 1. `.DELETE_ON_ERROR` (engine-internals.md) — orig 402 chars

**Original:**

> Agents write their output *while* running. If an agent crashes, times out, or its gate rejects the result, the target file exists on disk but is garbage. Without this directive, make would see the file, consider the target up to date, and happily build everything downstream on top of a half-written plan. With it, make deletes the target of any failed recipe, so the next run rebuilds it from scratch.

**Mild (−5.7%):**

> Agents write their output *while* running. If an agent crashes, times out, or its gate rejects the result, the target file is on disk but garbage. Without this directive, make would see the file, consider it up to date, and build everything downstream on top of a half-written plan. With it, make deletes the target of any failed recipe, so the next run rebuilds it from scratch.

**HIGH (−30.1%) ← target:**

> Agents write output *while* running. Crash, timeout, or gate rejection leaves a garbage target on disk. Without the directive, make sees the file, calls it up to date, builds downstream on a half-written plan. With it, a failed recipe's target is deleted; the next run rebuilds it.

**Maximal (−42.3%) — too far:**

> Agents write output while running. Crash/timeout/gate-reject → garbage target on disk. No directive: make sees file, thinks done, builds downstream on half-written plan. Directive: failed recipe → target deleted → next run rebuilds.

### 2. Order-only prerequisites (engine-internals.md) — orig 409 prose chars

**Original:**

> The part after `|` is an *order-only* prerequisite: `build/` must exist before the recipe runs, but its timestamp is ignored. That distinction matters for directories — a directory's mtime changes every time any file inside it is created, so a normal prerequisite on `$(B)` would make every artifact look perpetually stale and rebuild the world on each run. Order-only says "make sure it's there, then never look at it again."

**Mild (−4.2%):**

> The part after `|` is an *order-only* prerequisite: `build/` must exist before the recipe runs, but its timestamp is ignored. That matters for directories — a directory's mtime changes every time a file inside it is created, so a normal prerequisite on `$(B)` would make every artifact look perpetually stale and rebuild the world each run. Order-only says "make sure it's there, then never look at it again."

**HIGH (−30.6%) ← target:**

> After `|` is an *order-only* prerequisite: `build/` must exist before the recipe runs; timestamp ignored. Directory mtime changes with every file created inside, so a normal prerequisite on `$(B)` marks every artifact perpetually stale. Order-only: "make sure it's there, then never look at it again."

**Maximal (−54.3%) — too far:**

> `|` = order-only prerequisite: `build/` must exist, timestamp ignored. Directory mtime changes per file created → normal prereq on `$(B)` = everything always stale. Order-only: exists, then never checked.

(Maximal also mangled the quoted aphorism — rule violation, second reason it fails.)

### 3. Resume semantics (engine-internals.md) — orig 510 prose chars

**Original:**

> This is make's founding feature, and agents get it for free: a target whose prerequisites are older than itself is skipped. Kill a run at any point — Ctrl-C, laptop lid, crashed agent — and rerunning `make` re-executes only what is missing or stale. Finished components (their `.done` sentinels intact) are never rebuilt; the failed one (deleted by `.DELETE_ON_ERROR`) restarts; the untouched remainder proceeds. There is no "resume mode" because resuming is the default behavior of the tool. `make clean` (`rm -rf build/ src/`) is the only way to start over, deliberately.

**Mild (−8.0%):**

> Make's founding feature, and agents get it for free: a target whose prerequisites are older than itself is skipped. Kill a run at any point — Ctrl-C, laptop lid, crashed agent — and rerunning `make` re-executes only what is missing or stale. Finished components (`.done` sentinels intact) are never rebuilt; the failed one (deleted by `.DELETE_ON_ERROR`) restarts; the rest proceeds. There is no "resume mode" because resuming is the default behavior. `make clean` (`rm -rf build/ src/`) is the only way to start over, deliberately.

**HIGH (−30.8%) ← target:**

> Make's founding feature, free for agents: a target newer than its prerequisites is skipped. Kill a run anywhere — Ctrl-C, laptop lid, crashed agent — rerun `make`; only missing or stale work reruns. `.done` components never rebuild; the failed one (deleted by `.DELETE_ON_ERROR`) restarts; the rest proceeds. No "resume mode" — resume is the default. Starting over is deliberate: `make clean` (`rm -rf build/ src/`).

**Maximal (−44.7%) — too far:**

> Make's founding feature, free: target newer than prerequisites → skipped. Kill run anywhere (Ctrl-C, lid, crash), rerun `make` → only missing/stale re-executes. `.done` intact → never rebuilt; failed (deleted by `.DELETE_ON_ERROR`) → restarts; rest proceeds. No "resume mode" — resume is default. Start over: `make clean` (`rm -rf build/ src/`).

### 4. `make demo-mock` (README.md) — orig 592 prose chars

**Original:**

> Hacking on the *engine* rather than building something? `make demo-mock` runs the entire pipeline — classify → plan → parallel builds → review gate, including one composite component recursing into its own nested subtree — with [a 60-line bash stub](../engine/fixtures/mock-agent) standing in for the LLM: ~1s, zero tokens burned. It ends with the progress census, the mermaid dependency graph (nested subgraph included), and a `wfcheck` grade of the finished run (17/17). What you *don't* see is agents thinking; everything else — the DAG, the gates, the resume semantics — is exactly what real runs use. `bin/create-mvp --runtime mock "..."` is the same stub behind the one-shot CLI.

**Mild (−4.4%):**

> Hacking on the *engine* rather than building something? `make demo-mock` runs the entire pipeline — classify → plan → parallel builds → review gate, including one composite recursing into its own nested subtree — with [a 60-line bash stub](../engine/fixtures/mock-agent) standing in for the LLM: ~1s, zero tokens. It ends with the progress census, the mermaid dependency graph (nested subgraph included), and a `wfcheck` grade of the run (17/17). What you *don't* see is agents thinking; everything else — the DAG, the gates, the resume semantics — is exactly what real runs use. `bin/create-mvp --runtime mock "..."` is the same stub behind the one-shot CLI.

**HIGH (−33.4%) ← target:**

> Hacking on the *engine*? `make demo-mock` runs the full pipeline — classify → plan → parallel builds → review gate, one composite subtree included — with [a 60-line bash stub](../engine/fixtures/mock-agent) as the LLM: ~1s, zero tokens. Ends with the census, the mermaid graph (nested subgraph), and a `wfcheck` grade (17/17). Missing: agent thinking. The DAG, gates, and resume semantics are what real runs use. `bin/create-mvp --runtime mock "..."` — same stub behind the one-shot CLI.

**Maximal (−53.4%) — too far:**

> Engine hacking? `make demo-mock` = full pipeline (classify → plan → parallel builds → review gate, one composite subtree) with [a 60-line bash stub](../engine/fixtures/mock-agent) as LLM: ~1s, zero tokens. Ends: census, mermaid graph (nested subgraph), `wfcheck` 17/17. Missing: agent thinking. DAG/gates/resume = real. Same stub: `bin/create-mvp --runtime mock "..."`.

### 5. Dogfood story (README.md) — orig 665 prose chars

**Original:**

> We pointed the engine at its own repo — one ad-hoc `goal.md` per engine improvement, the tool's own documented workflow. Both runs came back green: every `check.sh` passed, both reviews said `VERDICT: PASS`. And both were failures. Asked to integrate with "our backlog board", the agents never found the real board sitting two directories up — they invented their own board format and built a gate-passing pipeline against their own fixtures. The other run left a stray `report.md` at the wrong level and reached outside its run dir. Root of the repo: two clutter directories, two orphan `effort.json`, zero improvements landed. The full mess is committed verbatim (now under [`docs/dogfood/`](dogfood/)) and dissected in [docs/dogfood-autopsy.md](dogfood-autopsy.md).

**Mild (−2.3%):**

> We pointed the engine at its own repo — one ad-hoc `goal.md` per engine improvement, the tool's own documented workflow. Both runs came back green: every `check.sh` passed, both reviews said `VERDICT: PASS`. And both were failures. Asked to integrate with "our backlog board", the agents never found the real board two directories up — they invented their own board format and built a gate-passing pipeline against their own fixtures. The other run left a stray `report.md` at the wrong level and reached outside its run dir. Repo root: two clutter directories, two orphan `effort.json`, zero improvements landed. The full mess is committed verbatim (now under [`docs/dogfood/`](dogfood/)) and dissected in [docs/dogfood-autopsy.md](dogfood-autopsy.md).

**HIGH (−30.2%) ← target:**

> We pointed the engine at its own repo — one ad-hoc `goal.md` per improvement. Both runs green: every `check.sh` passed, reviews said `VERDICT: PASS`. Both were failures. Asked to integrate with "our backlog board", the agents never found the real board two dirs up — invented their own, gate-passed their own fixtures. The other left a stray `report.md` outside its run dir. Repo root: two clutter dirs, two orphan `effort.json`, zero improvements. Mess committed verbatim under [`docs/dogfood/`](dogfood/), dissected in [docs/dogfood-autopsy.md](dogfood-autopsy.md).

**Maximal (−43.3%) — too far:**

> Engine pointed at own repo — one ad-hoc `goal.md` per improvement. Both runs green, `VERDICT: PASS` twice. Both failures. "our backlog board" ask → real board two dirs up never found; invented own format, gate-passed own fixtures. Other run: stray `report.md`, escaped run dir. Repo root: two clutter dirs, two orphan `effort.json`, zero improvements. Mess committed verbatim under [`docs/dogfood/`](dogfood/), dissected in [docs/dogfood-autopsy.md](dogfood-autopsy.md).

(Maximal drops the narrative beat "Asked to integrate…never found" — the
story's punchline flattens into a symbol chain. That is the tell you've
overshot HIGH.)

## Aggregate

| pair | orig prose | HIGH prose | reduction |
|---|---|---|---|
| 1 `.DELETE_ON_ERROR` | 402 | 281 | −30.1% |
| 2 order-only | 409 | 284 | −30.6% |
| 3 resume | 510 | 353 | −30.8% |
| 4 demo-mock | 592 | 394 | −33.4% |
| 5 dogfood | 665 | 464 | −30.2% |
| **total** | **2578** | **1776** | **−31.1%** |

## Self-check before shipping a rewrite

1. Diff the paragraph: every number, code span, link destination, quote, and
   honesty label byte-identical? If not, revert those spans.
2. Read the HIGH version aloud once. Any sentence you had to re-read → it
   crossed into maximal; restore an article or split the fragment.
3. Prose-only reduction in 30–40%? Under 30 on an already-dense paragraph is
   fine. Over 40 means check rule 8–10 violations before celebrating.
