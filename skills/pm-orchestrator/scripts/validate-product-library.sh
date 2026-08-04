#!/usr/bin/env bash
# Locate and validate a v2 product library.

set -u

ISSUES=()
TMP_FILES=()
fail_issue() { ISSUES+=("$1"); }
cleanup() { local f; for f in "${TMP_FILES[@]}"; do rm -f -- "$f"; done; }
trap cleanup EXIT

usage() {
  cat <<'EOF'
Usage: bash validate-product-library.sh [产品库路径]

未传路径时，从当前目录向上最多 3 层查找 product-library/。多个候选时只列出候选，不自动选择。
EOF
}

canonical_dir() {
  [ -d "$1" ] || return 1
  (cd -P "$1" 2>/dev/null && pwd)
}

trim() { printf '%s' "$1" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'; }

strip_quotes() {
  local value
  value=$(trim "$1")
  value="${value#\"}"; value="${value%\"}"
  value="${value#\'}"; value="${value%\'}"
  printf '%s' "$value"
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

list_candidates() {
  local container="$1" dir arch
  while IFS= read -r -d '' dir; do
    arch=$(architecture_file "$dir") && printf '%s\0' "$dir"
  done < <(find "$container" -mindepth 1 -maxdepth 1 -type d -print0)
}

# Locate the unique architecture root document by its suffix. The initializer uses
# "<产品库名称>架构设计.md" as the default, but existing libraries only need the regex match.
architecture_file() {
  local library_dir="$1" matches=() file
  while IFS= read -r -d '' file; do matches+=("$file"); done < <(find "$library_dir" -maxdepth 1 -type f -regextype posix-extended -regex '.*[^/]架构设计\.md' -print0)
  [ "${#matches[@]}" -eq 1 ] || return 1
  printf '%s' "${matches[0]}"
}
fm_value() {
  local file="$1" key="$2"
  awk -v key="$key" '
    NR == 1 { sub(/^\xef\xbb\xbf/, ""); if ($0 != "---") exit; in_fm=1; next }
    in_fm && $0 == "---" { exit }
    in_fm && index($0, key ":") == 1 { sub("^[^:]+:[[:space:]]*", ""); print; exit }
  ' "$file"
}

fm_has_key() {
  local file="$1" key="$2"
  awk -v key="$key" '
    NR == 1 { sub(/^\xef\xbb\xbf/, ""); if ($0 != "---") exit 1; in_fm=1; next }
    in_fm && $0 == "---" { exit 1 }
    in_fm && index($0, key ":") == 1 { exit 0 }
    END { if (!in_fm) exit 1 }
  ' "$file"
}

fm_has_list() {
  local file="$1" key="$2"
  awk -v key="$key" '
    NR == 1 { sub(/^\xef\xbb\xbf/, ""); if ($0 != "---") exit 1; in_fm=1; next }
    in_fm && $0 == "---" { exit }
    in_fm && index($0, key ":") == 1 { in_list=1; next }
    in_list && /^[ \t]+-/ { found=1; exit }
    in_list && !/^[ \t]+-/ { exit }
    END { if (!found) exit 1 }
  ' "$file"
}

validate_doc() {
  local file="$1" product="$2" expected_type="$3" expected_capability="${4:-}"
  local actual_product actual_type actual_capability rel
  rel="${file#"$LIBRARY_PATH"/}"
  if [ "$(head -n 1 "$file" | tr -d '\r' | sed 's/^\xef\xbb\xbf//')" != "---" ]; then
    fail_issue "[frontmatter] $rel: 缺少起始 ---"
    return
  fi
  actual_product=$(strip_quotes "$(fm_value "$file" product)")
  actual_type=$(strip_quotes "$(fm_value "$file" type)")
  actual_capability=$(strip_quotes "$(fm_value "$file" capability)")
  [ "$actual_product" = "$product" ] || fail_issue "[frontmatter] $rel: product 应为 $product"
  [ "$actual_type" = "$expected_type" ] || fail_issue "[frontmatter] $rel: type 应为 $expected_type"
  if [ -n "$expected_capability" ]; then
    [ "$actual_capability" = "$expected_capability" ] || fail_issue "[frontmatter] $rel: capability 应为 $expected_capability"
  elif [ -n "$actual_capability" ]; then
    fail_issue "[frontmatter] $rel: 此类型不应包含 capability"
  fi
  fm_has_key "$file" status && fail_issue "[frontmatter] $rel: 产品库文档不得包含 status"
  fm_has_list "$file" aliases || fail_issue "[frontmatter] $rel: 缺少 aliases 列表"
  fm_has_list "$file" tags || fail_issue "[frontmatter] $rel: 缺少 tags 列表"
}

valid_name() {
  local name="$1"
  # 能力目录名/文件名：仅汉字与单个半角中划线（不得连续、不得首尾）
  [[ "$name" =~ ^[一-龥]+(-[一-龥]+)*$ ]] || return 1
  return 0
}

valid_product_name() {
  local name="$1"
  # 产品全名：简称(2-6 汉字)＋全角：＋描述(汉字)，对应 spec 第 2 节
  [[ "$name" =~ ^[一-龥]{2,6}：[一-龥]+$ ]] || return 1
  return 0
}

table_short_for() {
  local product="$1"
  awk -F '\t' -v p="$product" '$1 == p { print $2; exit }' "$TABLE_ROWS"
}

validate_leaf() {
  local dir="$1" product="$2" short="$3" capability="$4" capability_slug doc_count story_dir story file expected
  capability_slug="${capability//\//-}"
  doc_count=$(find "$dir" -maxdepth 1 -type f -name '*-能力文档.md' | wc -l | tr -d '[:space:]')
  [ "$doc_count" -eq 1 ] || fail_issue "[层级] ${dir#"$LIBRARY_PATH"/}: 叶子能力必须有且仅有一份能力文档"
  expected="$dir/$short-$capability_slug-能力文档.md"
  if [ -f "$expected" ]; then validate_doc "$expected" "$product" "能力文档" "$capability"; else fail_issue "[命名] 缺少 ${expected#"$LIBRARY_PATH"/}"; fi
  story_dir="$dir/UserStory"
  [ -d "$story_dir" ] || { fail_issue "[层级] ${dir#"$LIBRARY_PATH"/}: 叶子能力缺少 UserStory"; return; }
  while IFS= read -r -d '' story; do
    file=$(basename -- "$story")
    if [[ ! "$file" =~ ^${short}-${capability_slug}-用户故事[0-9]{2}(-[^[:space:]]+)?\.md$ ]]; then
      fail_issue "[命名] ${story#"$LIBRARY_PATH"/}: 用户故事文件名不符合规范"
    fi
    validate_doc "$story" "$product" "用户故事" "$capability"
  done < <(find "$story_dir" -maxdepth 1 -type f -name '*.md' -print0)
  while IFS= read -r -d '' file; do fail_issue "[层级] ${file#"$LIBRARY_PATH"/}: UserStory 内不得有子目录"; done < <(find "$story_dir" -mindepth 1 -maxdepth 1 -type d -print0)
}

validate_capability() {
  local dir="$1" product="$2" short="$3" parent_cap="${4:-}" name capability child_count doc_count has_story child
  name=$(basename -- "$dir")
  valid_name "$name" || fail_issue "[命名] ${dir#"$LIBRARY_PATH"/}: 能力目录含禁用字符"
  [[ "$name" == *能力 ]] || fail_issue "[命名] ${dir#"$LIBRARY_PATH"/}: 能力目录必须以 能力 结尾"
  capability="$name"; [ -n "$parent_cap" ] && capability="$parent_cap/$name"
  child_count=$(find "$dir" -mindepth 1 -maxdepth 1 -type d ! -name UserStory | wc -l | tr -d '[:space:]')
  doc_count=$(find "$dir" -maxdepth 1 -type f -name '*-能力文档.md' | wc -l | tr -d '[:space:]')
  has_story=0; [ -d "$dir/UserStory" ] && has_story=1
  if [ "$child_count" -gt 0 ]; then
    [ -z "$parent_cap" ] || fail_issue "[层级] ${dir#"$LIBRARY_PATH"/}: 不允许三级能力目录"
    [ "$doc_count" -eq 0 ] || fail_issue "[层级] ${dir#"$LIBRARY_PATH"/}: 父能力不得有能力文档"
    [ "$has_story" -eq 0 ] || fail_issue "[层级] ${dir#"$LIBRARY_PATH"/}: 父能力不得有 UserStory"
    while IFS= read -r -d '' child; do validate_capability "$child" "$product" "$short" "$name"; done < <(find "$dir" -mindepth 1 -maxdepth 1 -type d ! -name UserStory -print0)
  else
    validate_leaf "$dir" "$product" "$short" "$capability"
  fi
}

[ "$#" -le 1 ] || { usage >&2; exit 2; }

if [ "$#" -eq 1 ]; then
  LIBRARY_PATH=$(canonical_dir "$1") || { printf 'LIBRARY_STATUS=NOT_EXISTS\n' >&2; exit 2; }
  [ "$(basename -- "$(dirname -- "$LIBRARY_PATH")")" = "product-library" ] || fail_issue "[定位] 产品库必须是 product-library/ 的一级子目录"
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

ARCH=$(architecture_file "$LIBRARY_PATH") || fail_issue "[根标识] 缺少或存在多个匹配 ^.+架构设计\\.md$ 的根文档"

TABLE_ROWS=$(mktemp); TMP_FILES+=("$TABLE_ROWS")
if [ -f "$ARCH" ]; then
  awk '
    /<!-- product-matrix:start -->/ { in_matrix=1; next }
    /<!-- product-matrix:end -->/ { in_matrix=0; next }
    in_matrix && /^<!-- product:.*:start -->$/ {
      line=$0
      sub(/^<!-- product:/, "", line)
      sub(/:start -->$/, "", line)
      full=line
      short=""
      caps=0
      stories=0
      in_product=1
      next
    }
    in_product && /^<!-- product:.*:end -->$/ {
      print full "\t" short "\t" caps "\t" stories
      in_product=0
      next
    }
    in_product && /^\*\*简称\*\*：/ {
      short=$0
      sub(/^\*\*简称\*\*：/, "", short)
      gsub(/^[ \t]+|[ \t]+$/, "", short)
      next
    }
    in_product && /^- \[\[.*能力文档/ { caps++ }
    in_product && /^- \[\[.*用户故事/ { stories++ }
  ' "$ARCH" > "$TABLE_ROWS"
fi

while IFS=$'\t' read -r full short caps stories; do
  [ -n "$full" ] || continue
  valid_product_name "$full" || fail_issue "[产品矩阵] 产品全名格式应为 简称：描述: $full"
  prefix=$(printf '%s' "$full" | awk -F'：' '{print $1}')
  [ "$short" = "$prefix" ] || fail_issue "[产品矩阵] 简称与全名冒号前缀不符: $full ($short/$prefix)"
  short_len=$(printf '%s' "$short" | awk '{print length($0)}')
  [ "$short_len" -ge 2 ] && [ "$short_len" -le 6 ] || fail_issue "[产品矩阵] 简称必须为 2-6 个汉字: $short"
  [[ "$short" =~ ^[一-龥]{2,6}$ ]] || fail_issue "[产品矩阵] 简称只能包含汉字: $short"
  [ "$(awk -F '\t' -v s="$short" '$2 == s {n++} END{print n+0}' "$TABLE_ROWS")" -eq 1 ] || fail_issue "[产品矩阵] 简称重复: $short"
  [ "$(awk -F '\t' -v p="$full" '$1 == p {n++} END{print n+0}' "$TABLE_ROWS")" -eq 1 ] || fail_issue "[产品矩阵] 产品全名重复: $full"
  [ -d "$LIBRARY_PATH/$full" ] || fail_issue "[产品矩阵] 已登记产品目录不存在: $full"
  [[ "$caps" =~ ^[0-9]+$ ]] || fail_issue "[产品矩阵] 能力数不是非负整数: $full"
  [[ "$stories" =~ ^[0-9]+$ ]] || fail_issue "[产品矩阵] 用户故事数不是非负整数: $full"
done < "$TABLE_ROWS"

while IFS= read -r -d '' product_dir; do
  product=$(basename -- "$product_dir")
  short=$(table_short_for "$product")
  if [ -z "$short" ]; then fail_issue "[产品矩阵] 产品目录未登记: $product"; continue; fi
  [ -f "$product_dir/$short-需求卡片.md" ] || fail_issue "[命名] $product 缺少 $short-需求卡片.md"
  [ -f "$product_dir/$short-设计文档.md" ] || fail_issue "[命名] $product 缺少 $short-设计文档.md"
  [ -f "$product_dir/$short-需求卡片.md" ] && validate_doc "$product_dir/$short-需求卡片.md" "$product" "需求卡片"
  [ -f "$product_dir/$short-设计文档.md" ] && validate_doc "$product_dir/$short-设计文档.md" "$product" "设计文档"
  while IFS= read -r -d '' file; do
    base=$(basename -- "$file")
    [ "$base" = "$short-需求卡片.md" ] || [ "$base" = "$short-设计文档.md" ] || fail_issue "[命名] ${file#"$LIBRARY_PATH"/}: 产品根目录不允许其他 Markdown"
  done < <(find "$product_dir" -maxdepth 1 -type f -name '*.md' -print0)
  while IFS= read -r -d '' cap_dir; do validate_capability "$cap_dir" "$product" "$short"; done < <(find "$product_dir" -mindepth 1 -maxdepth 1 -type d -print0)
  actual_caps=$(find "$product_dir" -type f -name '*-能力文档.md' | wc -l | tr -d '[:space:]')
  actual_stories=$(find "$product_dir" -type f -path '*/UserStory/*.md' | wc -l | tr -d '[:space:]')
  declared_caps=$(awk -F '\t' -v p="$product" '$1 == p {print $3; exit}' "$TABLE_ROWS")
  declared_stories=$(awk -F '\t' -v p="$product" '$1 == p {print $4; exit}' "$TABLE_ROWS")
  [ "$declared_caps" = "$actual_caps" ] || fail_issue "[产品矩阵] $product 能力数应为 $actual_caps"
  [ "$declared_stories" = "$actual_stories" ] || fail_issue "[产品矩阵] $product 用户故事数应为 $actual_stories"
done < <(find "$LIBRARY_PATH" -mindepth 1 -maxdepth 1 -type d ! -name '.*' -print0)

DUPES=$(mktemp); TMP_FILES+=("$DUPES")
find "$LIBRARY_PATH" -type f -name '*.md' ! -path "$ARCH" -exec basename {} \; | sort | uniq -d > "$DUPES"
while IFS= read -r duplicate; do [ -n "$duplicate" ] && fail_issue "[唯一性] 同名文件: $duplicate"; done < "$DUPES"

# Link integrity: check all [[link]] targets exist
LINK_TARGETS=$(mktemp); TMP_FILES+=("$LINK_TARGETS")
find "$LIBRARY_PATH" -type f -name '*.md' ! -path "$ARCH" -exec basename {} .md \; | sort -u > "$LINK_TARGETS"
while IFS= read -r -d '' file; do
  rel="${file#"$LIBRARY_PATH"/}"
  grep -o '\[\[[^]]*\]\]' "$file" 2>/dev/null | sed 's/\[\[//;s/\]\]//' | sed 's/|.*//' | sort -u | while IFS= read -r target; do
    [ -n "$target" ] || continue
    grep -qxF "$target" "$LINK_TARGETS" || fail_issue "[链接] $rel: 链接目标不存在: [[$target]]"
  done
done < <(find "$LIBRARY_PATH" -type f -name '*.md' ! -path "$ARCH" -print0)

# Alias conflict: check no alias points to multiple files
ALIAS_LIST=$(mktemp); TMP_FILES+=("$ALIAS_LIST")
while IFS= read -r -d '' file; do
  rel="${file#"$LIBRARY_PATH"/}"
  awk -v rel="$rel" '
    NR == 1 { sub(/^\xef\xbb\xbf/, ""); if ($0 != "---") exit; in_fm=1; next }
    in_fm && $0 == "---" { exit }
    in_fm && index($0, "aliases:") == 1 { in_aliases=1; next }
    in_aliases && /^[ \t]+-/ {
      line=$0
      sub(/^[ \t]+- /, "", line)
      gsub(/^[ \t]+|[ \t]+$/, "", line)
      print line "\t" rel
    }
    in_aliases && !/^[ \t]+-/ { in_aliases=0 }
  ' "$file"
done < <(find "$LIBRARY_PATH" -type f -name '*.md' ! -path "$ARCH" -print0) | sort > "$ALIAS_LIST"
cut -f1 "$ALIAS_LIST" | sort | uniq -d | while IFS= read -r dup; do
  [ -n "$dup" ] && fail_issue "[别名] 别名冲突: $dup"
done

if [ "${#ISSUES[@]}" -gt 0 ]; then
  printf 'LIBRARY_STATUS=INVALID\n'
  printf 'PRODUCT_LIBRARY_PATH=%s\n' "$LIBRARY_PATH"
  printf 'Validation failed with %d issue(s).\n' "${#ISSUES[@]}"
  for issue in "${ISSUES[@]}"; do printf '  - %s\n' "$issue"; done
  exit 1
fi

printf 'LIBRARY_STATUS=VALID\n'
printf 'PRODUCT_LIBRARY_PATH=%s\n' "$LIBRARY_PATH"
printf 'ARCHITECTURE_PATH=%s\n' "$ARCH"
exit 0
