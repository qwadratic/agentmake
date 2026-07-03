#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

# 1) fixture with 3 tasks -> first picked
out=$(node next-task-selector.js < fixtures/three-tasks.jsonl)
expected='{"id":"task-1","title":"Fix login redirect","body":"Users land on 404 after login."}'
[ "$out" = "$expected" ] || { echo "FAIL: expected first task, got: $out"; exit 1; }

# 2) empty input -> nonzero exit with message
if out2=$(node next-task-selector.js </dev/null 2>&1); then
  echo "FAIL: expected nonzero exit for empty input"; exit 1
fi
echo "$out2" | grep -q "empty" || { echo "FAIL: missing clear empty message"; exit 1; }

# 3) integration: pipe from board-reader fixture
out3=$(node ../board-reader/board-reader.js ../board-reader/fixtures/board.md | node next-task-selector.js)
echo "$out3" | grep -q '"id":"task-1"' || { echo "FAIL: board-reader pipe mismatch"; exit 1; }

echo "OK"
