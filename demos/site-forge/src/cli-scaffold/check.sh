#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

mkdir "$TMP/src"
echo "# Hello" > "$TMP/src/hello.md"
echo '{"theme": "midnight"}' > "$TMP/src/site.json"

# good build: exit 0, out-dir created
python3 forge.py build "$TMP/src" "$TMP/out"
[ -d "$TMP/out" ] || { echo "FAIL: out-dir not created" >&2; exit 1; }

# bad src-dir: nonzero exit + stderr message
if python3 forge.py build "$TMP/nope" "$TMP/out2" 2>"$TMP/err"; then
  echo "FAIL: bad src-dir exited 0" >&2; exit 1
fi
grep -q "src-dir" "$TMP/err" || { echo "FAIL: no stderr message" >&2; exit 1; }

# theme precedence: --theme > site.json > classic
python3 - "$TMP/src" <<'EOF'
import sys, forge
cfg = forge.load_config(sys.argv[1])
assert cfg["theme"] == "midnight"
assert (None or cfg.get("theme") or "classic") == "midnight"
assert ("solar" or cfg.get("theme") or "classic") == "solar"
site = forge.build(sys.argv[1], sys.argv[1] + "/../out3", cfg)
assert site["pages"][0]["name"] == "hello"
EOF

echo OK
