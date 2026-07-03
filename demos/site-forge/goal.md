# PRD: "site-forge" — static site generator with a plugin subsystem

## Summary
Static site generator: markdown in → themed HTML site out. Core pipeline
(parse → render → nav/index), a PLUGIN SUBSYSTEM (its own architecture:
loader + hook API + two shipped plugins), two visual themes with screenshot
goldens, and a self-demo: site-forge builds its own docs site as the fixture.

## Hard constraints
- python3 stdlib ONLY. No pip, no network installs, no CDN assets — all CSS
  inline or shipped as local files in the output.
- Every component ships an executable `check.sh`: non-interactive, allocates
  its own tmp dirs, cleans up on exit (trap), finishes < 60s. Checks run
  under `make -j2` — never assume exclusive ownership of shared paths.
- CLI contract (integration seam every component honors):
  `python3 forge.py build <src-dir> <out-dir> [--theme NAME]`
  reads `<src-dir>/*.md` + optional `<src-dir>/site.json` config,
  writes a complete static site to `<out-dir>`.
- Screenshot tooling lives at the repo root:
  `$(git rev-parse --show-toplevel)/evals/snap <file-or-url> <out.png> [w h]`
  and `$(git rev-parse --show-toplevel)/evals/evalshot <shot.png> <golden.png> [thr]`.
  Keep shots in `shots/`, goldens in `goldens/` next to the component that
  renders them. Deterministic renders only: no wall-clock dates in the HTML
  body, no animations.

## Functional requirements

### F1. Markdown core (parser + HTML renderer)
- Markdown subset, stdlib-only parser: ATX headings (h1–h3), paragraphs,
  `**bold**`, `*italic*`, `[text](url)` links, inline `` `code` ``,
  fenced code blocks (``` with optional language tag), unordered `-` lists.
- Renderer: each `page.md` → `page.html`, full document with `<head>`
  (title = first h1, else filename) and theme CSS link.
- Edge cases: empty file → valid empty page; unclosed fence → treat rest of
  file as code, never crash; raw HTML in markdown is escaped (XSS: input md
  is untrusted).

### F2. Site assembly — nav + index
- Scans all pages, generates `index.html` listing every page (title + link)
  and injects a `<nav>` (link to every page, current page marked
  `class="active"`) into each rendered page.
- Stable ordering: nav and index sorted by filename; `index.md` (if present)
  supplies the index page body above the page list.
- Edge case: single-page site still gets nav + index; no dead links ever
  (every href resolves within `<out-dir>`).

### F3. Plugin SUBSYSTEM
This is a self-contained subsystem with its own internal architecture, NOT a
single build step. It contains at minimum: the loader/hook API, and two
independently specified, independently testable shipped plugins. Treat its
internals as their own project with the sub-requirements below as its scope.

#### F3a. Plugin API + loader
- A plugin = python file in `plugins/` exposing any of the hooks:
  `on_page(page: dict) -> dict` (mutate parsed page before render),
  `on_html(page: dict, html: str) -> str` (mutate rendered HTML),
  `on_site(site: dict, out_dir: str) -> None` (post-build, whole-site
  artifacts).
- Loader: discovers plugins listed in `site.json` `"plugins": [...]`,
  loads via `importlib`, runs hooks in list order. Unknown plugin name →
  clear error, nonzero exit. Plugin raising an exception → build fails
  loudly with plugin name in the message (no silent skip).
- Hook contract documented in a docstring or `plugins/README.md`.

#### F3b. Shipped plugin: syntax-highlight
- `on_html` hook: fenced code blocks with a language tag get token-level
  `<span class="tok-*">` markup for at least: python (keywords, strings,
  comments, numbers), plus a generic fallback (strings + numbers) for
  unknown languages. stdlib only — regex/tokenize based, no pygments.
- Blocks without a language tag pass through unchanged.

#### F3c. Shipped plugin: rss
- `on_site` hook: emits valid `feed.xml` (RSS 2.0) at the output root —
  one `<item>` per page (title, link, description from first paragraph).
- Feed parses with `xml.etree.ElementTree`; channel has title/link/
  description from `site.json`; deterministic output (fixed or omitted
  pubDate — never wall clock).

#### F3 acceptance (subsystem-level)
- Build with both plugins enabled: highlighted code in HTML AND feed.xml
  present, in one run.
- Build with `"plugins": []`: output contains no `tok-` spans and no
  feed.xml — plugins are genuinely opt-in.
- A deliberately broken plugin (raises in hook) fails the build with its
  name in stderr.

### F4. Themes — two, screenshot-golden verified
- Two selectable CSS themes: `classic` (light: white bg, dark text, serif
  headings) and `midnight` (dark: #0b0e14 bg, light text, accent color on
  links/nav). Selected via `--theme` or `site.json` `"theme"`, default
  `classic`. Same HTML structure, CSS-only difference.
- Both themes style: nav bar, headings, body text, links, lists, and
  syntax-highlight `tok-*` classes (highlighting is visible in both).
- Screenshot eval per theme: build a fixture page, `snap` it at 480x640,
  `evalshot` against a committed golden. Both theme checks pass.

### F5. Self-demo — site-forge documents itself
- `docs-src/` with ≥4 real markdown pages about site-forge itself: index
  (what it is), usage (CLI + site.json reference), plugin-api (hook
  contract), themes (both themes described).
- `site.json` enabling BOTH shipped plugins + a theme.
- Building it produces: index.html + one html per page, nav on every page,
  highlighted code samples, feed.xml. This built site is the demo fixture.

## Acceptance criteria
- A1 pipeline: `forge.py build` on a 3-page fixture → 3 html pages +
  index.html; headings/bold/links/lists/code render; raw `<script>` in md
  arrives escaped.
- A2 nav: every page contains nav with links to all pages; current page
  marked active; zero dead hrefs in the whole output dir.
- A3 plugins: F3 subsystem acceptance holds (both-on run, opt-out run,
  broken-plugin run).
- A4 themes: both themes build; both screenshot goldens pass evalshot.
- A5 self-demo: docs site builds clean with plugins + theme on; feed.xml
  valid; ≥4 pages.
- A6 checks: every component ships executable `check.sh` per Hard
  constraints.

## Out of scope
Incremental builds, watch mode, deployment, markdown tables/footnotes/
images, plugin sandboxing, config schema validation beyond required keys.
