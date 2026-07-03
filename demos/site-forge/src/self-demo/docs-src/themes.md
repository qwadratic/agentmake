# Themes

site-forge ships two CSS themes. Same HTML structure, CSS-only difference —
switching themes never changes markup. The selected theme is copied into the
output as a local `style.css`; there are no CDN links.

## classic

The default. Light and bookish:

- white background, dark text
- serif headings over a sans-serif body
- understated nav bar with an underlined *active* link

```sh
python3 forge.py build docs-src out --theme classic
```

## midnight

Dark mode:

- `#0b0e14` background, light text
- accent color on links and the nav bar
- syntax-highlight `tok-*` colors tuned for dark background

```sh
python3 forge.py build docs-src out --theme midnight
```

## What both themes style

Nav bar, `h1`–`h3` headings, body text, links, lists, and the highlight
plugin token classes, e.g.:

```css
.tok-kw  { font-weight: bold; }
.tok-str { /* string literals */ }
.tok-com { font-style: italic; }
.tok-num { /* numeric literals */ }
```

Selection precedence: `--theme` flag, then `"theme"` in
[site.json](usage.html), then `classic`.
