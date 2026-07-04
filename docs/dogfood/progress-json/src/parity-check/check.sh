#!/bin/sh
# parity-check self-test: `make progress` numbers == `make progress-json` fields.
set -eu
cd "$(dirname "$0")"

ROOT=../..
human=$(mktemp); jsonf=$(mktemp)
trap 'rm -f "$human" "$jsonf"' EXIT

# env -u: strip inherited MAKEFLAGS (may run under parent make)
env -u MAKEFLAGS -u MFLAGS make -s -C "$ROOT" progress > "$human"
env -u MAKEFLAGS -u MFLAGS make -s -C "$ROOT/src/make-progress-json-target" progress-json > "$jsonf"

python3 parity.py "$human" "$jsonf"
echo "parity-check: OK"
