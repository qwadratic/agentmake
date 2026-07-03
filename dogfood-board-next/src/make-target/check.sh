#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
MAKEFILE=$PWD/Makefile

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
cp ../board-reader/fixtures/board.md "$tmp/board.md"

# 1) first run creates goal.md
( cd "$tmp" && make -f "$MAKEFILE" next-goal >/dev/null )
[ -f "$tmp/goal.md" ] || { echo "FAIL: goal.md not created"; exit 1; }
grep -q '^# Goal$' "$tmp/goal.md" || { echo "FAIL: goal.md missing '# Goal'"; exit 1; }
grep -qF 'Fix login redirect' "$tmp/goal.md" || { echo "FAIL: task title missing"; exit 1; }

# 2) rerun without FORCE -> nonzero exit, file untouched
before=$(cat "$tmp/goal.md")
if ( cd "$tmp" && make -f "$MAKEFILE" next-goal >/dev/null 2>&1 ); then
  echo "FAIL: expected nonzero exit on existing goal.md"; exit 1
fi
[ "$before" = "$(cat "$tmp/goal.md")" ] || { echo "FAIL: goal.md modified without FORCE"; exit 1; }

# 3) FORCE=1 overwrites successfully
( cd "$tmp" && make -f "$MAKEFILE" next-goal FORCE=1 >/dev/null )
grep -q '^# Goal$' "$tmp/goal.md" || { echo "FAIL: FORCE rewrite broken"; exit 1; }

echo "OK"
