#!/usr/bin/env bash
#
# render-matrix.sh - 渲染溯源矩阵 JSON 为 Markdown，自动分配 ID。
#
# 跨平台：通过 Claude Code 的 Bash 工具运行，Windows(Git Bash)/macOS/Linux 通用。
# 只用 bash + grep，无外部依赖（不依赖 jq）。
#
# 用法：
#   bash render-matrix.sh <matrix_json_file> <output_dir>
#
#   matrix_json_file : 溯源矩阵 JSON 文件（matrix-*.json）
#   output_dir       : Markdown 输出目录（通常 docs/design/）
#
# 工作流程：
#   1. 扫描 output_dir 中已有的 matrix-*.md，取最大序号
#   2. 分配下一个可用 ID（matrix-<nnn>）
#   3. 读取 JSON 字段，渲染 Markdown，写入 output_dir/matrix-<nnn>.md
#
# 矩阵 JSON 字段结构：
#   {
#     "id": "matrix-001",
#     "type": "traceability-matrix",
#     "projectId": "model-config",
#     "title": "Story-Feature 溯源矩阵",
#     "featureCount": "1",
#     "feature_1_id": "feature-001",
#     "feature_1_name": "模型配置管理",
#     "feature_1_priority": "P0",
#     "feature_1_status": "approved",
#     "storyCount": "2",
#     "story_1_id": "story-001",
#     "story_1_title": "创建模型配置",
#     "story_1_role": "算法工程师",
#     "story_1_priority": "P0",
#     "story_1_sp": "3",
#     "mappingCount": "2",
#     "mapping_1_story": "story-001",
#     "mapping_1_feature": "feature-001",
#     "mapping_1_coverage": "完整"
#   }
#
set -euo pipefail

matrix_json="${1:?missing matrix_json_file}"
output_dir="${2:?missing output_dir}"

if [ ! -f "$matrix_json" ]; then
  echo "ERROR: matrix_json_file not found: $matrix_json" >&2
  exit 2
fi

mkdir -p "$output_dir"

# ---- JSON 值提取（不依赖 jq） ----
json_val() {
  local key="$1"
  local file="$2"
  local val
  val=$(grep "\"$key\":" "$file" | head -1)
  val="${val#*\": \"}"
  val="${val%\"}"
  val="${val%\",}"
  val="${val//\\\\/\\}"
  val="${val//\\n/
}"
  val="${val//\\t/	}"
  val="${val//\\\"/\"}"
  echo "$val"
}

# ---- 自动分配 ID ----
allocate_next_id() {
  local dir="$1"
  local prefix="$2"
  local max_num=0

  for f in "$dir"/${prefix}-*.md; do
    [ -f "$f" ] || continue
    local fname
    fname=$(basename "$f")
    local num
    num=$(echo "$fname" | sed "s/${prefix}-//" | sed 's/\.md$//')
    num=$((10#$num))
    if [ "$num" -gt "$max_num" ]; then
      max_num="$num"
    fi
  done

  local next_num=$((max_num + 1))
  printf "%s-%03d" "$prefix" "$next_num"
}

# ---- 读取矩阵字段 ----
project_id=$(json_val "projectId" "$matrix_json")
title=$(json_val "title" "$matrix_json")
feature_count=$(json_val "featureCount" "$matrix_json")
story_count=$(json_val "storyCount" "$matrix_json")
mapping_count=$(json_val "mappingCount" "$matrix_json")

if [ -z "$feature_count" ]; then feature_count=0; fi
if [ -z "$story_count" ]; then story_count=0; fi
if [ -z "$mapping_count" ]; then mapping_count=0; fi

feature_count=$((10#$feature_count))
story_count=$((10#$story_count))
mapping_count=$((10#$mapping_count))

# ---- 分配 ID ----
matrix_id=$(allocate_next_id "$output_dir" "matrix")
out_file="$output_dir/${matrix_id}.md"

# 收集第一个 feature_id 作为 refs（如果有的话）
ref_feature_id=""
if [ "$feature_count" -ge 1 ]; then
  ref_feature_id=$(json_val "feature_1_id" "$matrix_json")
fi

echo "=== 矩阵渲染 ==="
echo "输入: $(basename "$matrix_json")"
echo "输出: ${matrix_id}.md"
echo ""

# ---- 渲染 Markdown ----
{
  # Frontmatter
  cat <<FRONTMATTER
---
id: "$matrix_id"
type: "traceability-matrix"
projectId: "$project_id"
title: "$title"
status: "draft"
refs:
  - id: "$ref_feature_id"
    relation: "references"
---

# $title

## Feature 列表

| ID | Feature 名称 | 优先级 | 状态 |
|----|-------------|--------|------|
FRONTMATTER

  # Feature 行
  i=1
  while [ "$i" -le "$feature_count" ]; do
    fid=$(json_val "feature_${i}_id" "$matrix_json")
    fname=$(json_val "feature_${i}_name" "$matrix_json")
    fpri=$(json_val "feature_${i}_priority" "$matrix_json")
    fstat=$(json_val "feature_${i}_status" "$matrix_json")
    echo "| $fid | $fname | $fpri | $fstat |"
    i=$((i + 1))
  done

  echo ""
  echo "## Story 列表"
  echo ""
  echo "| ID | Story 标题 | 角色 | 优先级 | Story Points |"
  echo "|----|-----------|------|--------|-------------|"

  # Story 行
  i=1
  while [ "$i" -le "$story_count" ]; do
    sid=$(json_val "story_${i}_id" "$matrix_json")
    stitle=$(json_val "story_${i}_title" "$matrix_json")
    srole=$(json_val "story_${i}_role" "$matrix_json")
    spri=$(json_val "story_${i}_priority" "$matrix_json")
    ssp=$(json_val "story_${i}_sp" "$matrix_json")
    echo "| $sid | $stitle | $srole | $spri | $ssp |"
    i=$((i + 1))
  done

  echo ""
  echo "## 映射关系"
  echo ""
  echo "| Story ID | 实现 Feature ID | 覆盖度 |"
  echo "|----------|----------------|--------|"

  # 映射行
  i=1
  while [ "$i" -le "$mapping_count" ]; do
    mstory=$(json_val "mapping_${i}_story" "$matrix_json")
    mfeature=$(json_val "mapping_${i}_feature" "$matrix_json")
    mcov=$(json_val "mapping_${i}_coverage" "$matrix_json")
    echo "| $mstory | $mfeature | $mcov |"
    i=$((i + 1))
  done

  echo ""
  echo "## 覆盖度检查"
  echo ""

  # 逐 Feature 检查覆盖度
  i=1
  while [ "$i" -le "$feature_count" ]; do
    fid=$(json_val "feature_${i}_id" "$matrix_json")
    echo "- [ ] $fid 至少有一条 Story 实现"
    i=$((i + 1))
  done
  echo "- [ ] 所有高优先级（P0）Feature 已覆盖"
} > "$out_file"

echo "[OK] 矩阵已渲染: $out_file"
exit 0
