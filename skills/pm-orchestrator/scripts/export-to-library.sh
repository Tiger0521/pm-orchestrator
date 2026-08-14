#!/usr/bin/env bash
#
# [已废弃] export-to-library.sh - 从过程项目导出到产品库。
#
# 此脚本已废弃。persist 流程现已直接写入产品库格式，不再需要独立的导出步骤。
# 旧项目如需迁移，请使用独立的迁移脚本 backfill-library-ids.mjs。
#
# 保留此文件仅用于向后兼容旧项目的迁移需求。新项目不应使用此脚本。
#
# Preview or apply an incremental export to a v2 product library.
#
set -euo pipefail
[ "$#" -ge 4 ] && [ "$#" -le 5 ] || {
  echo "Usage: bash export-to-library.sh <项目目录> <产品库目录> <产品全名> <产品简称> [--apply]" >&2
  exit 2
}
[ "$#" -eq 4 ] || [ "$5" = "--apply" ] || { echo "ERROR: unknown option: $5" >&2; exit 2; }
command -v node >/dev/null 2>&1 || { echo "ERROR: Node.js is required" >&2; exit 1; }

to_native() { if command -v cygpath >/dev/null 2>&1; then cygpath -w "$1"; else printf '%s' "$1"; fi; }
script_dir=$(cd -P "$(dirname "$0")" && pwd)
script_native=$(to_native "$script_dir")
project_native=$(to_native "$1")
library_native=$(to_native "$2")
bash_native=$(to_native "$BASH")

if [ "$#" -eq 5 ]; then
  exec node "$script_native/product-library-tools.mjs" export "$script_native" "$project_native" "$library_native" "$3" "$4" --apply "$bash_native"
fi
exec node "$script_native/product-library-tools.mjs" export "$script_native" "$project_native" "$library_native" "$3" "$4" "$bash_native"
