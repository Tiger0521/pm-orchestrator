#!/usr/bin/env bash
#
# validate-story.sh - 校验 User Story Markdown 是否符合写作规范。
#
# 跨平台：通过 Claude Code 的 Bash 工具运行，Windows(Git Bash)/macOS/Linux 通用。
# 只用 bash + grep，无外部依赖。
#
# 用法：
#   bash validate-story.sh <markdown_file>
#
#   markdown_file : 渲染后的 Story Markdown 文档（story-*.md）
#
# 校验内容（派生自 writing-paradigm/user-story-writing.md）：
#   1. 三段式格式：作为 **角色**，我想要 **目标**，以便于 **价值**
#   2. 加粗关键词领条：每条 AC 以 **加粗关键词** 开头（不是编号）
#   3. GWT 格式：每条 AC 含 Given / When / Then
#   4. 角色具名：角色不是笼统的"用户"
#   5. 提示语引号：Then 含引号标注的提示语
#   6. AC 数量：3-8 条
#
# 退出码：0 全部通过；1 有警告；2 文件问题。
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

echo "=== Story 写作规范校验: $doc_id ($doc_type) ==="
echo ""

warnings=0
passes=0

# ---- 提取指定章节内容 ----
# 用法: get_section "章节标题"
# 返回该章节到下一个同级或更高级标题之间的内容
get_section() {
  local section="$1"
  sed -n "/^## ${section}$/,/^## /p" "$md_file" | head -n -1
}

# ---- 检查 1: 三段式格式 ----
check_three_part() {
  local story_section
  story_section=$(get_section "用户故事")

  if echo "$story_section" | grep -q '作为 \*\*.*\*\*，我想要 \*\*.*\*\*，以便于 \*\*.*\*\*'; then
    echo "[PASS] 三段式格式: 检测到标准三段式（作为/我想要/以便于，均含加粗）"
    passes=$((passes + 1))
  else
    echo "[WARN] 三段式格式: 未检测到标准三段式格式，应为'作为 **角色**，我想要 **目标**，以便于 **价值**'"
    warnings=$((warnings + 1))
  fi
}

# ---- 检查 2: 加粗关键词领条 ----
check_bold_ac() {
  local ac_section
  ac_section=$(get_section "验收标准")

  # 检查是否有加粗关键词领条的 AC
  local bold_count
  bold_count=$(echo "$ac_section" | grep -c '^[0-9]\+\. \*\*' || true)

  if [ "$bold_count" -gt 0 ]; then
    echo "[PASS] 加粗关键词领条: 检测到 $bold_count 条加粗关键词领条的 AC"
    passes=$((passes + 1))
  else
    echo "[WARN] 加粗关键词领条: 验收标准未使用 **加粗关键词** 领条格式"
    warnings=$((warnings + 1))
  fi

  # 检查是否有非加粗的编号 AC（如 "1. Given ..." 而非 "1. **关键词**：Given ..."）
  local plain_ac
  plain_ac=$(echo "$ac_section" | grep -c '^[0-9]\+\. Given' || true)
  if [ "$plain_ac" -gt 0 ] && [ "$bold_count" -eq 0 ]; then
    echo "[WARN] 加粗关键词领条: 检测到纯编号 AC（1. Given ...），应改为 1. **关键词**：Given ..."
    warnings=$((warnings + 1))
  fi
}

# ---- 检查 3: GWT 格式 ----
check_gwt() {
  local ac_section
  ac_section=$(get_section "验收标准")

  local ac_lines
  ac_lines=$(echo "$ac_section" | grep -c '^[0-9]\+\.' || true)

  if [ "$ac_lines" -eq 0 ]; then
    echo "[WARN] GWT 格式: 未检测到任何验收标准"
    warnings=$((warnings + 1))
    return
  fi

  local given_count when_count then_count
  given_count=$(echo "$ac_section" | grep -c 'Given' || true)
  when_count=$(echo "$ac_section" | grep -c 'When' || true)
  then_count=$(echo "$ac_section" | grep -c 'Then' || true)

  if [ "$given_count" -eq "$ac_lines" ] && [ "$when_count" -eq "$ac_lines" ] && [ "$then_count" -eq "$ac_lines" ]; then
    echo "[PASS] GWT 格式: $ac_lines 条 AC 均含 Given/When/Then"
    passes=$((passes + 1))
  else
    echo "[WARN] GWT 格式: AC 数量($ac_lines)与 Given($given_count)/When($when_count)/Then($then_count) 数量不一致，可能有 AC 缺少 GWT 要素"
    warnings=$((warnings + 1))
  fi
}

# ---- 检查 4: 角色具名 ----
check_role_specific() {
  local story_section
  story_section=$(get_section "用户故事")

  # 提取角色（加粗内容）
  local role
  role=$(echo "$story_section" | grep '作为' | sed 's/.*作为 \*\*//;s/\*\*.*//')

  if [ -z "$role" ]; then
    echo "[WARN] 角色具名: 未提取到角色，请检查三段式格式"
    warnings=$((warnings + 1))
    return
  fi

  case "$role" in
    用户|管理员|普通人)
      echo "[WARN] 角色具名: 角色为'$role'，过于笼统，应具体到角色名（如'算法工程师''VIP 会员'）"
      warnings=$((warnings + 1))
      ;;
    *)
      echo "[PASS] 角色具名: 角色为'$role'，具体可辨识"
      passes=$((passes + 1))
      ;;
  esac
}

# ---- 检查 5: 提示语引号 ----
check_quoted_prompt() {
  local ac_section
  ac_section=$(get_section "验收标准")

  # 检查 Then 行是否含引号标注的提示语
  local then_lines
  then_lines=$(echo "$ac_section" | grep 'Then' || true)
  local quoted_count
  quoted_count=$(echo "$then_lines" | grep -c '"' || true)

  local then_total
  then_total=$(echo "$then_lines" | grep -c '.' || true)

  if [ "$then_total" -eq 0 ]; then
    echo "[WARN] 提示语引号: 未检测到 Then 行"
    warnings=$((warnings + 1))
    return
  fi

  if [ "$quoted_count" -ge "$((then_total / 2))" ] || [ "$quoted_count" -ge 1 ]; then
    echo "[PASS] 提示语引号: $quoted_count/$then_total 条 Then 含引号标注的提示语"
    passes=$((passes + 1))
  else
    echo "[WARN] 提示语引号: Then 中缺少引号标注的提示语，应写具体提示语如\"配置名称已存在\""
    warnings=$((warnings + 1))
  fi
}

# ---- 检查 6: AC 数量 ----
check_ac_count() {
  local ac_section
  ac_section=$(get_section "验收标准")

  local ac_count
  ac_count=$(echo "$ac_section" | grep -c '^[0-9]\+\.' || true)

  if [ "$ac_count" -ge 3 ] && [ "$ac_count" -le 8 ]; then
    echo "[PASS] AC 数量: $ac_count 条，在 3-8 条范围内"
    passes=$((passes + 1))
  elif [ "$ac_count" -lt 3 ]; then
    echo "[WARN] AC 数量: 仅 $ac_count 条，少于 3 条最低要求"
    warnings=$((warnings + 1))
  else
    echo "[WARN] AC 数量: $ac_count 条，超过 8 条上限，应考虑拆分 Story"
    warnings=$((warnings + 1))
  fi
}

# ---- 按文档类型路由校验 ----
case "$doc_type" in
  user-story)
    echo "--- User Story 写作规范校验 ---"
    check_three_part
    check_role_specific
    check_bold_ac
    check_gwt
    check_quoted_prompt
    check_ac_count
    ;;
  *)
    echo "ERROR: unknown document type: $doc_type (expected: user-story)" >&2
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
