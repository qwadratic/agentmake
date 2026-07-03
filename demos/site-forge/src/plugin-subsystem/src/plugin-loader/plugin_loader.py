"""Plugin loader for site-forge. stdlib only.

Reads config["plugins"] (list of module names), imports each from plugins/,
dispatches optional hooks in list order:
  on_page(page: dict) -> dict          pre-render
  on_html(page: dict, html: str) -> str  post-nav-injection
  on_site(site: dict, out_dir: str) -> None  post-build
Missing hooks skipped silently. Unknown plugin or raising hook: error to
stderr with plugin name, nonzero exit.
"""
import importlib
import os
import sys


def _die(msg):
    print("plugin error: %s" % msg, file=sys.stderr)
    sys.exit(1)


def load_plugins(config, plugins_dir=None):
    """Import modules named in config["plugins"] from plugins_dir.

    Returns list of (name, module) in list order.
    """
    names = config.get("plugins", [])
    if not names:
        return []
    if plugins_dir is None:
        plugins_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "plugins")
    if plugins_dir not in sys.path:
        sys.path.insert(0, plugins_dir)
    loaded = []
    for name in names:
        try:
            mod = importlib.import_module(name)
        except ImportError:
            _die("unknown plugin '%s' (not found in %s)" % (name, plugins_dir))
        loaded.append((name, mod))
    return loaded


def _run_hook(name, fn, args):
    try:
        return fn(*args)
    except SystemExit:
        raise
    except Exception as e:
        _die("plugin '%s' failed in %s: %s: %s" % (name, fn.__name__, type(e).__name__, e))


def run_on_page(plugins, page):
    for name, mod in plugins:
        fn = getattr(mod, "on_page", None)
        if fn is not None:
            page = _run_hook(name, fn, (page,))
    return page


def run_on_html(plugins, page, html):
    for name, mod in plugins:
        fn = getattr(mod, "on_html", None)
        if fn is not None:
            html = _run_hook(name, fn, (page, html))
    return html


def run_on_site(plugins, site, out_dir):
    for name, mod in plugins:
        fn = getattr(mod, "on_site", None)
        if fn is not None:
            _run_hook(name, fn, (site, out_dir))
