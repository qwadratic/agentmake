#!/usr/bin/env python3
"""site-forge CLI entrypoint.

Contract: python3 forge.py build <src-dir> <out-dir> [--theme NAME]

Internal page dict shape (siblings integrate against this):

    page = {
        "path": str,   # absolute path to the source .md file
        "name": str,   # filename stem, e.g. "usage" for usage.md
        "title": str,  # first h1 if present, else name (set by md-core)
        "md": str,     # raw markdown source
        "html": str,   # rendered HTML body (set by md-core / plugins)
    }

Site dict passed downstream: {"pages": [page...], "config": config}.

Theme precedence: --theme > site.json "theme" > "classic".

site-assembly stage: pages sorted by filename; index.html lists every page
(index.md body, if present, renders above the list); <nav> injected into
every rendered page with current page marked class="active". Nav injection
happens between render and the plugin on_html hook, so plugins see the
final page HTML.
"""

import argparse
import html
import json
import os
import sys

import mdcore


def load_config(src):
    """Load optional <src>/site.json; returns {} if absent."""
    p = os.path.join(src, "site.json")
    if os.path.isfile(p):
        with open(p, encoding="utf-8") as f:
            return json.load(f)
    return {}


def nav_html(entries, current):
    """entries = [(name, title), ...]; current = active page name."""
    links = []
    for name, title in entries:
        cls = ' class="active"' if name == current else ""
        links.append('<a href="%s.html"%s>%s</a>'
                     % (html.escape(name, quote=True), cls, html.escape(title)))
    return "<nav>\n%s\n</nav>" % "\n".join(links)


def build(src, out, config):
    """Build the site from src into out. Returns site dict {pages, config}.

    Stages: parse+render (md-core) -> nav/index (site-assembly).
    plugin-subsystem extends this: on_html runs on `doc` below (post-nav),
    on_site runs on the returned site dict.
    """
    os.makedirs(out, exist_ok=True)
    pages = []
    for fn in sorted(os.listdir(src)):
        if not fn.endswith(".md"):
            continue
        path = os.path.join(src, fn)
        with open(path, encoding="utf-8") as f:
            md = f.read()
        name = fn[:-3]
        pages.append({"path": path, "name": name, "title": name,
                      "md": md, "html": ""})

    for page in pages:
        title, body = mdcore.md_to_html(page["md"])
        page["title"] = title or page["name"]
        page["html"] = body

    # --- site assembly: nav + index -------------------------------------
    index_page = next((p for p in pages if p["name"] == "index"), None)
    content = [p for p in pages if p["name"] != "index"]

    entries = [("index", index_page["title"] if index_page else "Home")]
    entries += [(p["name"], p["title"]) for p in content]

    listing = "<ul class=\"page-list\">\n%s\n</ul>" % "\n".join(
        '<li><a href="%s.html">%s</a></li>'
        % (html.escape(p["name"], quote=True), html.escape(p["title"]))
        for p in content)
    index_title = index_page["title"] if index_page else "Home"
    index_body = ((index_page["html"] + "\n") if index_page else "") + listing

    for page in content:
        doc = mdcore.render_document(
            page["title"],
            nav_html(entries, page["name"]) + "\n" + page["html"],
            "style.css")
        # plugin on_html hook point: runs here on `doc` (nav already in)
        with open(os.path.join(out, page["name"] + ".html"),
                  "w", encoding="utf-8") as f:
            f.write(doc)

    index_doc = mdcore.render_document(
        index_title, nav_html(entries, "index") + "\n" + index_body,
        "style.css")
    with open(os.path.join(out, "index.html"), "w", encoding="utf-8") as f:
        f.write(index_doc)

    # ponytail: placeholder so the style.css href never dangles;
    # themes component overwrites this with real CSS.
    css = os.path.join(out, "style.css")
    if not os.path.exists(css):
        with open(css, "w", encoding="utf-8") as f:
            f.write("/* site-forge: placeholder, themes ship real CSS */\n")

    return {"pages": pages, "config": config}


def main(argv=None):
    ap = argparse.ArgumentParser(prog="forge.py")
    sub = ap.add_subparsers(dest="cmd", required=True)
    b = sub.add_parser("build")
    b.add_argument("src")
    b.add_argument("out")
    b.add_argument("--theme")
    args = ap.parse_args(argv)

    if not os.path.isdir(args.src):
        print(f"error: src-dir not found: {args.src}", file=sys.stderr)
        return 1

    config = load_config(args.src)
    config["theme"] = args.theme or config.get("theme") or "classic"
    build(args.src, args.out, config)
    return 0


if __name__ == "__main__":
    sys.exit(main())
