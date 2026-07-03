#!/bin/sh
# check hook-contract-docs: README.md contains signatures, dict keys, error semantics
set -u
README="$(dirname "$0")/plugins/README.md"
fail=0
need() {
  if ! grep -qF -- "$1" "$README"; then
    echo "MISSING: $1" >&2
    fail=1
  fi
}
# exact hook signatures
need 'on_page(page: dict) -> dict'
need 'on_html(page: dict, html: str) -> str'
need 'on_site(site: dict, out_dir: str) -> None'
# page dict keys
for k in path name title md html; do need "\`$k\`"; done
# site dict keys
need '`pages`'
need '`config`'
# execution order + optional rule
need 'list order'
need 'optional'
# error semantics keywords
need 'stderr'
need 'nonzero'
need 'raise'
need 'fails loudly'
[ "$fail" -eq 0 ] && echo "OK: hook-contract-docs" || echo "FAIL: hook-contract-docs" >&2
exit "$fail"
