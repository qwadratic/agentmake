#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
fail() { echo "FAIL: $1" >&2; exit 1; }

linkcheck() {  # parse every href in every .html; assert target exists
python3 - "$1" <<'EOF'
import html.parser, os, sys, urllib.parse

class H(html.parser.HTMLParser):
    def __init__(self):
        super().__init__()
        self.hrefs = []
    def handle_starttag(self, tag, attrs):
        for k, v in attrs:
            if k == "href" and v:
                self.hrefs.append(v)

out = sys.argv[1]
bad = []
for fn in os.listdir(out):
    if not fn.endswith(".html"):
        continue
    p = H()
    with open(os.path.join(out, fn), encoding="utf-8") as f:
        p.feed(f.read())
    for h in p.hrefs:
        if h.startswith(("http:", "https:", "mailto:", "#")):
            continue
        target = urllib.parse.urlparse(h).path
        if not os.path.exists(os.path.join(out, target)):
            bad.append((fn, h))
if bad:
    sys.exit("dead links: %r" % bad)
print("links ok")
EOF
}

# --- 3-page fixture (+ index.md body) --------------------------------
mkdir "$TMP/src"
printf '# Alpha Page\n\nalpha text\n'  > "$TMP/src/alpha.md"
printf '# Beta Page\n\nbeta text\n'    > "$TMP/src/beta.md"
printf '# Gamma Page\n\ngamma text\n'  > "$TMP/src/gamma.md"
printf '# Welcome\n\nintro paragraph\n' > "$TMP/src/index.md"

python3 forge.py build "$TMP/src" "$TMP/out"

IDX="$TMP/out/index.html"
[ -f "$IDX" ] || fail "index.html missing"

# index lists all 3 pages (title + link)
grep -q '<a href="alpha.html">Alpha Page</a>' "$IDX" || fail "index misses alpha"
grep -q '<a href="beta.html">Beta Page</a>'   "$IDX" || fail "index misses beta"
grep -q '<a href="gamma.html">Gamma Page</a>' "$IDX" || fail "index misses gamma"

# index.md body renders ABOVE the page list
python3 - "$IDX" <<'EOF'
import sys
h = open(sys.argv[1], encoding="utf-8").read()
assert "<h1>Welcome</h1>" in h, "index.md body missing"
assert h.index("<h1>Welcome</h1>") < h.index('class="page-list"'), "body not above list"
EOF

# every page (incl. index) has nav with all links + exactly one active
for f in index alpha beta gamma; do
  P="$TMP/out/$f.html"
  grep -q "<nav>" "$P" || fail "$f: no nav"
  for l in index alpha beta gamma; do
    grep -q "href=\"$l.html\"" "$P" || fail "$f: nav misses $l"
  done
  [ "$(grep -c 'class="active"' "$P")" = 1 ] || fail "$f: active count != 1"
  grep -q "class=\"active\">.*</a>" "$P" || true
  grep -q "href=\"$f.html\" class=\"active\"" "$P" || fail "$f: wrong active"
done

linkcheck "$TMP/out"

# --- single-page fixture (no index.md) -------------------------------
mkdir "$TMP/one"
printf '# Solo\n\nonly page\n' > "$TMP/one/solo.md"
python3 forge.py build "$TMP/one" "$TMP/oneout"

[ -f "$TMP/oneout/index.html" ] || fail "single: index.html missing"
grep -q '<a href="solo.html">Solo</a>' "$TMP/oneout/index.html" || fail "single: index misses solo"
grep -q "<nav>" "$TMP/oneout/solo.html" || fail "single: solo no nav"
grep -q "<nav>" "$TMP/oneout/index.html" || fail "single: index no nav"
[ "$(grep -c 'class="active"' "$TMP/oneout/solo.html")" = 1 ] || fail "single: active count"

linkcheck "$TMP/oneout"

echo OK
