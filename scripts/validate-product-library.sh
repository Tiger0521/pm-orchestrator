#!/usr/bin/env bash
# Locate and validate a v2 product library.

set -u

command -v node >/dev/null 2>&1 || { echo "ERROR: Node.js is required for Unicode-safe product-library validation" >&2; exit 2; }

ISSUES=()
TMP_FILES=()
PRODUCT_DIRS=()   # 已登记的产品目录（产品全名），供用户故事地图 product 校验使用
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

validate_library_id() {
  local id="$1" short="$2" doc_type="$3"
  [ -n "$short" ] || return 0
  node -e '
    const id = process.argv[1];
    const short = process.argv[2];
    const docType = process.argv[3];
    const patterns = {
      "需求卡片": `^${short}-REQ$`,
      "设计文档": `^${short}-EPIC$`,
      "能力文档": `^${short}-EPIC-F\\d{2,}$`,
      "用户故事": `^${short}-EPIC-F\\d{2,}-S\\d{2,}$`,
      "需求台账": `^${short}-REQ-LEDGER$`,
      "业务文档": `^${short}-BIZ-DOC$`,
      "结构流程图": `^${short}-DF-FLOW\\d{2,}$`,
      "原型": `^${short}-DF-PROTO\\d{2,}$`,
      "交互契约": `^${short}-DF-CONTRACT\\d{2,}$`,
      "规则摘要": `^${short}-DF-RULES\\d{2,}$`,
      "迭代规划": `^${short}-DF-SPRINT\\d{2,}$`
    };
    const pattern = patterns[docType];
    if (!pattern) process.exit(0);
    process.exit(new RegExp(pattern, "u").test(id) ? 0 : 1);
  ' "$id" "$short" "$doc_type"
}

validate_doc() {
  local file="$1" product="$2" expected_type="$3" expected_capability="${4:-}" short="${5:-}"
  local actual_id actual_product actual_type actual_capability rel
  rel="${file#"$LIBRARY_PATH"/}"
  if [ "$(head -n 1 "$file" | tr -d '\r' | sed 's/^\xef\xbb\xbf//')" != "---" ]; then
    fail_issue "[frontmatter] $rel: 缺少起始 ---"
    return
  fi
  actual_id=$(strip_quotes "$(fm_value "$file" id)")
  actual_product=$(strip_quotes "$(fm_value "$file" product)")
  actual_type=$(strip_quotes "$(fm_value "$file" type)")
  actual_capability=$(strip_quotes "$(fm_value "$file" capability)")
  if [ -z "$actual_id" ]; then
    fail_issue "[frontmatter] $rel: 缺少 id 字段"
  elif [ -n "$short" ] && ! validate_library_id "$actual_id" "$short" "$expected_type"; then
    fail_issue "[frontmatter] $rel: id 格式不合法（应符合产品库 ID 规范，如 ${short}-REQ、${short}-EPIC、${short}-EPIC-F<nnn>、${short}-EPIC-F<nnn>-S<nnn>、${short}-REQ-LEDGER 等）: $actual_id"
  fi
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
  # Bash ERE CJK ranges are unreliable in Windows Git Bash; use Node Unicode regexes.
  node -e 'const value = process.argv[1] ?? ""; process.exit(/^[\u4E00-\u9FFF]+(?:-[\u4E00-\u9FFF]+)*$/u.test(value) ? 0 : 1)' "$name"
}

valid_story_title() {
  local name="$1"
  node -e 'const value = process.argv[1] ?? ""; process.exit(/^[\u4E00-\u9FFFA-Za-z0-9]+(?:-[\u4E00-\u9FFFA-Za-z0-9]+)*$/u.test(value) ? 0 : 1)' "$name"
}

valid_product_name() {
  local name="$1"
  # 产品全名：简称(2-6 汉字)＋全角：＋描述(汉字)，对应 spec 第 2 节。
  node -e 'const value = process.argv[1] ?? ""; process.exit(/^[\u4E00-\u9FFF]{2,6}\uFF1A[\u4E00-\u9FFF]+$/u.test(value) ? 0 : 1)' "$name"
}

valid_short_name() {
  local name="$1"
  node -e 'const value = process.argv[1] ?? ""; process.exit(/^[\u4E00-\u9FFF]{2,6}$/u.test(value) ? 0 : 1)' "$name"
}

unicode_length() {
  node -e 'process.stdout.write(String(Array.from(process.argv[1] ?? "").length))' "$1"
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
  if [ -f "$expected" ]; then validate_doc "$expected" "$product" "能力文档" "$capability" "$short"; else fail_issue "[命名] 缺少 ${expected#"$LIBRARY_PATH"/}"; fi
  story_dir="$dir/用户故事"
  [ -d "$story_dir" ] || { fail_issue "[层级] ${dir#"$LIBRARY_PATH"/}: 叶子能力缺少 用户故事"; return; }
  while IFS= read -r -d '' story; do
    file=$(basename -- "$story")
    prefix="${short}-${capability_slug}-"
    story_title="${file#"$prefix"}"
    story_title="${story_title%.md}"
    if [[ "$file" != "$prefix"*.md ]] || [[ "$story_title" != *故事 ]] || ! valid_story_title "$story_title"; then
      fail_issue "[命名] ${story#"$LIBRARY_PATH"/}: 用户故事文件名应为 简称-能力路径-故事标题故事.md"
    fi
    validate_doc "$story" "$product" "用户故事" "$capability" "$short"
  done < <(find "$story_dir" -maxdepth 1 -type f -name '*.md' -print0)
  while IFS= read -r -d '' file; do fail_issue "[层级] ${file#"$LIBRARY_PATH"/}: 用户故事 内不得有子目录"; done < <(find "$story_dir" -mindepth 1 -maxdepth 1 -type d -print0)
}

validate_capability() {
  local dir="$1" product="$2" short="$3" parent_cap="${4:-}" name capability child_count doc_count has_story child
  name=$(basename -- "$dir")
  valid_name "$name" || fail_issue "[命名] ${dir#"$LIBRARY_PATH"/}: 能力目录含禁用字符"
  [[ "$name" == *能力 ]] || fail_issue "[命名] ${dir#"$LIBRARY_PATH"/}: 能力目录必须以 能力 结尾"
  capability="$name"; [ -n "$parent_cap" ] && capability="$parent_cap/$name"
  child_count=$(find "$dir" -mindepth 1 -maxdepth 1 -type d ! -name 用户故事 | wc -l | tr -d '[:space:]')
  doc_count=$(find "$dir" -maxdepth 1 -type f -name '*-能力文档.md' | wc -l | tr -d '[:space:]')
  has_story=0; [ -d "$dir/用户故事" ] && has_story=1
  if [ "$child_count" -gt 0 ]; then
    [ -z "$parent_cap" ] || fail_issue "[层级] ${dir#"$LIBRARY_PATH"/}: 不允许三级能力目录"
    [ "$doc_count" -eq 0 ] || fail_issue "[层级] ${dir#"$LIBRARY_PATH"/}: 父能力不得有能力文档"
    [ "$has_story" -eq 0 ] || fail_issue "[层级] ${dir#"$LIBRARY_PATH"/}: 父能力不得有 用户故事"
    while IFS= read -r -d '' child; do
      if [[ "$(basename -- "$child")" == *能力 ]]; then
        validate_capability "$child" "$product" "$short" "$name"
      else
        fail_issue "[类别] ${child#"$LIBRARY_PATH"/}: 能力目录下的子目录必须以 能力 结尾"
      fi
    done < <(find "$dir" -mindepth 1 -maxdepth 1 -type d ! -name 用户故事 -print0)
  else
    validate_leaf "$dir" "$product" "$short" "$capability"
  fi
}

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
      in_story_index=0
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
    in_product && /^### 故事索引/ { in_story_index=1; next }
    in_product && in_story_index && /^- \[\[/ { stories++ }
  ' "$ARCH" > "$TABLE_ROWS"
fi

while IFS=$'\t' read -r full short caps stories; do
  [ -n "$full" ] || continue
  PRODUCT_DIRS+=("$full")
  valid_product_name "$full" || fail_issue "[产品矩阵] 产品全名格式应为 简称：描述: $full"
  prefix=$(printf '%s' "$full" | awk -F'：' '{print $1}')
  [ "$short" = "$prefix" ] || fail_issue "[产品矩阵] 简称与全名冒号前缀不符: $full ($short/$prefix)"
  short_len=$(unicode_length "$short")
  [ "$short_len" -ge 2 ] && [ "$short_len" -le 6 ] || fail_issue "[产品矩阵] 简称必须为 2-6 个汉字: $short"
  valid_short_name "$short" || fail_issue "[产品矩阵] 简称只能包含汉字: $short"
  [ "$(awk -F '\t' -v s="$short" '$2 == s {n++} END{print n+0}' "$TABLE_ROWS")" -eq 1 ] || fail_issue "[产品矩阵] 简称重复: $short"
  [ "$(awk -F '\t' -v p="$full" '$1 == p {n++} END{print n+0}' "$TABLE_ROWS")" -eq 1 ] || fail_issue "[产品矩阵] 产品全名重复: $full"
  [ -d "$LIBRARY_PATH/$full" ] || fail_issue "[产品矩阵] 已登记产品目录不存在: $full"
  [[ "$caps" =~ ^[0-9]+$ ]] || fail_issue "[产品矩阵] 能力数不是非负整数: $full"
  [[ "$stories" =~ ^[0-9]+$ ]] || fail_issue "[产品矩阵] 用户故事数不是非负整数: $full"
done < "$TABLE_ROWS"

while IFS= read -r -d '' product_dir; do
  product=$(basename -- "$product_dir")
  short=$(table_short_for "$product")
  if [ -z "$short" ]; then
    # 未在架构文档产品矩阵登记的一级目录：只有符合产品全名格式（简称：描述）的才算"漏登记"；
    # 其余一级目录（如 用户故事地图/）是产品库的非产品目录，不属于产品校验范围，跳过。
    valid_product_name "$product" && fail_issue "[产品矩阵] 产品目录未登记: $product"
    continue
  fi
  [ -f "$product_dir/$short-需求卡片.md" ] || fail_issue "[命名] $product 缺少 $short-需求卡片.md"
  [ -f "$product_dir/$short-设计文档.md" ] || fail_issue "[命名] $product 缺少 $short-设计文档.md"
  [ -f "$product_dir/$short-需求卡片.md" ] && validate_doc "$product_dir/$short-需求卡片.md" "$product" "需求卡片" "" "$short"
  [ -f "$product_dir/$short-设计文档.md" ] && validate_doc "$product_dir/$short-设计文档.md" "$product" "设计文档" "" "$short"
  # 需求台账/业务文档在 V4.1.0 后直接落产品库根目录；对旧产品库不强制存在，存在即校验
  [ -f "$product_dir/$short-需求台账.md" ] && validate_doc "$product_dir/$short-需求台账.md" "$product" "需求台账" "" "$short"
  [ -f "$product_dir/$short-业务文档.md" ] && validate_doc "$product_dir/$short-业务文档.md" "$product" "业务文档" "" "$short"
  while IFS= read -r -d '' file; do
    base=$(basename -- "$file")
    [ "$base" = "$short-需求卡片.md" ] || [ "$base" = "$short-设计文档.md" ] \
      || [ "$base" = "$short-需求台账.md" ] || [ "$base" = "$short-业务文档.md" ] \
      || fail_issue "[命名] ${file#"$LIBRARY_PATH"/}: 产品根目录不允许其他 Markdown"
  done < <(find "$product_dir" -maxdepth 1 -type f -name '*.md' -print0)
  while IFS= read -r -d '' entry_dir; do
    entry_name=$(basename -- "$entry_dir")
    if [[ "$entry_name" == *能力 ]]; then
      validate_capability "$entry_dir" "$product" "$short"
    elif [ "$entry_name" = "用户故事地图" ] || [ "$entry_name" = "详细设计" ]; then
      : # 用户故事地图/详细设计 目录不是能力目录，跳过能力校验
    else
      fail_issue "[类别] ${entry_dir#"$LIBRARY_PATH"/}: 产品目录下的目录既不是能力目录（名称应以 能力 结尾），也不是用户故事地图或详细设计目录"
    fi
  done < <(find "$product_dir" -mindepth 1 -maxdepth 1 -type d -print0)
  actual_caps=$(find "$product_dir" -type f -name '*-能力文档.md' | wc -l | tr -d '[:space:]')
  actual_stories=$(find "$product_dir" -type f -path '*/用户故事/*.md' | wc -l | tr -d '[:space:]')
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
  # 用进程替换而非管道，确保 fail_issue 在父 shell 中生效；\| 为表格单元格内的转义竖线，需一并剥离
  while IFS= read -r target; do
    [ -n "$target" ] || continue
    grep -qxF "$target" "$LINK_TARGETS" || fail_issue "[链接] $rel: 链接目标不存在: [[$target]]"
  done < <(grep -o '\[\[[^]]*\]\]' "$file" 2>/dev/null | sed 's/\[\[//;s/\]\]//' | sed 's/#\^[^|]*//' | sed 's/\\|.*//;s/|.*//' | sort -u)
done < <(find "$LIBRARY_PATH" -type f -name '*.md' ! -path "$ARCH" -print0)

# Product libraries are formal assets, so process-space IDs such as epic-001 must
# never remain in either frontmatter (excluding the id field) or document bodies.
while IFS= read -r -d '' file; do
  rel="${file#"$LIBRARY_PATH"/}"
  process_ids=$(node -e 'const fs = require("fs"); let text = fs.readFileSync(process.argv[1], "utf8"); text = text.replace(/^id:[^\n]*$/m, ""); const ids = [...new Set([...text.matchAll(/(?<![\w\u4E00-\u9FFF^-])(?:req|diagnostic|epic|feature|story|matrix|flow|proto|contract|rules|sprint)-\d+\b/gi)].map((match) => match[0]))]; process.stdout.write(ids.join(", "));' "$file")
  [ -z "$process_ids" ] || fail_issue "[过程 ID] $rel: 产品库不得保留过程文档 ID（frontmatter id 字段除外）: $process_ids"
done < <(find "$LIBRARY_PATH" -type f -name '*.md' -print0)

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

# ---- 用户故事地图契约校验（依据 story-map/output-contract.md 与 persist-guide.md）----
MAP_CAPABILITY_PATHS=()   # 全部能力文档声明的能力路径
while IFS= read -r -d '' cd; do
  MAP_CAPABILITY_PATHS+=("$(strip_quotes "$(fm_value "$cd" capability)")")
done < <(find "$LIBRARY_PATH" -type f -name '*-能力文档.md' -print0)

STORY_BASENAMES=()        # 用户故事文件 basename（不含 .md）
STORY_CAPABILITIES=()     # 对应 capability
while IFS= read -r -d '' st; do
  bn=$(basename -- "$st"); bn="${bn%.md}"
  STORY_BASENAMES+=("$bn")
  STORY_CAPABILITIES+=("$(strip_quotes "$(fm_value "$st" capability)")")
done < <(find "$LIBRARY_PATH" -type f -path '*/用户故事/*.md' -print0)

is_registered_product() {
  local p="$1" d
  for d in "${PRODUCT_DIRS[@]}"; do [ "$d" = "$p" ] && return 0; done
  return 1
}
is_registered_capability() {
  local c="$1" i
  for i in "${!MAP_CAPABILITY_PATHS[@]}"; do [ "${MAP_CAPABILITY_PATHS[$i]}" = "$c" ] && return 0; done
  return 1
}
story_capability_of() {
  local n="$1" i
  for i in "${!STORY_BASENAMES[@]}"; do
    [ "${STORY_BASENAMES[$i]}" = "$n" ] && { printf '%s' "${STORY_CAPABILITIES[$i]}"; return 0; }
  done
  return 1
}

validate_story_map_file() {
  local file="$1" rel notion expected_kind actual_product actual_type actual_capability has_table has_matrix target owner
  rel="${file#"$LIBRARY_PATH"/}"
  notion=$(basename -- "$file")
  if [[ "$notion" != *能力-用户故事地图.md ]]; then
    fail_issue "[命名] $rel: 故事地图文件名应为 {产品名}-{能力名}能力-用户故事地图.md"
    return
  fi
  expected_kind="能力"

  if [ "$(head -n 1 "$file" | tr -d '\r' | sed 's/^\xef\xbb\xbf//')" != "---" ]; then
    fail_issue "[frontmatter] $rel: 缺少起始 ---"; return
  fi
  actual_product=$(strip_quotes "$(fm_value "$file" product)")
  actual_type=$(strip_quotes "$(fm_value "$file" type)")
  actual_capability=$(strip_quotes "$(fm_value "$file" capability)")

  # 产品库正式资产：不得携带过程空间字段
  for k in id status refs projectId; do
    fm_has_key "$file" "$k" && fail_issue "[frontmatter] $rel: 故事地图不得包含 $k"
  done

  [ "$actual_type" = "指南" ] || fail_issue "[frontmatter] $rel: type 应为 指南（当前: ${actual_type:-空}）"
  [ -n "$actual_product" ] || fail_issue "[frontmatter] $rel: 缺少 product"
  if [ -n "$actual_product" ] && ! is_registered_product "$actual_product"; then
    fail_issue "[frontmatter] $rel: product 未在产品库登记: $actual_product"
  fi
  fm_has_list "$file" tags || fail_issue "[frontmatter] $rel: 缺少 tags 列表"
  fm_has_key "$file" title || fail_issue "[frontmatter] $rel: 缺少 title"

  [ -n "$actual_capability" ] || fail_issue "[frontmatter] $rel: 能力级地图缺少 capability"
  if [ -n "$actual_capability" ] && ! is_registered_capability "$actual_capability"; then
    fail_issue "[frontmatter] $rel: capability 未在产品库登记: $actual_capability"
  fi

  has_table=$(grep -c '^|' "$file" || true)
  [ "$has_table" -gt 0 ] || fail_issue "[结构] $rel: 缺少 Markdown 表格（应为 2D 故事地图矩阵）"
  has_matrix=$(grep -cE '^\|\s*\*\*P[0-2]' "$file" || true)
  [ "$has_matrix" -gt 0 ] || fail_issue "[结构] $rel: 矩阵行应含 P0/P1/P2 优先级分层"
  grep -q '行走路径' "$file" || fail_issue "[结构] $rel: 缺少 行走路径 说明"

  # 能力级地图：引用的用户故事必须归属本能力
  if [ "$expected_kind" = "能力" ] && [ -n "$actual_capability" ]; then
    while IFS= read -r target; do
      [ -n "$target" ] || continue
      owner=$(story_capability_of "$target" || true)
      if [ -n "$owner" ] && [ "$owner" != "$actual_capability" ]; then
        fail_issue "[链接] $rel: 链接 [[$target]] 属能力 $owner，与本能力 $actual_capability 不一致"
      fi
    done < <(grep -o '\[\[[^]]*\]\]' "$file" | sed 's/\[\[//;s/\]\]//' | sed 's/\\|.*//;s/|.*//' | sort -u)
  fi
}

while IFS= read -r -d '' map_dir; do
  while IFS= read -r -d '' mf; do
    validate_story_map_file "$mf" "$map_dir"
  done < <(find "$map_dir" -maxdepth 1 -type f -name '*.md' -print0)
done < <(find "$LIBRARY_PATH" -type d -name '用户故事地图' -print0)

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
