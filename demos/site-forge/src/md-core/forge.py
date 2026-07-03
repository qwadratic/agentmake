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

Theme precedence: --theme > site.json "theme" > "classic".
"""

import argparse
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


def build(src, out, config):
    """Build the site from src into out.

    ponytail: md-core stage — parses + renders each page to <name>.html.
    site-assembly (nav/index) and plugin-subsystem extend this function.
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
        doc = mdcore.render_document(page["title"], page["html"], "style.css")
        with open(os.path.join(out, page["name"] + ".html"),
                  "w", encoding="utf-8") as f:
            f.write(doc)

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
