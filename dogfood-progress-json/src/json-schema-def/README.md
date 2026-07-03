# json-schema-def

Stable JSON schema for `make progress-json` output.

## Files

- `progress.schema.json` — JSON Schema (draft 2020-12)
- `example.json` — canonical example instance
- `validate.py` — stdlib-only validator (no network deps): `python3 validate.py progress.schema.json example.json`
- `check.sh` — self-test

## Contract (v1.0.0)

```json
{
  "version": "1.0.0",
  "timestamp": "2026-07-03T12:00:00Z",
  "totals": { "done": 7, "total": 12 },
  "percent": 58.3,
  "sections": [
    { "name": "core", "done": 4, "total": 5 }
  ]
}
```

- `version`: schema semver string; bump on breaking change
- `timestamp`: ISO 8601 UTC of census run
- `totals.done` / `totals.total`: non-negative integers, whole-repo counts
- `percent`: 0–100, `done/total*100` rounded to 1 decimal, `0` if total is 0
- `sections[]`: per-section `{name, done, total}`, same order as human `make progress` output
- No extra keys allowed anywhere (`additionalProperties: false`) — keeps output stable for scripts

Emitter (`json-emitter`) must produce instances that pass `validate.py`.
