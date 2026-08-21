#!/usr/bin/env bash
# Preview or apply a product-short-name change with rollback.

set -euo pipefail
[ "$#" -ge 3 ] && [ "$#" -le 4 ] || {
  echo "Usage: bash rename-product.sh <产品库目录> <产品全名> <新简称> [--apply]" >&2
  exit 2
}
[ "$#" -eq 3 ] || [ "$4" = "--apply" ] || { echo "ERROR: unknown option: $4" >&2; exit 2; }
command -v node >/dev/null 2>&1 || { echo "ERROR: Node.js is required" >&2; exit 1; }

to_native() { if command -v cygpath >/dev/null 2>&1; then cygpath -w "$1"; else printf '%s' "$1"; fi; }
script_dir=$(cd -P "$(dirname "$0")" && pwd)
script_native=$(to_native "$script_dir")
library_native=$(to_native "$1")
bash_native=$(to_native "$BASH")

if [ "$#" -eq 4 ]; then
  exec node "$script_native/product-library-tools.mjs" rename "$script_native" "$library_native" "$2" "$3" --apply "$bash_native"
fi
exec node "$script_native/product-library-tools.mjs" rename "$script_native" "$library_native" "$2" "$3" "$bash_native"
