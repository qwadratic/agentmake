# site-forge

**site-forge** is a static site generator written in pure Python 3 stdlib:
markdown in, themed HTML site out. No pip packages, no CDN assets — every
byte of CSS ships as a local file in the output directory.

## What it does

- Parses a markdown subset: headings, paragraphs, **bold**, *italic*, links, inline `code`, fenced code blocks and lists
- Assembles a site: `index.html` page listing plus a `<nav>` injected into every page, current page marked *active*
- Runs a plugin subsystem with three hooks (`on_page`, `on_html`, `on_site`) and two shipped plugins: [syntax highlight](plugin-api.html) and RSS
- Ships two selectable [themes](themes.html): `classic` and `midnight`

## Quick start

```sh
python3 forge.py build docs-src out --theme midnight
```

That single command built the site you are reading right now — site-forge
documents itself. See [usage](usage.html) for the full CLI and config
reference.
