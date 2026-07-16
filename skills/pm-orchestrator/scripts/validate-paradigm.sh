#!/usr/bin/env bash
#
# validate-paradigm.sh - 校验 Markdown 文档是否符合 writing-paradigm 范式要求。
#
# 跨平台：通过 Claude Code 的 Bash 工具运行，Windows(Git Bash)/macOS/Linux 通用。
# 只用 bash + grep，无外部依赖。
#
# 用法：
#   bash validate-paradigm.sh <markdown_file>
#
#   markdown_file : 渲染后的 Markdown 文档（req-*.md / epic-*.md / feature-*.md）
#
# 校验内容：
#   1. 分条列点是否使用 **加粗关键词** 领条（而非纯编号或无加粗标签）
#   2. 范式 C 字段（需求基本信息、用户角色、需求评估结果）是否有表格
#   3. 范式 D 字段（现状描述、核心场景）是否有流程图代码块
#   4. 范式 B 字段（产品定位）是否有 blockquote 核心论断
#   5. 范式 F 字段（问题本质还原）是否有"这说明/因此/这意味着"过渡词
#
# 退出码：0 全部通过；1 有警告（建议修正但不阻断）；2 文件问题。
#
set -euo pipefail

md_file="${1:?missing markdown_file}"

if [ ! -f "$md_file" ]; then
  echo "ERROR: file not found: $md_file" >&2
  exit 2
fi

# ---- 从 frontmatter 提取文档类型 ----
doc_type=$(grep '^type:' "$md_file" | head -1 | sed 's/^type: *"//' | sed 's/"$//')
doc_id=$(grep '^id:' "$md_file" | head -1 | sed 's/^id: *"//' | sed 's/"$//')

echo "=== 范式校验: $doc_id ($doc_type) ==="
echo ""

warnings=0
passes=0

# ---- 通用检查：分条列点用加粗关键词领条 ----
check_bold_bullets() {
  local section="$1"
  local field_name="$2"
  local section_content
  section_content=$(sed -n "/^#\+ $section$/,/^#\+ /p" "$md_file" | head -n -1)

  if echo "$section_content" | grep -q '^[0-9]\+\.'; then
    echo "[WARN] $field_name: 检测到编号列表（1. 2. 3.），范式 A 要求用 - **加粗关键词**： 格式"
    warnings=$((warnings + 1))
  fi

  if echo "$section_content" | grep -q '^- \*\*'; then
    echo "[PASS] $field_name: 检测到加粗关键词领条"
    passes=$((passes + 1))
  else
    # 该字段没有分条，可能不需要，不报错
    :
  fi
}

# ---- 范式 C 检查：表格存在性 ----
check_table() {
  local section="$1"
  local field_name="$2"
  local section_content
  section_content=$(sed -n "/^#\+ $section$/,/^#\+ /p" "$md_file" | head -n -1)

  if echo "$section_content" | grep -q '^|'; then
    echo "[PASS] $field_name: 检测到表格"
    passes=$((passes + 1))
  else
    echo "[WARN] $field_name: 范式 C 要求用表格，但未检测到表格行"
    warnings=$((warnings + 1))
  fi
}

# ---- 范式 D 检查：流程图存在性 ----
check_flowchart() {
  local section="$1"
  local field_name="$2"
  local section_content
  section_content=$(sed -n "/^#\+ $section$/,/^#\+ /p" "$md_file" | head -n -1)

  if echo "$section_content" | grep -q '```text\|```mermaid\|```flowchart'; then
    echo "[PASS] $field_name: 检测到流程图"
    passes=$((passes + 1))
  else
    echo "[WARN] $field_name: 范式 D 要求有流程图，但未检测到代码块"
    warnings=$((warnings + 1))
  fi
}

# ---- 范式 B 检查：blockquote 核心论断 ----
check_blockquote() {
  local section="$1"
  local field_name="$2"
  local section_content
  section_content=$(sed -n "/^#\+ $section$/,/^#\+ /p" "$md_file" | head -n -1)

  if echo "$section_content" | grep -q '^> \*\*'; then
    echo "[PASS] $field_name: 检测到 blockquote 加粗核心论断"
    passes=$((passes + 1))
  else
    echo "[WARN] $field_name: 范式 B 要求 blockquote + 加粗核心论断，但未检测到"
    warnings=$((warnings + 1))
  fi
}

# ---- 范式 F 检查：过渡词存在性 ----
check_transition() {
  local section="$1"
  local field_name="$2"
  local section_content
  section_content=$(sed -n "/^#\+ $section$/,/^#\+ /p" "$md_file" | head -n -1)

  if echo "$section_content" | grep -q '这说明\|因此\|这意味着'; then
    echo "[PASS] $field_name: 检测到范式 F 过渡词"
    passes=$((passes + 1))
  else
    echo "[WARN] $field_name: 范式 F 要求'这说明/因此/这意味着'过渡，但未检测到"
    warnings=$((warnings + 1))
  fi
}

# ---- 范式 A 检查：总结开头 + 加粗领条 ----
check_paradigm_a() {
  local section="$1"
  local field_name="$2"
  local section_content
  section_content=$(sed -n "/^#\+ $section$/,/^#\+ /p" "$md_file" | head -n -1)

  # 检查是否有加粗领条
  if echo "$section_content" | grep -q '^- \*\*'; then
    echo "[PASS] $field_name: 检测到加粗关键词领条"
    passes=$((passes + 1))
  else
    echo "[WARN] $field_name: 范式 A 要求 - **加粗关键词**： 分条，但未检测到"
    warnings=$((warnings + 1))
  fi

  # 检查是否有编号列表（应改为加粗领条）
  if echo "$section_content" | grep -q '^[0-9]\+\.'; then
    echo "[WARN] $field_name: 检测到编号列表，应改为 - **加粗关键词**： 格式"
    warnings=$((warnings + 1))
  fi
}

# ---- 按文档类型路由校验 ----

case "$doc_type" in
  requirement-card)
    echo "--- 需求卡片范式校验 ---"
    check_table "需求基本信息" "需求基本信息"
    check_flowchart "现状描述" "现状描述"
    check_paradigm_a "痛点" "痛点"
    check_transition "问题本质还原" "问题本质还原"
    check_table "需求评估结果" "需求评估结果"
    ;;
  epic)
    echo "--- Epic 范式校验 ---"
    check_blockquote "产品定位" "产品定位"
    check_paradigm_a "产品目标" "产品目标"
    check_table "用户角色" "用户角色"
    check_flowchart "核心场景" "核心场景"
    check_paradigm_a "产品价值" "产品价值"
    check_paradigm_a "范围内" "范围与边界-范围内"
    # 范围外检查"不做"结构
    out_scope=$(sed -n '/^### 范围外$/,/^## /p' "$md_file" | head -n -1)
    if echo "$out_scope" | grep -q '不做'; then
      echo "[PASS] 范围外: 检测到'不做XX'结构"
      passes=$((passes + 1))
    else
      echo "[WARN] 范围外: 范式 A 要求'不做XX：因为…'结构，但未检测到"
      warnings=$((warnings + 1))
    fi
    # 建设思路检查"这一理念的价值"
    build_content=$(sed -n '/^## 建设思路$/,$ p' "$md_file")
    if echo "$build_content" | grep -q '这一理念的价值'; then
      echo "[PASS] 建设思路: 检测到'这一理念的价值'独立段落"
      passes=$((passes + 1))
    else
      echo "[WARN] 建设思路: 设计理念范式要求'这一理念的价值'独立段落，但未检测到"
      warnings=$((warnings + 1))
    fi
    ;;
  feature)
    echo "--- Feature 范式校验 ---"
    check_transition "能力描述" "能力描述"
    check_paradigm_a "能力目标" "能力目标"
    check_paradigm_a "业务价值" "业务价值"
    check_paradigm_a "业务场景" "业务场景"
    check_flowchart "业务流程" "业务流程"
    check_table "业务规则" "业务规则"
    check_transition "技术可行性" "技术可行性"
    check_table "资源投入" "资源投入"
    ;;
  *)
    echo "ERROR: unknown document type: $doc_type" >&2
    exit 2
    ;;
esac

# ---- 汇总 ----
echo ""
echo "=== 汇总: $passes 项通过, $warnings 项警告 ==="

if [ "$warnings" -gt 0 ]; then
  exit 1
else
  exit 0
fi
