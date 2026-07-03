#!/usr/bin/env python3
"""site-forge CLI entrypoint, wired to plugin_loader.

Contract: python3 forge.py build <src-dir> <out-dir> [--theme NAME]

Same pipeline as the host forge.py (md-core parse/render -> nav/index ->
write site) plus the plugin hooks:

  on_page(page)          after parsing, before render
  on_html(page, doc)     on the final document, after nav injection
  on_site(site, out_dir) after all files written

Plugins come from site.json "plugins": [...]; errors abort the build with
the plugin name on stderr (see plugin_loader).
"""

import argparse
import html
import json
import os
import sys

import mdcore
import plugin_loader
import shutil

THEMES_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "themes")


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


def build(src, out, config, plugins):
    """Build site from src into out, running plugin hooks. Returns site dict."""
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

    # hook: on_page (pre-render)
    pages = [plugin_loader.run_on_page(plugins, p) for p in pages]

    for page in pages:
        title, body = mdcore.md_to_html(page["md"])
        page["title"] = title or page["name"]
        page["html"] = body

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
        # hook: on_html (post-nav-injection)
        doc = plugin_loader.run_on_html(plugins, page, doc)
        with open(os.path.join(out, page["name"] + ".html"),
                  "w", encoding="utf-8") as f:
            f.write(doc)

    index_doc = mdcore.render_document(
        index_title, nav_html(entries, "index") + "\n" + index_body,
        "style.css")
    index_meta = index_page or {"path": "", "name": "index",
                                "title": index_title, "md": "", "html": index_body}
    index_doc = plugin_loader.run_on_html(plugins, index_meta, index_doc)
    with open(os.path.join(out, "index.html"), "w", encoding="utf-8") as f:
        f.write(index_doc)

    # themes: copy selected theme CSS into out-dir as style.css (local file, no CDN)
    theme = config.get("theme", "classic")
    theme_css = os.path.join(THEMES_DIR, theme + ".css")
    if not os.path.isfile(theme_css):
        print("error: unknown theme '%s' (no %s)" % (theme, theme_css),
              file=sys.stderr)
        sys.exit(1)
    shutil.copyfile(theme_css, os.path.join(out, "style.css"))

    site = {"pages": pages, "config": config}
    # hook: on_site (post-build)
    plugin_loader.run_on_site(plugins, site, out)
    return site


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
    plugins = plugin_loader.load_plugins(config)
    build(args.src, args.out, config, plugins)
    return 0


if __name__ == "__main__":
    sys.exit(main())
