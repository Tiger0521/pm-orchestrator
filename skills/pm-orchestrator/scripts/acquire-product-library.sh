#!/usr/bin/env bash
# Acquire an externally provided product library without creating product content.

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  bash acquire-product-library.sh git <远程地址> [本地产品库路径]
  bash acquire-product-library.sh local <已有产品库路径>

git：未提供本地产品库路径时，克隆或更新到
     <当前目录>/product-library/<仓库目录名>。
local：只规范化已有路径，不复制、移动或创建文件。

用户显式提供的产品库路径可以位于任意本地目录。
EOF
}

fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

canonical_dir() {
  [ -d "$1" ] || return 1
  (cd -P "$1" 2>/dev/null && pwd)
}

require_library_path() {
  local requested="$1" parent_input base_input base_abs parent_abs name
  name=$(basename -- "$requested")
  [ -n "$name" ] && [ "$name" != '.' ] && [ "$name" != '..' ] || fail "产品库路径无效: $requested"

  if [ -e "$requested" ]; then
    [ -d "$requested" ] || fail "产品库路径不是目录: $requested"
    PRODUCT_LIBRARY_PATH=$(canonical_dir "$requested") || fail "无法规范化产品库路径: $requested"
    parent_abs=$(canonical_dir "$(dirname -- "$PRODUCT_LIBRARY_PATH")") || fail "无法规范化产品库容器"
    return
  fi

  parent_input=$(dirname -- "$requested")
  if [ "$(basename -- "$parent_input")" = "product-library" ]; then
    base_input=$(dirname -- "$parent_input")
    base_abs=$(canonical_dir "$base_input") || fail "产品库容器的父目录不存在: $base_input"
    parent_abs="$base_abs/product-library"
    [ -e "$parent_abs" ] && [ ! -d "$parent_abs" ] && fail "产品库容器不是目录: $parent_abs"
    mkdir -p -- "$parent_abs"
  else
    parent_abs=$(canonical_dir "$parent_input") || fail "产品库目标父目录不存在: $parent_input"
  fi
  PRODUCT_LIBRARY_PATH="$parent_abs/$name"
}

repository_directory_name() {
  local remote="$1" value
  value="${remote%/}"
  value="${value##*/}"
  value="${value%.git}"
  [ -n "$value" ] && [ "$value" != '.' ] && [ "$value" != '..' ] || fail "无法从远程地址推导产品库目录名，请显式提供本地产品库路径"
  printf '%s' "$value"
}

acquire_git() {
  local remote="$1" destination="${2:-}" origin status
  command -v git >/dev/null 2>&1 || fail "Git 不可用，无法获取产品库"
  [ -n "$remote" ] || fail "缺少 Git 远程地址"
  if [ -z "$destination" ]; then
    destination="$PWD/product-library/$(repository_directory_name "$remote")"
  fi
  require_library_path "$destination"

  if [ -e "$PRODUCT_LIBRARY_PATH" ]; then
    [ -d "$PRODUCT_LIBRARY_PATH/.git" ] || fail "目标已存在但不是 Git 工作树: $PRODUCT_LIBRARY_PATH"
    origin=$(git -C "$PRODUCT_LIBRARY_PATH" remote get-url origin 2>/dev/null) || fail "目标 Git 工作树没有 origin: $PRODUCT_LIBRARY_PATH"
    [ "$origin" = "$remote" ] || fail "目标 origin 与提供的远程地址不一致: $origin"
    status=$(git -C "$PRODUCT_LIBRARY_PATH" status --porcelain) || fail "无法检查目标 Git 工作树: $PRODUCT_LIBRARY_PATH"
    [ -z "$status" ] || fail "目标 Git 工作树有未提交变更，拒绝拉取: $PRODUCT_LIBRARY_PATH"
    git -C "$PRODUCT_LIBRARY_PATH" pull --ff-only
    printf 'LIBRARY_STATUS=PULLED\n'
  else
    git clone -- "$remote" "$PRODUCT_LIBRARY_PATH"
    printf 'LIBRARY_STATUS=CLONED\n'
  fi
  printf 'PRODUCT_LIBRARY_PATH=%s\n' "$PRODUCT_LIBRARY_PATH"
}

acquire_local() {
  [ -d "$1" ] || fail "本地产品库不存在: $1"
  require_library_path "$1"
  printf 'LIBRARY_STATUS=LOCAL_READY\n'
  printf 'PRODUCT_LIBRARY_PATH=%s\n' "$PRODUCT_LIBRARY_PATH"
}

[ "$#" -ge 1 ] || { usage >&2; exit 2; }
case "$1" in
  git)
    [ "$#" -ge 2 ] && [ "$#" -le 3 ] || { usage >&2; exit 2; }
    acquire_git "$2" "${3:-}"
    ;;
  local)
    [ "$#" -eq 2 ] || { usage >&2; exit 2; }
    acquire_local "$2"
    ;;
  -h|--help)
    [ "$#" -eq 1 ] || { usage >&2; exit 2; }
    usage
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac