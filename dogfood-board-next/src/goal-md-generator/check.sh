#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
out="$tmp/goal.md"

node goal-md-generator.js "$out" < fixtures/task.json

# required section headers
grep -q '^# Goal$' "$out" || { echo "FAIL: missing '# Goal'"; exit 1; }
grep -q '^## Constraints$' "$out" || { echo "FAIL: missing '## Constraints'"; exit 1; }
grep -q '^## Done criteria$' "$out" || { echo "FAIL: missing '## Done criteria'"; exit 1; }

# task text verbatim
grep -qF 'Fix login redirect' "$out" || { echo "FAIL: title missing"; exit 1; }
grep -qF 'Users land on 404 after login.' "$out" || { echo "FAIL: body missing"; exit 1; }
grep -qF 'after login user lands on /dashboard' "$out" || { echo "FAIL: acceptance missing"; exit 1; }

# invalid input -> nonzero exit
if node goal-md-generator.js "$tmp/nope.md" </dev/null 2>/dev/null; then
  echo "FAIL: expected nonzero exit for empty input"; exit 1
fi

# integration: full pipe from board-reader fixture
node ../board-reader/board-reader.js ../board-reader/fixtures/board.md \
  | node ../next-task-selector/next-task-selector.js \
  | node goal-md-generator.js "$tmp/goal2.md" 2>/dev/null
grep -q '^# Goal$' "$tmp/goal2.md" || { echo "FAIL: pipe integration"; exit 1; }

echo "OK"
