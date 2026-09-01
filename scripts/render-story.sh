#!/usr/bin/env bash
#
# render-story.sh - 批量渲染 Story JSON 为 Markdown，写入产品库，自动分配继承式 ID，自动校验。
#
# 跨平台：通过 Claude Code 的 Bash 工具运行，Windows(Git Bash)/macOS/Linux 通用。
# 只用 bash + grep，无外部依赖（不依赖 jq）。
#
# 用法：
#   bash render-story.sh <stories_json_dir> <output_dir> <产品简称> <产品全名> <能力路径>
#
#   stories_json_dir : 存放 story-*.json 的目录（通常 docs/_extracted/.stories/）
#   output_dir       : 产品库中产品目录的绝对路径
#   产品简称         : 如 网资
#   产品全名         : 如 网资：网络资源全生命周期管理
#   能力路径         : Feature 的能力路径（如 设备管理能力/领用审批能力）
#
# 工作流程：
#   1. 从能力文档的 frontmatter id 读取 Feature 的产品库 ID（如 网资-EPIC-F01）
#   2. 扫描 用户故事 目录中已有的故事文档，取最大序号
#   3. 遍历 stories_json_dir 中的 story-*.json（按文件名排序）
#   4. 为每个 JSON 分配下一个可用 ID（<简称>-EPIC-F<nnn>-S<nnn>）
#   5. 读取 JSON 字段（含旅程阶段 journey_stage 与需求台账条目 ID requirementEntryId），
#      渲染 Markdown 写入产品库 用户故事 目录；requirementEntryId 推导为
#      Obsidian 文件链接（[[<简称>-需求台账|<条目ID>]]）并写入 frontmatter refs
#   6. 对每个渲染结果运行 validate-story.sh 做写作规范校验
#
set -euo pipefail

stories_dir="${1:?missing stories_json_dir}"
output_dir="${2:?missing output_dir}"
product_short="${3:?missing 产品简称}"
product_full="${4:?missing 产品全名}"
capability_path="${5:?missing 能力路径}"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ ! -d "$stories_dir" ]; then
  echo "ERROR: stories_json_dir not found: $stories_dir" >&2
  exit 2
fi

mkdir -p "$output_dir"
output_dir_abs="$(cd -P "$output_dir" 2>/dev/null && pwd)" || {
  echo "ERROR: cannot resolve output_dir: $output_dir" >&2
  exit 2
}

capability_slug="${capability_path//\//-}"
capability_dir="$output_dir_abs/${capability_path}"
feature_doc="$capability_dir/${product_short}-${capability_slug}-能力文档.md"
story_dir="$capability_dir/用户故事"
mkdir -p "$story_dir"

# ---- JSON 值提取（不依赖 jq） ----
json_val() {
  local key="$1"
  local file="$2"
  local val
  val=$(grep "\"$key\":" "$file" | head -1)
  # 提取冒号后的字符串值
  val="${val#*\": \"}"   # 去掉 key": " 前缀
  val="${val%\"}"        # 去掉末尾 "（无逗号情况）
  val="${val%\",}"       # 去掉末尾 ",（有逗号情况）
  # 反转义
  val="${val//\\\\/\\}"  # \\ -> \
  val="${val//\\n/
}"                       # \n -> 换行
  val="${val//\\t/	}"   # \t -> tab
  val="${val//\\\"/\"}"  # \" -> "
  echo "$val"
}

# ---- 从 frontmatter 读取 id 字段 ----
read_frontmatter_id() {
  local file="$1"
  [ -f "$file" ] || { printf ''; return; }
  awk '
    NR == 1 { sub(/^\xef\xbb\xbf/, ""); if ($0 != "---") exit; in_fm=1; next }
    in_fm && $0 == "---" { exit }
    in_fm && index($0, "id:") == 1 { sub("^[^:]+:[[:space:]]*", ""); gsub(/^["\x27]|["\x27]$/, ""); print; exit }
  ' "$file"
}

# ---- 读取 Feature 的产品库 ID ----
feature_library_id=$(read_frontmatter_id "$feature_doc")
if [ -z "$feature_library_id" ]; then
  echo "ERROR: 无法从能力文档读取 Feature 产品库 ID: $feature_doc" >&2
  exit 2
fi

# ---- 自动分配故事 ID ----
# 扫描 用户故事 目录中已有文档的 frontmatter id，取同一 Feature 下最大序号 +1
allocate_next_story_id() {
  local feat_id="$1"
  local max_num=0 num id_val
  while IFS= read -r -d '' f; do
    id_val=$(read_frontmatter_id "$f")
    if [[ "$id_val" =~ ^${feat_id}-S([0-9]+)$ ]]; then
      num=$((10#${BASH_REMATCH[1]}))
      [ "$num" -gt "$max_num" ] && max_num="$num"
    fi
  done < <(find "$story_dir" -type f -name '*.md' -print0 2>/dev/null)
  printf "%s-S%02d" "$feat_id" "$((max_num + 1))"
}

# ---- 故事标题转文件名 ----
# 标题只能包含中文、英文字母、数字和单个中划线
story_filename_stem() {
  local title="$1"
  local value
  value="${title%故事}"
  printf '%s故事' "$value"
}

# ---- 渲染单个 Story ----
render_one_story() {
  local json_file="$1"
  local story_id="$2"
  local out_file="$3"

  local title role goal value priority sp ac_count
  local journey_stage req_entry req_seq req_link

  title=$(json_val "title" "$json_file")
  role=$(json_val "role" "$json_file")
  goal=$(json_val "goal" "$json_file")
  value=$(json_val "value" "$json_file")
  priority=$(json_val "priority" "$json_file")
  sp=$(json_val "storyPoints" "$json_file")
  ac_count=$(json_val "acCount" "$json_file")
  journey_stage=$(json_val "journey_stage" "$json_file")
  req_entry=$(json_val "requirementEntryId" "$json_file")

  # 从 requirementEntryId 生成 Obsidian 文件链接（条目是台账表格中的一行，不使用块锚点）
  # 输出 [[<简称>-需求台账|<条目ID>]]（<简称> 复用产品简称参数）
  req_seq=""
  if [[ "$req_entry" =~ -REQ-([0-9]+)$ ]]; then
    req_seq="${BASH_REMATCH[1]}"
  fi
  if [ -n "$req_entry" ] && [ -n "$product_short" ]; then
    req_link="[[${product_short}-需求台账|${req_entry}]]"
  else
    # 无法取得产品简称，回退为纯条目 ID 链接
    req_link="[[${req_entry}]]"
  fi

  if [ -z "$ac_count" ]; then
    ac_count=0
  fi
  ac_count=$((10#$ac_count))

  # 渲染 frontmatter + 标题 + 三段式
  {
    # 产品库 frontmatter
    printf '%s\n' '---'
    printf 'id: "%s"\n' "$story_id"
    printf 'product: "%s"\n' "$product_full"
    printf '%s\n' 'type: "用户故事"'
    printf 'capability: "%s"\n' "$capability_path"
    printf '%s\n' 'aliases:'
    printf '  - %s %s\n' "$capability_path" "$title"
    printf '%s\n' 'tags:'
    printf '  - %s\n' "$product_short"
    printf '%s\n' '  - 用户故事'
    printf '  - %s\n' "$capability_path"
    # refs: implements 指向所属能力文档（Feature 产品库 ID）+ addresses 关联需求台账条目（条目级 ID）
    printf '%s\n' 'refs:'
    printf '  - id: "%s"\n' "$feature_library_id"
    printf '%s\n' '    relation: "implements"'
    if [ -n "$req_entry" ]; then
      printf '  - id: "%s"\n' "$req_entry"
      printf '%s\n' '    relation: "addresses"'
    fi
    printf '%s\n' '---'
    printf '\n'
    printf '<!-- ID: %s -->\n' "$story_id"
    printf '\n'
    printf '# %s\n' "$title"
    printf '\n'
    printf '## 用户故事\n\n'
    printf '作为 **%s**，我想要 **%s**，以便于 **%s**。\n' "$role" "$goal" "$value"
    printf '\n## 旅程阶段\n\n%s\n' "$journey_stage"
    printf '\n## 关联需求\n\n'
    if [ -n "$req_entry" ]; then
      printf '%s\n' "$req_link"
      if [ -z "$product_short" ]; then
        printf '<!-- 注意: 缺少产品简称，无法生成台账文件链接，已回退为纯条目 ID 链接，请人工核对需求台账条目 -->\n' "$req_entry"
      fi
    else
      printf '%s\n' '待关联需求台账条目'
    fi
    printf '\n## 优先级\n\n%s\n' "$priority"
    printf '\n## Story Points 建议\n\n%s（建议值，待团队确认）\n' "$sp"
    printf '\n## 验收标准\n\n'

    # 渲染 AC 列表
    local i=1
    while [ "$i" -le "$ac_count" ]; do
      local kw given when then
      kw=$(json_val "ac_${i}_keyword" "$json_file")
      given=$(json_val "ac_${i}_given" "$json_file")
      when=$(json_val "ac_${i}_when" "$json_file")
      then=$(json_val "ac_${i}_then" "$json_file")
      printf '%d. **%s**：Given %s，When %s，Then %s\n' "$i" "$kw" "$given" "$when" "$then"
      i=$((i + 1))
    done

    # 渲染关联 Feature（使用产品库文件名引用）
    printf '\n## 关联 Feature\n\n'
    printf '本 Story 实现 [[%s-%s-能力文档]]。\n' "$product_short" "$capability_slug"
  } > "$out_file"
}

# ---- 主流程 ----
echo "=== Story 批量渲染 ==="
echo "输入目录: $stories_dir"
echo "输出目录: $story_dir"
echo "Feature ID: $feature_library_id"
echo ""

# 收集所有 story-*.json
json_files=()
for f in "$stories_dir"/story-*.json; do
  [ -f "$f" ] || continue
  json_files+=("$f")
done

if [ "${#json_files[@]}" -eq 0 ]; then
  echo "WARN: 未找到 story-*.json 文件"
  exit 0
fi

# 按文件名排序
IFS=$'\n' sorted_files=($(printf '%s\n' "${json_files[@]}" | sort)); unset IFS

rendered_count=0
validation_failed=0

for json_file in "${sorted_files[@]}"; do
  # 读取标题
  title=$(json_val "title" "$json_file")

  # 轻校验：featureId 必须为规范格式（feature-<nnn>），缺失/畸形时告警以便人工核对能力归属
  feature_id=$(json_val "featureId" "$json_file")
  if [ -z "$feature_id" ] || ! printf '%s' "$feature_id" | grep -qE '^feature-[0-9]+$'; then
    echo "WARN: $(basename "$json_file") 缺少规范 featureId（应为 feature-<nnn>），无法核对能力归属，请确认该 Story 属于能力 $capability_path" >&2
  fi

  # 计算文件名
  filename_stem=$(story_filename_stem "$title")
  out_file="$story_dir/${product_short}-${capability_slug}-${filename_stem}.md"

  # 分配 ID：如果文件已存在，沿用原 ID；否则分配新 ID
  existing_id=$(read_frontmatter_id "$out_file")
  if [ -n "$existing_id" ]; then
    story_id="$existing_id"
  else
    story_id=$(allocate_next_story_id "$feature_library_id")
  fi

  echo "渲染: $(basename "$json_file") -> $(basename "$out_file") ($story_id)"

  # 渲染到临时文件
  tmp_file=$(mktemp "$story_dir/.story.XXXXXX")
  render_one_story "$json_file" "$story_id" "$tmp_file"
  rendered_count=$((rendered_count + 1))

  # 校验
  echo "  校验: $(basename "$out_file")"
  if bash "$script_dir/validate-story.sh" "$tmp_file"; then
    echo "  [OK] $story_id 校验通过"
    mv -f "$tmp_file" "$out_file"
  else
    echo "  [FAIL] $story_id 校验未通过（详见上方警告）"
    rm -f "$tmp_file"
    validation_failed=$((validation_failed + 1))
  fi
  echo ""
done

# ---- 汇总 ----
echo "=== 渲染完成: $rendered_count 个 Story, $validation_failed 个校验未通过 ==="

if [ "$validation_failed" -gt 0 ]; then
  echo ""
  echo "有 Story 校验未通过，请修复对应 JSON 中的字段格式后重新渲染。"
  exit 1
fi

exit 0
