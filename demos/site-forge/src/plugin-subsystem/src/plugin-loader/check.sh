#!/bin/sh
# self-test for plugin_loader.py — non-interactive, <60s
set -eu
HERE=$(cd "$(dirname "$0")" && pwd)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$TMP/plugins"
cp "$HERE/plugin_loader.py" "$TMP/"

# trivial plugin recording hook call order
cat > "$TMP/plugins/recorder.py" <<'EOF'
import os
LOG = os.environ["REC_LOG"]
def _rec(x):
    with open(LOG, "a") as f:
        f.write(x + "\n")
def on_page(page):
    _rec("on_page")
    return page
def on_html(page, html):
    _rec("on_html")
    return html
def on_site(site, out_dir):
    _rec("on_site")
EOF

# raising plugin
cat > "$TMP/plugins/boomer.py" <<'EOF'
def on_page(page):
    raise RuntimeError("boom")
EOF

# driver simulating forge.py usage
cat > "$TMP/drive.py" <<'EOF'
import sys, plugin_loader as pl
config = {"plugins": sys.argv[1:]}
plugins = pl.load_plugins(config)
page = {"path": "a.md", "name": "a", "title": "A", "md": "", "html": ""}
page = pl.run_on_page(plugins, page)
html = pl.run_on_html(plugins, page, "<p>hi</p>")
pl.run_on_site(plugins, {"pages": [page], "config": config}, "/tmp")
EOF

cd "$TMP"

# 1) all three hooks fire in order
REC_LOG="$TMP/log" python3 drive.py recorder
printf 'on_page\non_html\non_site\n' > "$TMP/expect"
cmp -s "$TMP/log" "$TMP/expect" || { echo "FAIL: hook order"; cat "$TMP/log"; exit 1; }

# 2) unknown plugin: nonzero, name in stderr
if python3 drive.py nosuchplugin 2> "$TMP/err2"; then
    echo "FAIL: unknown plugin exited zero"; exit 1
fi
grep -q nosuchplugin "$TMP/err2" || { echo "FAIL: name missing in stderr"; cat "$TMP/err2"; exit 1; }

# 3) raising plugin: nonzero, name in stderr
if python3 drive.py boomer 2> "$TMP/err3"; then
    echo "FAIL: raising plugin exited zero"; exit 1
fi
grep -q boomer "$TMP/err3" || { echo "FAIL: name missing in stderr"; cat "$TMP/err3"; exit 1; }

# 4) empty plugins list: no-op
python3 drive.py

echo "OK"
