---
id: TASK-17
title: Mid-flight re-planning for long trajectories
status: To Do
assignee: []
created_date: '2026-07-03 22:20'
labels: []
dependencies: []
ordinal: 16000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Judge-surfaced ceiling from TASK-11 nested-decomposition round (trajectory-fitness): plan.json is written once per (sub)tree and never revisited. Lazy planning means a subtree plans AFTER its deps exist (rfc-nested adjudication win), but once a plan lands it is frozen — a long trajectory cannot amend a plan when built reality diverges mid-subtree (e.g. a leaf's check.sh keeps failing because the decomposition itself was wrong, not the code). Today the only escape is a human rm build/plan.json. Explore: bounded re-plan trigger (N consecutive gate failures on a leaf => invalidate that subtree's plan.json with prior plan + failure log as context), same determinism rules as MAXDEPTH (make/jq-enforced, not prompt trust). Related: TASK-10 retry-with-feedback is the per-leaf version; this is the per-plan version.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Re-plan trigger is deterministic (make/jq), bounded (max re-plans per subtree), and off by default or clearly documented
- [ ] #2 Prior plan + gate failure output injected into the re-plan prompt
- [ ] #3 nested-selftest covers re-plan path with mock agent (zero LLM)
<!-- AC:END -->
