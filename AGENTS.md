# Agent directives

## Backlog.md
- Run `backlog instructions overview` before any task-touching action.
- NEVER edit `backlog/**/*.md` directly — `backlog` CLI only (metadata + history integrity).

## Engine conventions
- `engine/build.mk` is the whole engine; project Makefile = `include engine/build.mk` (+ optional `GOAL`/`B`/`SRC`/`AGENT` overrides).
- `engine/agent` is the harness adapter (roles: `plan | build <id> | review`); prompts are `${VAR}` templates in `engine/prompts/`.
- Every build artifact must have a gate (jq check, `check.sh`, grep verdict). `.DELETE_ON_ERROR` stays.
- Smoke-test engine changes with a mock agent (no LLM calls) before wiring real harnesses.
- Evals: `evals/snap` (screenshot) + `evals/evalshot` (SSIM golden); research docs in `evals/docs/`.
