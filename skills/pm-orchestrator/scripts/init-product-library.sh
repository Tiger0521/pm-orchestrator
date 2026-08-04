#!/usr/bin/env bash
# Create product-library/<library-name>/<library-name>架构设计.md relative to a chosen base directory.

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: bash init-product-library.sh <产品库名称> [创建起点]

创建起点默认为当前终端目录。脚本不初始化 Git，也不创建产品。
EOF
}

fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

[ "$#" -ge 1 ] && [ "$#" -le 2 ] || { usage >&2; exit 2; }
library_name="$1"
base_dir="${2:-$PWD}"

case "$library_name" in
  ''|'.'|'..'|*'/'*|*'\'*|*':'*|*'*'*|*'?'*|*'<'*|*'>'*|*'|'*|*'"'*)
    fail "产品库名称为空或包含禁用字符: $library_name"
    ;;
esac
[[ "$library_name" =~ [[:space:]] ]] && fail "产品库名称不得包含空白字符: $library_name"
[ -d "$base_dir" ] || fail "创建起点不存在: $base_dir"

base_abs=$(cd -P "$base_dir" && pwd)
container="$base_abs/product-library"
library_dir="$container/$library_name"

[ ! -e "$library_dir" ] || fail "目标已存在: $library_dir"
mkdir -p -- "$library_dir"

architecture_path="$library_dir/${library_name}架构设计.md"

cat > "$architecture_path" <<'EOF'
# 建设背景

在此维护产品库的建设背景、现状与痛点。

# 建设目标

在此维护产品库的建设目标。

# 设计原则

在此维护产品库的设计原则。

# 总体架构图

```mermaid
graph LR
    User[用户]
    Gateway[网关]
    Product[产品矩阵]

    User --> Gateway
    Gateway --> Product
```

# 产品矩阵

<!-- product-matrix:start -->
<!-- 此区域由 export-to-library.sh 自动维护。每个产品的简介概述在标记外手动维护，首次导出时从 Epic 产品定位自动提取。请勿删除标记。 -->
<!-- product-matrix:end -->
EOF

printf 'LIBRARY_STATUS=CREATED\n'
printf 'PRODUCT_LIBRARY_CONTAINER=%s\n' "$container"
printf 'PRODUCT_LIBRARY_PATH=%s\n' "$library_dir"
printf 'ARCHITECTURE_PATH=%s\n' "$architecture_path"
