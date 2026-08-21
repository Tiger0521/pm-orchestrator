#!/usr/bin/env bash
# Fast lightweight product library validation for Step 0 confirmation.
# Only checks structural identity (path, root document, product dirs),
# NOT per-file frontmatter/naming/link integrity.
# For full validation, use validate-product-library.sh.

set -u

ISSUES=()
fail_issue() { ISSUES+=("$1"); }

usage() {
  cat <<'EOF'
Usage: bash validate-product-library-lite.sh [产品库路径]

未传路径时，从当前目录向上最多 3 层查找 product-library/。多个候选时只列出候选，不自动选择。
快速校验：确认路径存在、有唯一架构设计文件、有至少一个产品目录。不逐文件校验。
EOF
}

canonical_dir() {
  [ -d "$1" ] || return 1
  (cd -P "$1" 2>/dev/null && pwd)
}

find_container() {
  local cursor depth parent
  cursor=$(canonical_dir "$PWD") || return 1
  depth=0
  while [ "$depth" -le 3 ]; do
    if [ -d "$cursor/product-library" ]; then
      canonical_dir "$cursor/product-library"
      return 0
    fi
    parent=$(dirname -- "$cursor")
    [ "$parent" != "$cursor" ] || break
    cursor="$parent"
    depth=$((depth + 1))
  done
  return 1
}

# Locate the unique architecture root document by its suffix.
architecture_file() {
  local library_dir="$1" matches=() file
  while IFS= read -r -d '' file; do matches+=("$file"); done < <(find "$library_dir" -maxdepth 1 -type f -regextype posix-extended -regex '.*[^/]架构设计\.md' -print0)
  [ "${#matches[@]}" -eq 1 ] || return 1
  printf '%s' "${matches[0]}"
}

list_candidates() {
  local container="$1" dir arch
  while IFS= read -r -d '' dir; do
    arch=$(architecture_file "$dir") && printf '%s\0' "$dir"
  done < <(find "$container" -mindepth 1 -maxdepth 1 -type d -print0)
}

# ---- main ----

[ "$#" -le 1 ] || { usage >&2; exit 2; }

if [ "$#" -eq 1 ]; then
  LIBRARY_PATH=$(canonical_dir "$1") || { printf 'LIBRARY_STATUS=NOT_EXISTS\n' >&2; exit 2; }
else
  CONTAINER=$(find_container) || { printf 'LIBRARY_STATUS=NOT_FOUND\n'; exit 2; }
  CANDIDATES=()
  while IFS= read -r -d '' item; do CANDIDATES+=("$item"); done < <(list_candidates "$CONTAINER")
  if [ "${#CANDIDATES[@]}" -ne 1 ]; then
    printf 'LIBRARY_STATUS=SELECTION_REQUIRED\n'
    for item in "${CANDIDATES[@]}"; do printf 'PRODUCT_LIBRARY_CANDIDATE=%s\n' "$item"; done
    exit 2
  fi
  LIBRARY_PATH=$(canonical_dir "${CANDIDATES[0]}")
fi

# 1. Confirm exactly one architecture design file (root identifier)
ARCH=$(architecture_file "$LIBRARY_PATH") || fail_issue "[根标识] 缺少或存在多个匹配 ^.+架构设计\\.md$ 的根文档"

# 2. Confirm the architecture file has frontmatter (basic content check)
if [ -n "$ARCH" ]; then
  first_line=$(head -n 1 "$ARCH" | tr -d '\r' | sed 's/^\xef\xbb\xbf//')
  [ "$first_line" = "---" ] || fail_issue "[根标识] 架构设计文件缺少 frontmatter 起始 ---"
fi

# 3. Confirm at least one product subdirectory exists
PRODUCT_COUNT=$(find "$LIBRARY_PATH" -mindepth 1 -maxdepth 1 -type d ! -name '.*' 2>/dev/null | wc -l | tr -d '[:space:]')
[ "$PRODUCT_COUNT" -gt 0 ] || fail_issue "[结构] 产品库目录下没有产品子目录"

# 4. Confirm at least one .md file exists (basic content check)
MD_COUNT=$(find "$LIBRARY_PATH" -type f -name '*.md' 2>/dev/null | wc -l | tr -d '[:space:]')
[ "$MD_COUNT" -gt 0 ] || fail_issue "[结构] 产品库中没有 Markdown 文件"

# ---- output ----

if [ "${#ISSUES[@]}" -gt 0 ]; then
  printf 'LIBRARY_STATUS=INVALID\n'
  printf 'PRODUCT_LIBRARY_PATH=%s\n' "$LIBRARY_PATH"
  [ -n "$ARCH" ] && printf 'ARCHITECTURE_PATH=%s\n' "$ARCH"
  printf 'Lite validation failed with %d issue(s).\n' "${#ISSUES[@]}"
  for issue in "${ISSUES[@]}"; do printf '  - %s\n' "$issue"; done
  exit 1
fi

printf 'LIBRARY_STATUS=VALID\n'
printf 'PRODUCT_LIBRARY_PATH=%s\n' "$LIBRARY_PATH"
printf 'ARCHITECTURE_PATH=%s\n' "$ARCH"
exit 0
