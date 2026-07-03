#!/usr/bin/env bash
# themes check: build fixture with both themes, assert CSS shipped + linked,
# snap + evalshot against committed goldens. Non-interactive, <60s.
set -euo pipefail
cd "$(dirname "$0")"

ROOT=$(git rev-parse --show-toplevel)
SNAP="$ROOT/evals/snap"
EVALSHOT="$ROOT/evals/evalshot"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

mkdir -p shots

for theme in classic midnight; do
  out="$TMP/out-$theme"
  python3 forge.py build fixture "$out" --theme "$theme"

  # CSS file shipped locally into out-dir
  [ -s "$out/style.css" ] || { echo "FAIL: $theme: style.css missing/empty in out-dir" >&2; exit 1; }
  # theme actually applied (copied byte-identical from themes/)
  cmp -s "themes/$theme.css" "$out/style.css" \
    || { echo "FAIL: $theme: out/style.css != themes/$theme.css" >&2; exit 1; }
  # page links the local CSS, no CDN
  grep -q '<link rel="stylesheet" href="style.css">' "$out/page.html" \
    || { echo "FAIL: $theme: page.html does not link style.css" >&2; exit 1; }
  grep -qE 'https?://' "$out/style.css" \
    && { echo "FAIL: $theme: style.css references remote URL" >&2; exit 1; }
  # highlight visible: tok spans present in fixture page
  grep -q 'tok-kw' "$out/page.html" \
    || { echo "FAIL: $theme: no tok-kw spans in page.html (highlight plugin)" >&2; exit 1; }

  # screenshot eval
  "$SNAP" "$out/page.html" "shots/$theme.png" 480 640
  "$EVALSHOT" "shots/$theme.png" "goldens/$theme.png"
done

echo "OK: themes check passed (classic + midnight)"
