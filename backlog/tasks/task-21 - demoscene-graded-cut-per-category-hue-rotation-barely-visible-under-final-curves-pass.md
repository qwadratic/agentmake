---
id: TASK-21
title: >-
  demoscene graded cut: per-category hue rotation barely visible under final
  curves pass
status: Done
assignee: []
created_date: '2026-07-04 00:10'
updated_date: '2026-07-04 03:35'
labels: []
dependencies: []
ordinal: 20000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Judge-loop round 1 out-of-scope observation (non-CRITICAL, aesthetic). mk-grade.py keys hue rotation (0/120 deg) to ATTN token category per timeline segment, but the final curves pass (green phosphor tint) dominates the palette, so USR-vs-PRIM segments read as near-identical green; only the saturation heat pulse differentiates them. Category color is effectively conveyed by the drawtext label alone. Consider: apply category tint AFTER curves, or replace hue rotation with a category-colored glow/border, or drop rotation and lean on labels. Keep honesty label ('interpretive proxy - not model internals') burned into every frame regardless.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 USR (hue 120) vs PRIM (hue 0) segments visually distinguishable in a side-by-side frame extract without reading the ATTN label
- [ ] #2 probe render still self-terminates and full final-v1/v2 render 95.7s
- [ ] #3 honesty disclaimer still on every frame (spot-check 3 timestamps)
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
dropped: demoscene removed from repo (demos/forth-forth covers forth showcase); moot
<!-- SECTION:NOTES:END -->
