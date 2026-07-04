# Runtime matrix — same goal, different agent CLIs

Complement to `matrix-results.md` (multi-MODEL, pi runtime). This table is
multi-RUNTIME: each installed+authed `ENGINE_CLI` preset drives the SAME real
build via `bin/create-mvp --runtime cli --tier vague` in a fresh `/tmp/rtm-<agent>`.

Goal (fixed): `word frequency counter cli, python stdlib, with golden output test`

Auth probed cheaply first (trivial `-p`/`exec` prompt); unauthed or missing
CLIs get honest rows, no fake runs. Retries = manual `--resume` reruns needed.

| agent | installed | authed | completed | wfcheck | score | wall (s) | retries | notes |
|---|---|---|---|---|---|---|---|---|
| `claude` (default) | yes | **no** | — | — | — | — | — | probe: `401 Invalid authentication credentials`; no `~/.claude/.credentials.json`, no `ANTHROPIC_*` env. TASK-16 stays open |
| `pi` | yes | yes | yes | 16/16 | 1 | 140 | 0 | review VERDICT: PASS; 3 components (core, cli, golden-test) |
| `codex` | yes | **no** | — | — | — | — | — | probe: `Your workspace is out of credits` — reaches auth boundary, adapter untestable e2e here |
| `gemini` | no | — | — | — | — | — | — | not installed; preset UNVERIFIED-LOCALLY |
| `opencode` | no | — | — | — | — | — | — | not installed; preset UNVERIFIED-LOCALLY |

_Single run per agent, one host, 2026-07-04 — trend, not benchmark. claude/codex
adapters verified to the auth boundary only (plumbing correct, credentials absent);
`engine/selfcheck-argv.sh` golden-checks all preset argv shapes without agent calls._
