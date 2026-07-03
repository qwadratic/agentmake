---
id: TASK-19
title: Cross-subtree deps + shared sibling artifact store
status: To Do
assignee: []
created_date: '2026-07-03 22:20'
labels: []
dependencies: []
ordinal: 18000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Two related judge-surfaced ceilings from TASK-11: (1) cross-subtree dependency edges are inexpressible in the recursive-make design — a leaf in subtree X cannot depend on a leaf in subtree Y, only whole-composite ordering at the parent (rfc-nested adjudication, A's -j utilization loss; §12 defers a 'flatten hybrid' if a workload needs it). (2) Sibling integration is copy-based: components copy files per description contract, no shared artifact store, so a subtree can drift from the sibling it copied (STATE ceiling #3). Investigate together — a shared build/artifacts/ contract likely solves both (dep edge = artifact path, freshness = mtime). Only one real-PRD composite datapoint exists (site-forge); gather one more before committing to a design.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Design note: artifact-store contract or flatten-hybrid, chosen with a second real-PRD datapoint
- [ ] #2 If built: cross-subtree dep expressible + mtime-correct resume, verified in nested-selftest
<!-- AC:END -->
