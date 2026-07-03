---
id: TASK-20
title: 'attn: interpretive attention visualizer (view + timeline)'
status: Done
assignee: []
created_date: '2026-07-03 23:28'
updated_date: '2026-07-03 23:35'
labels: []
dependencies: []
ordinal: 19000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Implement demoscene/attn per demoscene/ATTN-SPEC.md (attn-proxy/1). Single python3-stdlib script. Modes: 'attn view file.fs' (static ANSI token heatmap: category hue fg, weight bg, junction markers, honesty legend) and 'attn session|timeline trace.jsonl' (one frame per tool call, w_recency decay tau=6). JSON sidecar per spec section 5. HONESTY: exact string 'interpretive proxy — not model internals' in every frame legend + sidecar disclaimer; weights are grammar/session-derived proxy, NOT model attention.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 attn view renders compiler.fs with category colors, weight bg, junction gutter markers, legend every 40 lines
- [x] #2 attn timeline renders one frame per tool call from demoscene/session-trace.jsonl with recency glow + per-frame legend
- [x] #3 JSON sidecar emitted for both modes with top-level disclaimer, tokens/edges/frames per spec
- [x] #4 Golden self-check: fixed tiny .fs fixture -> stripped category/weight matrix == committed golden; disclaimer asserted in every mode output
- [x] #5 attn-proxy-check.py still passes; weights match its executable definition
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Weight formula matches attn-proxy-check.py exactly (its numbers are the executable definition): base 0.30 applies to def KEYWORDS only; def-site name tokens render cat 'def' but weigh via w_ref (ind@def 0.625 reproduced). Session parsing handles forth-tool calls: s" content" s" path" fwrite / fread / load extracted per call; ALL ops applied (fwrite-then-load in one call no longer loses the write); write diffs against in-session vfs, never post-session disk. Edge order made deterministic (defs was a set) — selfcheck green under PYTHONHASHSEED 0/1/2/42. Honesty: exact disclaimer in every frame legend (11/11 timeline frames), legend repeated every 40 lines in view, sidecar top-level disclaimer both modes.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Built demoscene/attn (python3 stdlib, single script): 'view' static ANSI heatmap (category fg, weight bg truecolor/256, junction gutter ◆/‣, --focus, --no-color/--tags fallback) and 'session'/'timeline' per-tool-call frames with recency decay tau=6; JSON sidecar per ATTN-SPEC §5. Verified: demoscene/attn-selfcheck.py (golden fixture render + category/weight matrix, spec §3 invariants, disclaimer in every mode) + attn-proxy-check.py. Artifacts: demoscene/out/{compiler,session}.attn.json.
<!-- SECTION:FINAL_SUMMARY:END -->
