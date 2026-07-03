# site-forge plugin hook contract

A plugin is a Python file in `plugins/` (stdlib only). It is enabled by
listing its module name in `site.json` under `"plugins": [...]`.

## Hooks

All hooks are **optional** — a plugin may define any subset. Missing hook
attributes are skipped silently.

### `on_page(page: dict) -> dict`

Runs before rendering. Receives the parsed page dict; must return a page
dict (mutated or replaced). Use it to change markdown, title, etc.

### `on_html(page: dict, html: str) -> str`

Runs after rendering and nav injection, per page. Receives the page dict
and the final page HTML; must return the (possibly modified) HTML string.

### `on_site(site: dict, out_dir: str) -> None`

Runs once after the whole build. Receives the site dict and the output
directory path. Use it to write extra whole-site artifacts (e.g. feeds).
Return value is ignored.

## Data shapes

Page dict keys:

| key     | meaning                          |
|---------|----------------------------------|
| `path`  | source file path                 |
| `name`  | page name (output stem)          |
| `title` | page title                       |
| `md`    | markdown source                  |
| `html`  | rendered HTML (empty pre-render) |

Site dict keys:

| key      | meaning                       |
|----------|-------------------------------|
| `pages`  | list of page dicts            |
| `config` | parsed `site.json` config dict|

## Execution order

Plugins run in **list order** as declared in `site.json` `"plugins"` array.
For each hook, every plugin's implementation is called in that order;
`on_page`/`on_html` results chain (output of one feeds the next).

## Error semantics

- Unknown plugin name in `site.json`: clear error on stderr, nonzero exit.
- If a hook raises, the build fails loudly: the plugin name is printed to
  stderr and the process exits nonzero. There are no silent skips of
  failing plugins.
