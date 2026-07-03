"""highlight plugin: on_html wraps tokens in fenced code blocks with tok-* spans.

Operates on already-HTML-escaped code content (mdcore emits
<pre><code class="lang-X">ESCAPED</code></pre>); inserts spans only,
never re-escapes. Blocks without a lang class pass through untouched.
stdlib only (re, keyword).
"""
import keyword
import re

# token patterns over HTML-escaped text (quotes appear as entities)
_STR = r"&quot;.*?&quot;|&#x27;.*?&#x27;|&#39;.*?&#39;"
_COM = r"#[^\n]*"
_NUM = r"\b\d+(?:\.\d+)?\b"
_KW = r"\b(?:%s)\b" % "|".join(keyword.kwlist)

_PY = re.compile("(?P<str>%s)|(?P<com>%s)|(?P<kw>%s)|(?P<num>%s)"
                 % (_STR, _COM, _KW, _NUM))
_GEN = re.compile("(?P<str>%s)|(?P<num>%s)" % (_STR, _NUM))

_CLS = {"kw": "tok-kw", "str": "tok-str", "com": "tok-com", "num": "tok-num"}

_BLOCK = re.compile(
    r'(<pre><code class="(?:lang|language)-([^"]+)">)(.*?)(</code></pre>)',
    re.S)


def _mark(rx, code):
    return rx.sub(
        lambda m: '<span class="%s">%s</span>' % (_CLS[m.lastgroup], m.group()),
        code)


def on_html(page, html):
    def sub(m):
        rx = _PY if m.group(2).lower() in ("python", "py") else _GEN
        return m.group(1) + _mark(rx, m.group(3)) + m.group(4)
    return _BLOCK.sub(sub, html)
