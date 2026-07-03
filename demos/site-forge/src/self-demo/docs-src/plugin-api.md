# Plugin API

A plugin is a plain Python file in `plugins/` exposing any subset of three
hooks. All hooks are optional; missing ones are skipped. Plugins are enabled
via `site.json` and run in list order.

## Hook contract

```python
def on_page(page: dict) -> dict:
    """Mutate the parsed page before rendering.

    page = {"path": str, "name": str, "title": str,
            "md": str, "html": str}
    Return the (possibly replaced) page dict.
    """

def on_html(page: dict, html: str) -> str:
    """Mutate the final rendered document.

    Runs AFTER nav injection, so the plugin sees the complete
    page HTML. Return the new HTML string.
    """

def on_site(site: dict, out_dir: str) -> None:
    """Post-build hook for whole-site artifacts.

    site = {"pages": [page, ...], "config": dict}
    Write extra files (e.g. feed.xml) into out_dir.
    """
```

## Error handling

- Unknown plugin name in `site.json` — clear error on stderr, nonzero exit
- A hook raising any exception — build fails loudly with the plugin name in the message; there are no silent skips

## Shipped plugins

### highlight

`on_html`: fenced code blocks with a language tag get token-level spans —
`tok-kw`, `tok-str`, `tok-com`, `tok-num` for Python, a generic
strings-and-numbers fallback for unknown languages. Untagged blocks pass
through untouched. Example input:

```python
# comment -> tok-com
def total(items):
    return sum(items) + 42  # 42 -> tok-num, "def"/"return" -> tok-kw
```

### rss

`on_site`: writes a deterministic RSS 2.0 `feed.xml` at the output root —
one `<item>` per page with title, link, and the first paragraph as
description. Channel metadata comes from `site.json`. No wall-clock dates,
so two builds produce identical bytes.
