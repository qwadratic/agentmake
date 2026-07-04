#!/usr/bin/env bash
# Self-test: fixture build dir with 2 components, 1 done -> expect 3/5 done.
set -euo pipefail
cd "$(dirname "$0")"

fix=$(mktemp -d)
trap 'rm -rf "$fix"' EXIT
echo '{"components":[{"id":"a","deps":[]},{"id":"b","deps":["a"]}]}' > "$fix/plan.json"
echo '{"tier":"vague"}' > "$fix/effort.json"
touch "$fix/a.done"
# missing: b.done, report.md  => done=3 total=5

python3 - "$fix" <<'EOF'
import sys
from collect import collect
r = collect(sys.argv[1])
assert r["total"] == 5, r
assert r["done"] == 3, r
assert r["percent"] == 60, r
paths = [i["path"] for i in r["items"]]
assert paths[0].endswith("effort.json") and paths[-1].endswith("report.md"), paths
assert [i["done"] for i in r["items"]] == [True, True, True, False, False], r
# empty build dir edge case
import tempfile, os
r2 = collect(tempfile.mkdtemp())
assert r2["total"] == 3 and r2["done"] == 0 and r2["percent"] == 0, r2
print("OK")
EOF
