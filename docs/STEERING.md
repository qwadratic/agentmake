# STEERING — mandatory directive for all agents in this repo

Audience: builders, judges, fixers, synthesis. Judges: treat the acceptance
criteria below as RELEASE REQUIREMENTS — anything missing is CRITICAL.
This directive extends (does not replace) existing task instructions.

## The arc (execute in order)

1. DOGFOOD FIRST. Before polishing anything else: attempt to develop this
   tool WITH ITSELF. Engine improvements driven by make — one goal.md per
   improvement, engine pipeline runs the build agents on its own codebase.

2. LET THE MESS HAPPEN — HONESTLY. The attempt will yield a directory of
   individual build phases, one-off goal.md prompts, scattered build/ dirs,
   orphan effort.json files. Do NOT hide or pre-clean it. Capture evidence:
   tree snapshot + short autopsy -> docs/dogfood-autopsy.md. The mess is the
   argument: ad-hoc goal files do not scale as a work queue.

3. THEREFORE: install backlog.md as the DEFAULT BOARD of this make agent.
   Board = source of goals. Task = goal unit. Engine integration target:
   make board-next -> pulls next todo task via backlog CLI -> materializes
   goal.md -> runs pipeline -> gates pass -> task marked done via CLI.
   Backlog CLI ONLY — never edit backlog/**/*.md directly.

4. SELF-HOST. Put a SINGLE task on the board: "Build agentmake with
   agentmake". Point the engine at the board. Let it DECOMPOSE that task
   (plan.json from task content) and build itself from the board. Keep run
   artifacts as proof.

## Acceptance criteria (judges: CRITICAL if missing)

- docs/dogfood-autopsy.md — real pre-cleanup tree + what went wrong + why a board
- engine/board.mk (or equivalent) — backlog as default board; make board-next works end-to-end
- board contains the single self-host task, decomposed by the engine, subtasks completed on gate pass
- README section: the dogfood story (mess -> board) as the motivating narrative for board-as-default
