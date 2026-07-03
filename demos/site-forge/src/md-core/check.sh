#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

mkdir "$TMP/src"

cat > "$TMP/src/full.md" <<'EOF'
# Title One

## Sub *two*

### Deep

Paragraph with **bold**, *italic*, [a link](page.html) and `in code`.

<script>alert(1)</script>

- item one
- item **two**

```python
def f(x):
    return x  # comment
```

```
no lang here
```
EOF

: > "$TMP/src/empty.md"

cat > "$TMP/src/unclosed.md" <<'EOF'
# Unclosed

```js
never closed
still code
EOF

python3 forge.py build "$TMP/src" "$TMP/out"

F="$TMP/out/full.html"
fail() { echo "FAIL: $1" >&2; exit 1; }

grep -q "<h1>Title One</h1>" "$F" || fail "h1"
grep -q "<h2>Sub <em>two</em></h2>" "$F" || fail "h2 + italic"
grep -q "<h3>Deep</h3>" "$F" || fail "h3"
grep -q "<strong>bold</strong>" "$F" || fail "bold"
grep -q "<em>italic</em>" "$F" || fail "italic"
grep -q '<a href="page.html">a link</a>' "$F" || fail "link"
grep -q "<code>in code</code>" "$F" || fail "inline code"
grep -q '<pre><code class="lang-python">' "$F" || fail "fenced lang"
grep -q "<pre><code>no lang here" "$F" || fail "fenced no-lang"
grep -q "<ul>" "$F" && grep -q "<li>item one</li>" "$F" || fail "list"
grep -q "<li>item <strong>two</strong></li>" "$F" || fail "list inline"
grep -q "<title>Title One</title>" "$F" || fail "title from h1"
grep -q '<link rel="stylesheet" href="style.css">' "$F" || fail "css link"

# XSS: raw script must arrive escaped, never live
grep -q "&lt;script&gt;alert(1)&lt;/script&gt;" "$F" || fail "script not escaped"
grep -q "<script>" "$F" && fail "raw script leaked" || true

# empty file -> valid empty page, title = filename
E="$TMP/out/empty.html"
[ -f "$E" ] || fail "empty page missing"
grep -q "<title>empty</title>" "$E" || fail "empty title fallback"
grep -q "</html>" "$E" || fail "empty page not a full doc"

# unclosed fence -> rest of file is code, no crash
U="$TMP/out/unclosed.html"
grep -q '<pre><code class="lang-js">' "$U" || fail "unclosed fence code"
grep -q "still code" "$U" || fail "unclosed fence content"

echo OK
