#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

# 1) explicit file arg
out=$(node board-reader.js fixtures/board.md)
expected='{"id":"task-1","title":"Fix login redirect","body":"Users land on 404 after login.\nShould go to /dashboard."}
{"id":"task-2","title":"Add dark mode","body":""}'
[ "$out" = "$expected" ] || { echo "FAIL: explicit file output mismatch"; echo "$out"; exit 1; }

# 2) auto-discovery via --root
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
cp fixtures/board.md "$tmp/backlog.md"
out2=$(node board-reader.js --root "$tmp")
[ "$out2" = "$expected" ] || { echo "FAIL: --root discovery mismatch"; exit 1; }

# 3) missing board -> nonzero exit
if node board-reader.js --root "$tmp/nope" 2>/dev/null; then
  echo "FAIL: expected nonzero exit for missing board"; exit 1
fi

echo "OK"
