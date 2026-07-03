#!/bin/sh
# rss-plugin self-test: determinism + feed structure. stdlib only, <60s.
set -eu
DIR=$(cd "$(dirname "$0")" && pwd)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT INT TERM

mkdir -p "$TMP/out1" "$TMP/out2"

python3 - "$DIR" "$TMP" <<'EOF'
import sys, os
plugin_dir, tmp = sys.argv[1], sys.argv[2]
sys.path.insert(0, os.path.join(plugin_dir, "plugins"))
import rss

site = {
    "config": {
        "title": "Test Site",
        "link": "https://example.com",
        "description": "A test site & more",
    },
    "pages": [
        {"path": "a.md", "name": "a", "title": "Page A", "md": "",
         "html": "<h1>Page A</h1><p>First para of <em>A</em>.</p><p>Second.</p>"},
        {"path": "b.md", "name": "b", "title": "Page B <special>", "md": "",
         "html": "<p>B's intro &amp; stuff.</p>"},
        {"path": "c.md", "name": "c", "title": "Page C", "md": "",
         "html": "<h1>no para</h1>"},
    ],
}

rss.on_site(site, os.path.join(tmp, "out1"))
rss.on_site(site, os.path.join(tmp, "out2"))

import xml.etree.ElementTree as ET
tree = ET.parse(os.path.join(tmp, "out1", "feed.xml"))
root = tree.getroot()
assert root.tag == "rss" and root.get("version") == "2.0", "not rss 2.0"
ch = root.find("channel")
assert ch is not None, "no channel"
assert ch.findtext("title") == "Test Site"
assert ch.findtext("link") == "https://example.com"
assert ch.findtext("description") == "A test site & more"
items = ch.findall("item")
assert len(items) == len(site["pages"]), "item count %d != %d" % (len(items), len(site["pages"]))
for it in items:
    assert (it.findtext("description") or "").strip(), "empty description"
    assert (it.findtext("link") or "").startswith("https://example.com/")
assert items[0].findtext("description") == "First para of A."
assert "pubdate" not in open(os.path.join(tmp, "out1", "feed.xml")).read().lower(), "pubDate present"
print("structure ok")
EOF

cmp "$TMP/out1/feed.xml" "$TMP/out2/feed.xml"
echo "deterministic ok"
echo "rss-plugin check PASSED"
