"""Markdown subset -> HTML, stdlib only.

Supports: ATX h1-h3, paragraphs, **bold**, *italic*, [text](url),
inline `code`, fenced ``` blocks (optional lang -> class="lang-X"),
unordered - lists. ALL source text is html.escape()d — md is untrusted.
"""

import html
import re

_CODE = re.compile(r"`([^`]+)`")
_LINK = re.compile(r"\[([^\]]+)\]\(([^)\s]+)\)")
_BOLD = re.compile(r"\*\*(.+?)\*\*")
_ITAL = re.compile(r"\*(.+?)\*")
_HEAD = re.compile(r"(#{1,3}) (.*)")


def _inline(text):
    """Inline markup on already-escaped text. Code spans first, untouched inside."""
    out = []
    parts = _CODE.split(text)
    for i, part in enumerate(parts):
        if i % 2:
            out.append("<code>%s</code>" % part)
        else:
            part = _LINK.sub(r'<a href="\2">\1</a>', part)
            part = _BOLD.sub(r"<strong>\1</strong>", part)
            part = _ITAL.sub(r"<em>\1</em>", part)
            out.append(part)
    return "".join(out)


def md_to_html(md):
    """Return (title_or_None, body_html). Title = first h1 text."""
    title = None
    out = []
    lines = md.split("\n")
    i, n = 0, len(lines)
    while i < n:
        line = lines[i]
        if line.startswith("```"):
            lang = line[3:].strip()
            i += 1
            buf = []
            while i < n and not lines[i].startswith("```"):
                buf.append(lines[i])
                i += 1
            i += 1  # skip closing fence; harmless past EOF (unclosed fence)
            cls = ' class="lang-%s"' % html.escape(lang, quote=True) if lang else ""
            out.append("<pre><code%s>%s</code></pre>"
                       % (cls, html.escape("\n".join(buf))))
            continue
        if not line.strip():
            i += 1
            continue
        m = _HEAD.match(line)
        if m:
            lvl, text = len(m.group(1)), m.group(2).strip()
            if lvl == 1 and title is None:
                title = text
            out.append("<h%d>%s</h%d>" % (lvl, _inline(html.escape(text)), lvl))
            i += 1
            continue
        if line.startswith("- "):
            items = []
            while i < n and lines[i].startswith("- "):
                items.append("<li>%s</li>" % _inline(html.escape(lines[i][2:])))
                i += 1
            out.append("<ul>\n%s\n</ul>" % "\n".join(items))
            continue
        buf = []
        while i < n and lines[i].strip() and not lines[i].startswith(("#", "- ", "```")):
            buf.append(lines[i])
            i += 1
        if not buf:  # e.g. lone "####" line — consume it as a paragraph
            buf.append(lines[i])
            i += 1
        out.append("<p>%s</p>" % _inline(html.escape("\n".join(buf))))
    return title, "\n".join(out)


def render_document(title, body, css="style.css"):
    """Full HTML document. body is trusted HTML; title/css get escaped."""
    return (
        "<!DOCTYPE html>\n"
        '<html lang="en">\n<head>\n<meta charset="utf-8">\n'
        "<title>%s</title>\n"
        '<link rel="stylesheet" href="%s">\n'
        "</head>\n<body>\n%s\n</body>\n</html>\n"
        % (html.escape(title), html.escape(css, quote=True), body)
    )
