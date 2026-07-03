#!/usr/bin/env bash
# self-demo check: build docs-src (site-forge documenting itself) with both
# plugins + midnight theme; assert pages, nav, tok- spans, feed.xml, no dead
# links. Non-interactive, own tmp dir, trap cleanup, <60s.
set -euo pipefail
cd "$(dirname "$0")"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
OUT="$TMP/out"

python3 forge.py build docs-src "$OUT"

# index.html + >=4 page htmls (index counts as one of the page htmls)
[ -f "$OUT/index.html" ] || { echo "FAIL: index.html missing" >&2; exit 1; }
n=$(ls "$OUT"/*.html | wc -l)
[ "$n" -ge 4 ] || { echo "FAIL: expected >=4 html pages, got $n" >&2; exit 1; }
for p in index usage plugin-api themes; do
  [ -f "$OUT/$p.html" ] || { echo "FAIL: $p.html missing" >&2; exit 1; }
done

# nav on every page, tok- spans present somewhere
for f in "$OUT"/*.html; do
  grep -q '<nav>' "$f" || { echo "FAIL: no nav in $f" >&2; exit 1; }
done
grep -q 'class="tok-' "$OUT/plugin-api.html" \
  || { echo "FAIL: no tok- spans in plugin-api.html" >&2; exit 1; }

# feed.xml parses via xml.etree with >=4 items; zero dead hrefs in out-dir
python3 - "$OUT" <<'EOF'
import os, sys, xml.etree.ElementTree as ET
from html.parser import HTMLParser

out = sys.argv[1]

tree = ET.parse(os.path.join(out, "feed.xml"))
items = tree.getroot().findall("./channel/item")
assert len(items) >= 4, "feed.xml has %d items, want >=4" % len(items)
for it in items:
    assert (it.findtext("title") or "").strip(), "feed item missing title"
    assert (it.findtext("description") or "").strip(), "feed item missing description"

class Hrefs(HTMLParser):
    def __init__(self):
        super().__init__()
        self.refs = []
    def handle_starttag(self, tag, attrs):
        for k, v in attrs:
            if k in ("href", "src") and v:
                self.refs.append(v)

dead = []
for fn in os.listdir(out):
    if not fn.endswith(".html"):
        continue
    p = Hrefs()
    with open(os.path.join(out, fn), encoding="utf-8") as f:
        p.feed(f.read())
    for ref in p.refs:
        if "://" in ref or ref.startswith("#") or ref.startswith("mailto:"):
            continue
        target = ref.split("#")[0]
        if target and not os.path.isfile(os.path.join(out, target)):
            dead.append("%s -> %s" % (fn, ref))
assert not dead, "dead hrefs: %s" % dead
print("feed.xml ok (%d items), zero dead hrefs" % len(items))
EOF

echo "PASS: self-demo"
