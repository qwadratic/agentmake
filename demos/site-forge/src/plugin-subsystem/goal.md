# Sub-PRD: site-forge plugin subsystem

## Context
Host pipeline exists: `python3 forge.py build <src> <out> [--theme NAME]` parses md -> renders HTML -> injects nav -> writes site. Page dict shape: {path, name, title, md, html}. Site dict: {pages, config}. This subtree builds the plugin layer only. python3 stdlib ONLY. Every component ships executable check.sh: non-interactive, own tmp dirs, trap cleanup, <60s, safe under make -j2.

## Components in scope

### Loader + hook API
- Plugin = python file in plugins/ exposing any of: `on_page(page: dict) -> dict` (mutate parsed page pre-render), `on_html(page: dict, html: str) -> str` (mutate final page HTML, runs after nav injection), `on_site(site: dict, out_dir: str) -> None` (post-build whole-site artifacts).
- Discovers plugins from site.json `"plugins": [...]`, loads via importlib, runs hooks in list order. Missing hook attrs are fine (all optional).
- Unknown plugin name -> clear error on stderr, nonzero exit. Plugin raising in any hook -> build fails loudly, plugin name in stderr, nonzero exit. No silent skips.
- Hook contract documented in plugins/README.md.
- check.sh: tmp fixture with a trivial test plugin proving each hook fires in order; unknown-name run exits nonzero with name in stderr; raising plugin run exits nonzero with name in stderr.

### Shipped plugin: highlight
- on_html: fenced code blocks WITH language tag get <span class="tok-*"> markup. Python: keywords, strings, comments, numbers (classes tok-kw, tok-str, tok-com, tok-num). Unknown languages: generic fallback highlighting strings + numbers. Blocks without lang tag pass through byte-identical.
- regex/tokenize stdlib only. Must not double-escape: operates on already-escaped code content.
- check.sh: fixture with python block, unknown-lang block, untagged block; assert tok-kw/tok-str/tok-com/tok-num present for python, tok-str/tok-num for unknown, untagged block unchanged, output still valid (no nested/broken spans via html.parser parse).

### Shipped plugin: rss
- on_site: write feed.xml (RSS 2.0) at out-dir root. One <item> per page: title, link, description = first paragraph text. Channel title/link/description from site.json keys. Deterministic: fixed or omitted pubDate, never wall clock — two consecutive builds produce identical bytes.
- check.sh: build tmp fixture, parse feed.xml with xml.etree.ElementTree, assert channel meta + item count == page count + descriptions non-empty; build twice, cmp feed.xml identical.

## Acceptance (subsystem)
- Both plugins enabled in one run: HTML contains tok- spans AND feed.xml exists.
- `"plugins": []`: zero tok- spans anywhere, no feed.xml.
- Broken plugin (raises): nonzero exit, plugin name in stderr.
- An integration check.sh at subsystem root runs all three scenarios.
