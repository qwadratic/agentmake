---
id: TASK-16
title: Claude-runtime e2e verification
status: To Do
assignee: []
created_date: '2026-07-03 20:28'
updated_date: '2026-07-04 01:50'
labels: []
dependencies: []
ordinal: 15000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
ENGINE_CLI=claude plumbing exists (flag mapping, stdin quirk handled, system-prompt injection) and reaches the auth boundary (401 without creds). Never verified end-to-end on a real build. On a machine with claude CLI creds: run one demo (game-of-life) with ENGINE_CLI=claude, confirm classify/plan/build/review gates all pass, record wfcheck score, note any flag-mapping fixes. Judge flagged as environmental-not-code — this task closes the loop.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 make demo DEMO=game-of-life with ENGINE_CLI=claude completes all gates
- [ ] #2 wfcheck score recorded in evals/matrix-results.md or a runtime note
- [ ] #3 Any ENGINE_CLI=claude flag/stdin fixes committed with a mock-agent smoke test
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
E2E matrix run 2026-07-04 (evals/runtime-matrix.md): claude CLI installed but UNAUTHED on this host — 'claude -p' probe returns 401 Invalid authentication credentials, no ~/.claude/.credentials.json, no ANTHROPIC_API_KEY/AUTH_TOKEN env. Adapter plumbing reaches auth boundary as designed; e2e still blocked environmentally. codex also blocked (workspace out of credits). pi baseline on same fixed goal: wfcheck 16/16 score 1, 140s, 0 retries, review PASS. Task stays open until a claude-authed host runs it.
<!-- SECTION:NOTES:END -->
