# Usage

## CLI

The whole interface is one command:

```sh
python3 forge.py build <src-dir> <out-dir> [--theme NAME]
```

- `<src-dir>` — directory containing `*.md` pages and an optional `site.json`
- `<out-dir>` — created if missing; receives one `.html` per page, `index.html`, `style.css`, and any plugin artifacts such as `feed.xml`
- `--theme NAME` — overrides the theme from `site.json`; default is `classic`

A missing source directory is a hard error (nonzero exit, message on
stderr). Theme precedence is `--theme` > `site.json` > `classic`.

## site.json reference

`site.json` is optional and lives at the root of `<src-dir>`:

```json
{
  "theme": "midnight",
  "plugins": ["highlight", "rss"],
  "title": "site-forge docs",
  "link": "https://example.invalid/site-forge",
  "description": "site-forge documenting itself"
}
```

- `theme` — `classic` or `midnight`
- `plugins` — list of plugin module names from `plugins/`, run in list order; `[]` disables all plugins
- `title`, `link`, `description` — channel metadata consumed by the *rss* plugin

## Page conventions

- Pages are all `*.md` files in `<src-dir>`, sorted by filename for stable nav and index ordering
- The first `# h1` of a page becomes its `<title>` and nav label; otherwise the filename is used
- `index.md`, if present, renders above the generated page list on `index.html`
