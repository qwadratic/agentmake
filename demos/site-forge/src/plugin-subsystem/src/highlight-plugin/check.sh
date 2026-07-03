#!/bin/sh
# self-test for plugins/highlight.py — non-interactive, <60s
set -eu
HERE=$(cd "$(dirname "$0")" && pwd)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$TMP/plugins"
cp "$HERE/plugins/highlight.py" "$TMP/plugins/"

cat > "$TMP/drive.py" <<'EOF'
import html as H, re, sys
from html.parser import HTMLParser
sys.path.insert(0, "plugins")
import highlight

py_code = H.escape('# comment\nx = "hi" + \'yo\'\nif x:\n    n = 42')
unk_code = H.escape('val s = "hi"; n = 7')
raw_code = H.escape('def f(): return 3  # untouched')

page_html = (
    '<h1>T</h1>'
    '<pre><code class="lang-python">%s</code></pre>'
    '<pre><code class="lang-zorblang">%s</code></pre>'
    '<pre><code>%s</code></pre>' % (py_code, unk_code, raw_code))

out = highlight.on_html({"name": "p"}, page_html)

# split output back into the three blocks
blocks = re.findall(r'<pre><code[^>]*>(.*?)</code></pre>', out, re.S)
assert len(blocks) == 3, blocks
py, unk, raw = blocks

# python block: all four token classes
for cls in ("tok-kw", "tok-str", "tok-com", "tok-num"):
    assert 'class="%s"' % cls in py, "python block missing " + cls
assert '<span class="tok-kw">if</span>' in py
assert '<span class="tok-com"># comment</span>' in py

# unknown-lang block: generic fallback, str + num only
assert 'tok-str' in unk and 'tok-num' in unk
assert 'tok-kw' not in unk and 'tok-com' not in unk

# untagged block: byte-identical
assert raw == raw_code, "untagged block changed: %r" % raw

# no double-escape: entities intact, no &amp;quot;
assert '&amp;quot;' not in out and '&amp;#x27;' not in out

# output parses cleanly: balanced spans, no nesting inside code
class Check(HTMLParser):
    def __init__(self):
        super().__init__()
        self.stack = []
    def handle_starttag(self, tag, attrs):
        if tag == "span":
            assert self.stack[-1:] != ["span"], "nested span"
        self.stack.append(tag)
    def handle_endtag(self, tag):
        assert self.stack and self.stack[-1] == tag, "mismatched </%s>" % tag
        self.stack.pop()

c = Check()
c.feed(out)
c.close()
assert not c.stack, "unclosed tags: %s" % c.stack
print("OK")
EOF

cd "$TMP"
python3 drive.py
echo "highlight-plugin check: PASS"
