#!/usr/bin/env bash
# Self-test: example validates against schema; broken instances rejected.
set -euo pipefail
cd "$(dirname "$0")"

# both files parse as JSON
python3 -m json.tool progress.schema.json > /dev/null
python3 -m json.tool example.json > /dev/null

# validator one-liner: example must pass
python3 validate.py progress.schema.json example.json

# negative tests: mutated instances must fail
tmp=$(mktemp); trap 'rm -f "$tmp"' EXIT

python3 -c "import json; d=json.load(open('example.json')); del d['totals']; json.dump(d, open('$tmp','w'))"
if python3 validate.py progress.schema.json "$tmp" 2>/dev/null; then
  echo "FAIL: missing 'totals' accepted"; exit 1
fi

python3 -c "import json; d=json.load(open('example.json')); d['percent']=150; json.dump(d, open('$tmp','w'))"
if python3 validate.py progress.schema.json "$tmp" 2>/dev/null; then
  echo "FAIL: percent>100 accepted"; exit 1
fi

python3 -c "import json; d=json.load(open('example.json')); d['timestamp']='not-a-date'; json.dump(d, open('$tmp','w'))"
if python3 validate.py progress.schema.json "$tmp" 2>/dev/null; then
  echo "FAIL: bad timestamp accepted"; exit 1
fi

echo "json-schema-def: OK"
