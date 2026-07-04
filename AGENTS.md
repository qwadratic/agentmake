# Agent directives

## Backlog.md
- Run `backlog instructions overview` before any task-touching action.
- NEVER edit `backlog/**/*.md` directly — `backlog` CLI only (metadata + history integrity).

## Engine conventions
- `engine/build.mk` is the whole engine; project Makefile = `include engine/build.mk` (+ optional `GOAL`/`B`/`SRC`/`AGENT` overrides).
- `engine/agent` is the harness adapter (roles: `plan | build <id> | review`); prompts are `${VAR}` templates in `engine/prompts/`.
- Runtime knobs: `RUNTIME=cli|sdk` (sdk = `engine/runtime-sdk.mjs`, pi SDK), `ENGINE_CLI=claude(default)|pi|codex|gemini|opencode|custom` (+`ENGINE_CLI_CUSTOM` template), `ENGINE_CLI_FLAGS` passthrough. Every call injects `engine/prompts/system.md` (caveman+ponytail). Optional `$B/effort.json` routes model/thinking per unit (`units{unit→tier}`, `tiers{tier→{model,thinking}}`).
- Every build artifact must have a gate (jq check, `check.sh`, grep verdict). `.DELETE_ON_ERROR` stays.
- Smoke-test engine changes with a mock agent (no LLM calls) before wiring real harnesses.
- Evals: `evals/snap` (screenshot) + `evals/evalshot` (SSIM golden); research docs in `evals/docs/`.

## STEERING (historical)
Original build directive preserved at docs/STEERING.md. Its acceptance criteria are met (see docs/STATE.md); kept as record of the self-steering build, no longer enforced.
