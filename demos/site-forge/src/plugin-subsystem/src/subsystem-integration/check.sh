#!/bin/sh
# subsystem integration check: forge.py wired to plugin_loader, end-to-end.
# Non-interactive, own tmp dir, trap cleanup, <60s, safe under make -j2.
set -eu
HERE=$(cd "$(dirname "$0")" && pwd)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# --- assemble workspace from sibling components ------------------------
MDCORE=""
for c in "$HERE/../../../site-assembly/mdcore.py" "$HERE/../../../md-core/mdcore.py"; do
    [ -f "$c" ] && MDCORE="$c" && break
done
[ -n "$MDCORE" ] || { echo "FAIL: host mdcore.py not found"; exit 1; }

mkdir -p "$TMP/plugins"
cp "$HERE/forge.py" "$MDCORE" "$HERE/../plugin-loader/plugin_loader.py" "$TMP/"
cp "$HERE/../highlight-plugin/plugins/highlight.py" \
   "$HERE/../rss-plugin/plugins/rss.py" "$TMP/plugins/"

# --- fixture site -------------------------------------------------------
mkdir -p "$TMP/site"
cat > "$TMP/site/index.md" <<'EOF'
# Home

Welcome to the fixture site.
EOF
cat > "$TMP/site/post.md" <<'EOF'
# Post

A paragraph before code.

```python
# comment
def f():
    return "hi" + str(42)
```
EOF

cd "$TMP"

# ==== scenario 1: both plugins enabled ==================================
cat > site/site.json <<'EOF'
{"plugins": ["highlight", "rss"],
 "title": "Fixture", "link": "https://example.test", "description": "d"}
EOF
python3 forge.py build site out1
grep -q 'class="tok-' out1/post.html || { echo "FAIL: no tok- spans in out1/post.html"; exit 1; }
[ -f out1/feed.xml ] || { echo "FAIL: feed.xml missing"; exit 1; }
python3 -c "import xml.etree.ElementTree as ET; ET.parse('out1/feed.xml')" \
    || { echo "FAIL: feed.xml does not parse"; exit 1; }

# ==== scenario 2: plugins: [] ===========================================
cat > site/site.json <<'EOF'
{"plugins": []}
EOF
python3 forge.py build site out2
if grep -rq 'class="tok-' out2; then
    echo "FAIL: tok- spans present with plugins disabled"; exit 1
fi
[ ! -e out2/feed.xml ] || { echo "FAIL: feed.xml written with plugins disabled"; exit 1; }

# ==== scenario 3: raising plugin ========================================
cat > plugins/boomer.py <<'EOF'
def on_page(page):
    raise RuntimeError("boom")
EOF
cat > site/site.json <<'EOF'
{"plugins": ["boomer"]}
EOF
if python3 forge.py build site out3 2> err3; then
    echo "FAIL: build with raising plugin exited zero"; exit 1
fi
grep -q boomer err3 || { echo "FAIL: plugin name missing in stderr"; cat err3; exit 1; }

echo "OK"
