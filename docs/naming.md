# Naming decision

**WINNER=cook POSTURE=HYBRID** — repo stays `qwadratic/agentmake`, CLI binary is `cook`.
Runner-up: **makex**.

Adjudicated 2026-07-04. Weighting applied: gh+npm collision (hard filter) > verb-ability in one-shot API > SEO > lineage.

## Verdict rationale

The product IS the sentence: `cook "an extension that makes all websites pink"`.
Verb-ability is the second-highest weight and `cook` wins it outright — grammatical
imperative, zero cognitive translation, "let him cook" meme as free cultural verb
for watching agents work. Every other survivor is a noun in the mouth.

The hard filter (gh+npm both free) kills bare `cook` as a *package* name:

- GitHub `cook/cook`: FREE
- npm `cook`: TAKEN — "Coming soon" placeholder, 157 dl/mo (squat, not a product)

HYBRID dissolves the filter instead of failing it — the **ripgrep/rg pattern**:

| Surface | Name | Status |
|---|---|---|
| GitHub repo | `qwadratic/agentmake` | already owned, publish in flight |
| npm package | `agentmake` | package name ≠ brand verb |
| CLI binary | `cook` | no PATH conflict (checked bash/zsh/fish); Cooklang CLI niche, Peter Miller's `cook` dead ~2008 |
| SEO query | "agentmake cook" | repo name carries findability; binary carries the verb |

Posture consequences:

- **Zero interference** with the publish workflow currently pushing `agentmake` — no rename, no redirect dance, no mid-push fight.
- Bare-"cook" SEO hell (101k★ recipe repos, cookbook-suffixed LLM repos) is routed around: nobody searches bare "cook", they search the repo/package name.
- npm squat becomes irrelevant; optional later: npm dispute for the placeholder if the brand hardens.

## Runner-up: makex

Only candidate fully clean on the hard filter (gh FREE, npm FREE, brew FREE, crates FREE).
Perfect lineage signal ("agentic successor to Make"), perfectly searchable. Loses on the
second weight: verb-dead — "makex me an app" clunks, pronunciation forks (make-ex/may-kex),
`-x` suffix is 2015-devtools patina. Also PyPI `makex` is an *active build tool* by
meta.company — direct semantic collision on one registry. Keep as fallback binary name
if `cook` develops a real PATH conflict.

## Rejected — one-liners

- **forge** — Foundry ships a binary literally named `forge` on dev machines (this one included); collision apocalypse. Fatal.
- **brew** — Homebrew. Fatal for macOS dev audience.
- **rig** — 0xPlaygrounds/rig 7.8k★ Rust LLM framework, exact same agent space. Fatal.
- **summon** — CyberArk ships a real `summon` binary (secrets injection); actual PATH conflict, not just SEO.
- **whisk** — Google Whisk (AI image gen) direct AI-space collision.
- **bake** — `docker buildx bake` active on the same semantic turf; PyPI bake = automation orchestrator.
- **ship** — over-promises (ship = deploy, tool builds); idiom so common spoken references are lossy; generic SEO hell.
- **conjure** — 7 chars breaks limit, npm taken, Palantir/neovim pollution, magic-metaphor tools age badly.
- **whip** — npm taken, WHIP (WebRTC) owns the dev namespace.
- **yoke** — icu4x `yoke` 418M crate downloads; verb means *harness*, not *create*.
- **spin** — Fermyon Spin direct dev-tool collision.
- **poof** — most memorable, but intransitive ("poof me an app" is a joke) and enterprise-hostile.
- **remake** — existing enhanced-GNU-make debugger; semantics say *redo*, not *create*.
- **wright** — Playwright typo magnet; noun.
- **stir / fry / simmer / sous / smith / lathe / hew** — semantic or grammatical failures (don't produce, slow-heat, not verb-able, archaic, opaque).
- **makeup** — rejected pre-scoring; cosmetics owns 100% of SEO.
