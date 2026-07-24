#!/usr/bin/env bash
#
# render-story.sh - 批量渲染 Story JSON 为 Markdown，自动分配 ID，自动校验。
#
# 跨平台：通过 Claude Code 的 Bash 工具运行，Windows(Git Bash)/macOS/Linux 通用。
# 只用 bash + grep，无外部依赖（不依赖 jq）。
#
# 用法：
#   bash render-story.sh <stories_json_dir> <output_dir>
#
#   stories_json_dir : 存放 story-*.json 的目录（通常 docs/_extracted/.stories/）
#   output_dir       : Markdown 输出目录（通常 docs/design/）
#
# 工作流程：
#   1. 扫描 output_dir 中已有的 story-*.md，取最大序号
#   2. 遍历 stories_json_dir 中的 story-*.json（按文件名排序）
#   3. 为每个 JSON 分配下一个可用 ID（story-<nnn>）
#   4. 读取 JSON 字段，渲染 Markdown，写入 output_dir/story-<nnn>.md
#   5. 对每个渲染结果运行 validate-story.sh 做写作规范校验
#
# Story JSON 字段结构：
#   {
#     "id": "story-001",          // 被脚本自动分配的 ID 覆盖
#     "type": "user-story",
#     "projectId": "model-config",
#     "title": "创建模型配置",
#     "featureId": "feature-001",
#     "role": "算法工程师",
#     "goal": "创建新的模型配置",
#     "value": "快速启用模型进行实验",
#     "priority": "P0",
#     "storyPoints": "3",
#     "acCount": "4",
#     "ac_1_keyword": "成功创建",
#     "ac_1_given": "...",
#     "ac_1_when": "...",
#     "ac_1_then": "...",
#     "ac_2_keyword": "...",
#     ...
#   }
#
set -euo pipefail

stories_dir="${1:?missing stories_json_dir}"
output_dir="${2:?missing output_dir}"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ ! -d "$stories_dir" ]; then
  echo "ERROR: stories_json_dir not found: $stories_dir" >&2
  exit 2
fi

mkdir -p "$output_dir"

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
  val="${val//\\\\/\\}"  # \\ → \
  val="${val//\\n/
}"                       # \n → 换行
  val="${val//\\t/	}"   # \t → tab
  val="${val//\\\"/\"}"  # \" → "
  echo "$val"
}

# ---- 自动分配 ID ----
allocate_next_id() {
  local dir="$1"
  local prefix="$2"   # "story"
  local max_num=0

  # 扫描已有文件
  for f in "$dir"/${prefix}-*.md; do
    [ -f "$f" ] || continue
    local fname
    fname=$(basename "$f")
    local num
    num=$(echo "$fname" | sed "s/${prefix}-//" | sed 's/\.md$//')
    # 去除前导零
    num=$((10#$num))
    if [ "$num" -gt "$max_num" ]; then
      max_num="$num"
    fi
  done

  local next_num=$((max_num + 1))
  printf "%s-%03d" "$prefix" "$next_num"
}

# ---- 渲染单个 Story ----
render_one_story() {
  local json_file="$1"
  local story_id="$2"
  local out_file="$3"

  local project_id title feature_id role goal value priority sp ac_count

  project_id=$(json_val "projectId" "$json_file")
  title=$(json_val "title" "$json_file")
  feature_id=$(json_val "featureId" "$json_file")
  role=$(json_val "role" "$json_file")
  goal=$(json_val "goal" "$json_file")
  value=$(json_val "value" "$json_file")
  priority=$(json_val "priority" "$json_file")
  sp=$(json_val "storyPoints" "$json_file")
  ac_count=$(json_val "acCount" "$json_file")

  if [ -z "$ac_count" ]; then
    ac_count=0
  fi
  ac_count=$((10#$ac_count))

  # 渲染 frontmatter + 标题 + 三段式
  {
    cat <<FRONTMATTER
---
id: "$story_id"
type: "user-story"
projectId: "$project_id"
title: "$title"
status: "draft"
refs:
  - id: "$feature_id"
    relation: "implements"
---

# $title

## 用户故事

作为 **$role**，我想要 **$goal**，以便于 **$value**。

## 优先级

$priority

## Story Points 建议

${sp}（建议值，待团队确认）

## 验收标准

FRONTMATTER

    # 渲染 AC 列表
    local i=1
    while [ "$i" -le "$ac_count" ]; do
      local kw given when then
      kw=$(json_val "ac_${i}_keyword" "$json_file")
      given=$(json_val "ac_${i}_given" "$json_file")
      when=$(json_val "ac_${i}_when" "$json_file")
      then=$(json_val "ac_${i}_then" "$json_file")
      echo "${i}. **${kw}**：Given ${given}，When ${when}，Then ${then}"
      i=$((i + 1))
    done

    # 渲染关联 Feature
    echo ""
    echo "## 关联 Feature"
    echo ""
    echo "本 Story 实现 [[${feature_id}]]。"
  } > "$out_file"
}

# ---- 主流程 ----
echo "=== Story 批量渲染 ==="
echo "输入目录: $stories_dir"
echo "输出目录: $output_dir"
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
  # 分配 ID
  story_id=$(allocate_next_id "$output_dir" "story")
  out_file="$output_dir/${story_id}.md"

  # 预占 ID（创建临时文件防止 ID 冲突）
  echo "" > "$out_file"

  echo "渲染: $(basename "$json_file") → ${story_id}.md"

  # 渲染
  render_one_story "$json_file" "$story_id" "$out_file"
  rendered_count=$((rendered_count + 1))

  # 校验
  echo "  校验: ${story_id}.md"
  if bash "$script_dir/validate-story.sh" "$out_file"; then
    echo "  [OK] ${story_id} 校验通过"
  else
    echo "  [FAIL] ${story_id} 校验未通过（详见上方警告）"
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
