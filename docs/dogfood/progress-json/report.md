# Review: progress census as JSON

Goal: `make progress` but machine-readable JSON for scripts.

## Per-component

| Component | Verdict | Notes |
|---|---|---|
| json-schema-def | PASS | Schema (draft 2020-12) + stdlib validator + example. check.sh: `valid`, OK. |
| progress-data-collector | PASS | Mirrors ARTIFACTS logic from build.mk (effort.json, plan.json, per-component .done, report.md). check.sh OK. |
| json-emitter | PASS | Maps collector output to schema shape, JSON on stdout only. check.sh validates against schema, OK. |
| make-progress-json-target | PASS | `make progress-json` target, BUILD_DIR overridable, clean stdout (`@`, `make -s`). check.sh OK. |
| parity-check | PASS | Cross-checks human `make progress` output vs JSON (done/total/percent/checkmarks/sections). check.sh OK. |

## Integration

End-to-end: `make -s -C src/make-progress-json-target progress-json BUILD_DIR=<fixture>` produced schema-valid JSON with correct counts (3/5 = 60.0%, and 1/3 = 33.3% on second fixture); validated with `validate.py progress.schema.json <out>` -> `valid`. Emitter imports collector directly; Makefile target wires emitter; parity component verifies numbers match human output. All five check.sh scripts pass.

Minor: `make` prints jobserver warning to stderr when nested, but stdout stays pure JSON — scripting use unaffected.

VERDICT: PASS
