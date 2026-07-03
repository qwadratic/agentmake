---
id: TASK-18
title: Whole-tree leaf census (progress.json rollup)
status: To Do
assignee: []
created_date: '2026-07-03 22:20'
labels: []
dependencies: []
ordinal: 17000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Deferred item from docs/rfc-nested.md §12 + judge criterion 'census truthfulness mid-flight' (design A's recorded loss to B in the TASK-11 adjudication). Today make progress shows per-level bars and recurses, but there is no single truthful whole-tree leaf count — a composite counts as 1 at the parent regardless of subtree size. Build: per-level progress.json + jq aggregation so one number answers 'how many leaves total / done' across the tree. Recovers B's census win without flattening. Existing dogfood-progress-json/ dir is prior art.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 make progress emits whole-tree leaf census (total/done) aggregated across all depths
- [ ] #2 Flat runs unchanged (byte-identical output or strict superset)
- [ ] #3 nested-selftest asserts census correctness on the 2-level mock tree
<!-- AC:END -->
