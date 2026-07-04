#!/bin/sh
# json-emitter self-test: emit -> json parse check + schema validation.
set -eu
cd "$(dirname "$0")"

out=$(mktemp)
trap 'rm -f "$out"' EXIT

# fixture: real repo build dir (two dirs up)
python3 emit.py ../../build > "$out"

# 1. valid JSON
python3 -m json.tool "$out" > /dev/null

# 2. schema-conformant
python3 ../json-schema-def/validate.py ../json-schema-def/progress.schema.json "$out"

# 3. sanity: totals consistent
python3 - "$out" <<'EOF'
import json, sys
d = json.load(open(sys.argv[1]))
assert 0 <= d["totals"]["done"] <= d["totals"]["total"]
assert sum(s["done"] for s in d["sections"]) == d["totals"]["done"]
EOF

echo "json-emitter: OK"
