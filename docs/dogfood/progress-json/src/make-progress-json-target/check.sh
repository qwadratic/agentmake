#!/bin/sh
# make-progress-json-target self-test: target emits valid JSON only, exit 0.
set -eu
cd "$(dirname "$0")"

out=$(mktemp); err=$(mktemp)
trap 'rm -f "$out" "$err"' EXIT

# 1. exits 0, stdout is valid JSON
# env -u: strip inherited MAKEFLAGS (CI may run this under a parent make)
env -u MAKEFLAGS -u MFLAGS make -s progress-json > "$out" 2> "$err"
python3 -m json.tool "$out" > /dev/null

# 2. no log noise: stderr empty, stdout exactly one line
[ ! -s "$err" ] || { echo "FAIL: stderr not empty"; cat "$err"; exit 1; }
[ "$(wc -l < "$out")" -eq 1 ] || { echo "FAIL: stdout not single JSON line"; exit 1; }

echo "make-progress-json-target: OK"
