#!/usr/bin/env bash
#
# render-doc.sh - 从 JSON 字段文件渲染 Markdown 文档并写入项目目录。
#
# 跨平台：通过 Claude Code 的 Bash 工具运行，Windows(Git Bash)/macOS/Linux 通用。
# 只用 bash + grep + printf，无外部依赖。
#
# 用法：
#   bash render-doc.sh <json_file> <output_dir>
#
#   json_file  : AI 生成的字段值 JSON 文件
#   output_dir : 项目 docs/requirement-analysis/ 的绝对路径
#
# JSON 格式见各文档类型的模板文件。
#
set -euo pipefail

json_file="${1:?missing json_file}"
output_dir="${2:?missing output_dir}"

if [ ! -f "$json_file" ]; then
  echo "ERROR: json_file not found: $json_file" >&2
  exit 2
fi

mkdir -p "$output_dir"
output_dir_abs="$(cd -P "$output_dir" 2>/dev/null && pwd)" || {
  echo "ERROR: cannot resolve output_dir: $output_dir" >&2
  exit 2
}

# ---- JSON 值提取 ----
# 从 AI 生成的 JSON 中提取指定 key 的字符串值。
# 处理 \n \t \" \\ 转义。
# 注意：JSON 中最终润色值在 qa_log 之前，head -1 确保只取最终润色值，不误读 qa_log。
json_val() {
  local key="$1"
  local val
  val=$(grep "\"$key\":" "$json_file" | head -1)
  if [ -z "$val" ]; then
    echo "WARN: json_val: key '$key' not found or empty in $json_file" >&2
    printf ''
    return
  fi
  val="${val#*\": \"}"
  val="${val%\"}"
  val="${val%\",}"
  val="${val//\\\\/\\}"   # \\ → \  (must be first: decode literal backslash before decoding \n \t \")
  val="${val//\\n/$'\n'}"   # \n → newline
  val="${val//\\t/$'\t'}"   # \t → tab
  val="${val//\\\"/\"}"     # \" → " (must be after \\ → \, otherwise \" in source becomes " then lost)
  printf '%s' "$val"
}

# ---- 读取公共字段 ----
doc_type=$(json_val "type")
doc_id=$(json_val "id")
project_id=$(json_val "projectId")
title=$(json_val "title")
case "$doc_type" in
  requirement-card) expected_id_regex='^req-[0-9]{3,}$' ;;
  epic)             expected_id_regex='^epic-[0-9]{3,}$' ;;
  feature)          expected_id_regex='^feature-[0-9]{3,}$' ;;
  *)                expected_id_regex='' ;;
esac

if [ -z "$expected_id_regex" ] || ! printf '%s' "$doc_id" | grep -Eq "$expected_id_regex"; then
  echo "ERROR: invalid document id for type '$doc_type': $doc_id" >&2
  exit 2
fi

if ! printf '%s' "$project_id" | grep -Eq '^[a-z0-9][a-z0-9-]{0,62}$'; then
  echo "ERROR: invalid projectId: $project_id" >&2
  exit 2
fi

output_file="$output_dir_abs/${doc_id}.md"
case "$output_file" in
  "$output_dir_abs"/*) ;;
  *) echo "ERROR: output file escaped output_dir: $output_file" >&2; exit 2 ;;
esac

# ---- 渲染函数 ----

render_requirement_card() {
  local requirement_source requester trigger_time affected_scope current_status
  local current_state pain_points root_problem
  local business_value_score business_value_reason impact_score impact_reason feasibility_score feasibility_reason resource_score resource_reason

  requirement_source=$(json_val "requirement_source")
  requester=$(json_val "requester")
  trigger_time=$(json_val "trigger_time")
  affected_scope=$(json_val "affected_scope")
  current_status=$(json_val "current_status")
  current_state=$(json_val "current_state")
  pain_points=$(json_val "pain_points")
  root_problem=$(json_val "root_problem")
  business_value_score=$(json_val "business_value_score")
  business_value_reason=$(json_val "business_value_reason")
  impact_score=$(json_val "impact_score")
  impact_reason=$(json_val "impact_reason")
  feasibility_score=$(json_val "feasibility_score")
  feasibility_reason=$(json_val "feasibility_reason")
  resource_score=$(json_val "resource_score")
  resource_reason=$(json_val "resource_reason")

  printf '%s\n' \
    '---' \
    "id: \"$doc_id\"" \
    'type: "requirement-card"' \
    "projectId: \"$project_id\"" \
    "title: \"$title\"" \
    'status: "draft"' \
    'refs: []' \
    '---' \
    '' \
    "# $title" \
    '' \
    '```' \
    '需求卡片 ──────────────→ Epic ──────────────→ Feature' \
    '  ▲                        │                     │' \
    '  │ 5 个字段                │ 9 个字段             │ 12 个字段' \
    '  │                        │                     │' \
    '  ├ 需求基本信息             ├ 产品名称             ├ 能力名称' \
    '  ├ 现状描述                ├ 产品定位             ├ 能力描述' \
    '  ├ 痛点                   ├ 产品目标             ├ 能力目标' \
    '  ├ 问题本质还原             ├ 用户角色             ├ 业务价值' \
    '  └ 需求评估结果             ├ 核心场景             ├ 业务场景' \
    '                           ├ 产品价值             ├ 业务流程' \
    '                           ├ 范围边界             ├ 业务规则' \
    '                           └ 建设思路             ├ 技术可行性' \
    '                                                  ├ 资源投入' \
    '                                                  └ 优先级' \
    '```' \
    '' \
    '## 需求基本信息' \
    '' \
    '| 字段 | 内容 |' \
    '| --- | --- |' \
    "| 需求来源 | $requirement_source |" \
    "| 提出人/角色 | $requester |" \
    "| 触发时间/时机 | $trigger_time |" \
    "| 影响范围 | $affected_scope |" \
    "| 当前状态 | $current_status |" \
    '' \
    '## 现状描述' \
    '' \
    "$current_state" \
    '' \
    '## 痛点' \
    '' \
    "$pain_points" \
    '' \
    '## 问题本质还原' \
    '' \
    "$root_problem" \
    '' \
    '## 需求评估结果' \
    '' \
    '| 维度 | 评分/结论 | 理由 |' \
    '| --- | --- | --- |' \
    "| 业务价值 | $business_value_score | $business_value_reason |" \
    "| 影响 | $impact_score | $impact_reason |" \
    "| 可行性 | $feasibility_score | $feasibility_reason |" \
    "| 资源 | $resource_score | $resource_reason |" \
    > "$output_file"
}

render_epic() {
  local req_id requirement_bg product_name positioning product_goals
  local user_roles core_scenarios product_value in_scope out_of_scope
  local build_approach

  req_id=$(json_val "req_id")
  requirement_bg=$(json_val "requirement_bg")
  product_name=$(json_val "product_name")
  positioning=$(json_val "positioning")
  product_goals=$(json_val "product_goals")
  user_roles=$(json_val "user_roles")
  core_scenarios=$(json_val "core_scenarios")
  product_value=$(json_val "product_value")
  in_scope=$(json_val "in_scope")
  out_of_scope=$(json_val "out_of_scope")
  build_approach=$(json_val "build_approach")

  printf '%s\n' \
    '---' \
    "id: \"$doc_id\"" \
    'type: "epic"' \
    "projectId: \"$project_id\"" \
    "title: \"$title\"" \
    'status: "draft"' \
    'refs:' \
    "  - id: \"$req_id\"" \
    '    relation: "derived-from"' \
    '---' \
    '' \
    "# $title" \
    '' \
    '```' \
    '需求卡片 ──────────────→ Epic ──────────────→ Feature' \
    '  │                        ▲                     │' \
    '  │ 5 个字段                │ 9 个字段             │ 12 个字段' \
    '  │                        │                     │' \
    '  ├ 需求基本信息             ├ 产品名称             ├ 能力名称' \
    '  ├ 现状描述                ├ 产品定位             ├ 能力描述' \
    '  ├ 痛点                   ├ 产品目标             ├ 能力目标' \
    '  ├ 问题本质还原             ├ 用户角色             ├ 业务价值' \
    '  └ 需求评估结果             ├ 核心场景             ├ 业务场景' \
    '                           ├ 产品价值             ├ 业务流程' \
    '                           ├ 范围边界             ├ 业务规则' \
    '                           └ 建设思路             ├ 技术可行性' \
    '                                                  ├ 资源投入' \
    '                                                  └ 优先级' \
    '```' \
    '' \
    '## 需求背景' \
    '' \
    "本 Epic 派生自 [@$req_id]：$requirement_bg" \
    '' \
    '## 产品名称' \
    '' \
    "$product_name" \
    '' \
    '## 产品定位' \
    '' \
    "$positioning" \
    '' \
    '## 产品目标' \
    '' \
    "$product_goals" \
    '' \
    '## 用户角色' \
    '' \
    "$user_roles" \
    '' \
    '## 核心场景' \
    '' \
    "$core_scenarios" \
    '' \
    '## 产品价值' \
    '' \
    "$product_value" \
    '' \
    '## 产品范围与边界' \
    '' \
    '### 范围内' \
    '' \
    "$in_scope" \
    '' \
    '### 范围外' \
    '' \
    "$out_of_scope" \
    '' \
    '## 建设思路' \
    '' \
    "$build_approach" \
    > "$output_file"
}

render_feature() {
  local req_id epic_id requirement_bg capability_name capability_description
  local capability_goal user_roles business_value business_scenarios
  local business_process business_rules tech_feasibility resource_investment
  local priority priority_reason

  req_id=$(json_val "req_id")
  epic_id=$(json_val "epic_id")
  requirement_bg=$(json_val "requirement_bg")
  capability_name=$(json_val "capability_name")
  capability_description=$(json_val "capability_description")
  capability_goal=$(json_val "capability_goal")
  user_roles=$(json_val "user_roles")
  business_value=$(json_val "business_value")
  business_scenarios=$(json_val "business_scenarios")
  business_process=$(json_val "business_process")
  business_rules=$(json_val "business_rules")
  tech_feasibility=$(json_val "tech_feasibility")
  resource_investment=$(json_val "resource_investment")
  priority=$(json_val "priority")
  priority_reason=$(json_val "priority_reason")

  printf '%s\n' \
    '---' \
    "id: \"$doc_id\"" \
    'type: "feature"' \
    "projectId: \"$project_id\"" \
    "title: \"$title\"" \
    'status: "draft"' \
    'refs:' \
    "  - id: \"$epic_id\"" \
    '    relation: "belongs-to"' \
    "  - id: \"$req_id\"" \
    '    relation: "references"' \
    '---' \
    '' \
    "# $title" \
    '' \
    '```' \
    '需求卡片 ──────────────→ Epic ──────────────→ Feature' \
    '  │                        │                     ▲' \
    '  │ 5 个字段                │ 9 个字段             │ 12 个字段' \
    '  │                        │                     │' \
    '  ├ 需求基本信息             ├ 产品名称             ├ 能力名称' \
    '  ├ 现状描述                ├ 产品定位             ├ 能力描述' \
    '  ├ 痛点                   ├ 产品目标             ├ 能力目标' \
    '  ├ 问题本质还原             ├ 用户角色             ├ 业务价值' \
    '  └ 需求评估结果             ├ 核心场景             ├ 业务场景' \
    '                           ├ 产品价值             ├ 业务流程' \
    '                           ├ 范围边界             ├ 业务规则' \
    '                           └ 建设思路             ├ 技术可行性' \
    '                                                  ├ 资源投入' \
    '                                                  └ 优先级' \
    '```' \
    '' \
    '## 需求背景' \
    '' \
    "本 Feature 回应 [@$req_id] 中的需求：$requirement_bg" \
    '' \
    '## 能力名称' \
    '' \
    "$capability_name" \
    '' \
    '## 能力描述' \
    '' \
    "$capability_description" \
    '' \
    '## 能力目标' \
    '' \
    "$capability_goal" \
    '' \
    '## 用户角色' \
    '' \
    "引用 [@$epic_id] 中的角色：$user_roles" \
    '' \
    '## 业务价值' \
    '' \
    "$business_value" \
    '' \
    '## 业务场景' \
    '' \
    "$business_scenarios" \
    '' \
    '## 业务流程' \
    '' \
    "$business_process" \
    '' \
    '## 业务规则' \
    '' \
    "$business_rules" \
    '' \
    '## 技术可行性' \
    '' \
    "$tech_feasibility" \
    '' \
    '## 资源投入' \
    '' \
    "$resource_investment" \
    '' \
    '## 优先级' \
    '' \
    "$priority（排序依据：$priority_reason）" \
    > "$output_file"
}

# ---- 路由 ----

case "$doc_type" in
  requirement-card) render_requirement_card ;;
  epic)             render_epic ;;
  feature)          render_feature ;;
  *)
    echo "ERROR: unknown document type: $doc_type" >&2
    exit 3
    ;;
esac

echo "OK: $output_file"

# ---- 范式校验（渲染后自动执行） ----
# 定位 validate-paradigm.sh（与本脚本同目录）
script_dir="$(cd "$(dirname "$0")" && pwd)"
validator="$script_dir/validate-paradigm.sh"

if [ -f "$validator" ]; then
  echo "--- 范式校验 ---"
  bash "$validator" "$output_file"
  validate_exit=$?
  if [ "$validate_exit" -ne 0 ]; then
    echo "--- 错误: 存在范式不合规项，必须修复字段 JSON 并重新渲染后才能确认落盘 ---"
    exit 1
  fi
else
  echo "WARN: validate-paradigm.sh not found, skipping paradigm validation" >&2
fi
