# Review: dogfood-board-next vs goal.md

Goal: make target pulls next todo task from backlog board, turns it into `goal.md` engine can build.

## Components

**board-reader** — PASS. Parses `## column` markdown board, auto-discovers common filenames via `--root`, emits todo tasks as JSONL. Handles checkboxes, indented bodies, missing-board error. check.sh: OK.

**next-task-selector** — PASS. Picks first task from stdin JSONL (top-of-column = next). Clear error on empty todo + invalid JSON. check.sh: OK (includes pipe test from board-reader).

**goal-md-generator** — PASS. Emits `# Goal` / `## Constraints` / `## Done criteria`; `Acceptance:` marker in body becomes done criteria, sensible fallback otherwise. Validates missing title / bad JSON. check.sh: OK.

**make-target** — PASS. `next-goal` target pipes reader → selector → generator; `BOARD`/`ROOT`/`OUT` vars; refuses overwrite without `FORCE=1` (no data loss). check.sh: OK (create, no-clobber, force-overwrite). Note: harmless `jobserver unavailable` warning from recursive make in check — cosmetic only.

## Integration

Full chain exercised twice: selector and generator checks pipe from real board-reader fixture, and make-target check runs whole pipeline end-to-end in temp dir producing valid goal.md containing `# Goal` + task title. Matches goal.md intent. All 4 check.sh scripts pass.

Minor observations (non-blocking): board task IDs are position-based (unstable across edits); blank line inside task body closes the task — both acceptable MVP shortcuts, documented in comments.

VERDICT: PASS
