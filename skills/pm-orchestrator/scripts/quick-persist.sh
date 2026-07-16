#!/usr/bin/env bash
#
# quick-persist.sh - 从字段目录快速渲染 Markdown 文档（绕过 JSON 中间层）。
#
# 跨平台：通过 Claude Code 的 Bash 工具运行，Windows(Git Bash)/macOS/Linux 通用。
# 只用 bash + cat + grep + printf，无外部依赖。
#
# 用法：
#   bash quick-persist.sh <fields_dir> <output_dir>
#
#   fields_dir : 包含 meta.json 和各字段 .md 文件的目录
#   output_dir : 输出 Markdown 文件的目录（如 docs/requirement-analysis/）
#
# 字段目录结构（以需求卡片为例）：
#   fields-req-001/
#   ├── meta.json                # 短元数据：id, type, projectId, title, req_id/epic_id
#   ├── requirement_source.md    # 字段正文（纯 markdown，无需 JSON 转义）
#   ├── requester.md
#   ├── trigger_time.md
#   ├── ...
#   └── resource_reason.md
#
# meta.json 格式：
#   {"id":"req-001","type":"requirement-card","projectId":"xxx","title":"..."}
#   epic 额外含 "req_id"；feature 额外含 "req_id" 和 "epic_id"。
#
# 与 render-doc.sh 的区别：
#   - render-doc.sh 从单个大 JSON 读取（含 qa_log），json_val 用 grep+字符串切割，
#     复杂多行值容易出错。适合 draft 模式（需要 qa_log 素材）。
#   - quick-persist.sh 从独立 .md 文件读取（无 qa_log），用 cat 直接读取，
#     无 JSON 转义问题，渲染速度快。适合 persist 模式（只需最终值）。
#   - AI 可并行写多个字段 .md 文件（多个 Write 调用），无需生成单个大 JSON。
#
# 退出码：0 成功；2 参数/文件问题；3 未知文档类型。
#
set -euo pipefail

fields_dir="${1:?missing fields_dir}"
output_dir="${2:?missing output_dir}"
meta_file="$fields_dir/meta.json"

if [ ! -f "$meta_file" ]; then
  echo "ERROR: meta.json not found in: $fields_dir" >&2
  exit 2
fi

mkdir -p "$output_dir"
output_dir_abs="$(cd -P "$output_dir" 2>/dev/null && pwd)" || {
  echo "ERROR: cannot resolve output_dir: $output_dir" >&2
  exit 2
}

# ---- meta.json 值提取（用 sed 健壮提取，兼容有无空格、BOM） ----
meta_val() {
  local key="$1"
  sed -n "s/.*\"$key\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" "$meta_file" | head -1
}

# ---- 读取字段文件（核心优化：cat 直接读取，无 JSON 解析） ----
field_val() {
  local field_name="$1"
  local field_file="$fields_dir/$field_name.md"
  if [ -f "$field_file" ]; then
    cat "$field_file"
  else
    printf ''
  fi
}

# ---- 读取公共元数据 ----
doc_type=$(meta_val "type")
doc_id=$(meta_val "id")
project_id=$(meta_val "projectId")
title=$(meta_val "title")
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

# ---- 校验必填字段文件存在 ----
check_fields() {
  local missing=0
  for f in "$@"; do
    if [ ! -f "$fields_dir/$f.md" ]; then
      echo "WARN: missing field file: $f.md" >&2
      missing=1
    fi
  done
  return $missing
}

# ---- 流程图（三种文档类型箭头位置不同） ----
print_flowchart() {
  local local_arrow="$1"
  printf '```\n'
  printf '需求卡片 ──────────────→ Epic ──────────────→ Feature\n'
  printf '%s\n' "$local_arrow"
  printf '  │ 5 个字段                │ 9 个字段             │ 12 个字段\n'
  printf '  │                        │                     │\n'
  printf '  ├ 需求基本信息             ├ 产品名称             ├ 能力名称\n'
  printf '  ├ 现状描述                ├ 产品定位             ├ 能力描述\n'
  printf '  ├ 痛点                   ├ 产品目标             ├ 能力目标\n'
  printf '  ├ 问题本质还原             ├ 用户角色             ├ 业务价值\n'
  printf '  └ 需求评估结果             ├ 核心场景             ├ 业务场景\n'
  printf '                           ├ 产品价值             ├ 业务流程\n'
  printf '                           ├ 范围边界             ├ 业务规则\n'
  printf '                           └ 建设思路             ├ 技术可行性\n'
  printf '                                                  ├ 资源投入\n'
  printf '                                                  └ 优先级\n'
  printf '```\n'
}

# ---- 渲染：需求卡片 ----
render_requirement_card() {
  check_fields \
    requirement_source requester trigger_time affected_scope current_status \
    current_state pain_points root_problem \
    business_value_score business_value_reason \
    impact_score impact_reason \
    feasibility_score feasibility_reason \
    resource_score resource_reason || true

  local requirement_source requester trigger_time affected_scope current_status
  local current_state pain_points root_problem
  local business_value_score business_value_reason
  local impact_score impact_reason
  local feasibility_score feasibility_reason
  local resource_score resource_reason

  requirement_source=$(field_val "requirement_source")
  requester=$(field_val "requester")
  trigger_time=$(field_val "trigger_time")
  affected_scope=$(field_val "affected_scope")
  current_status=$(field_val "current_status")
  current_state=$(field_val "current_state")
  pain_points=$(field_val "pain_points")
  root_problem=$(field_val "root_problem")
  business_value_score=$(field_val "business_value_score")
  business_value_reason=$(field_val "business_value_reason")
  impact_score=$(field_val "impact_score")
  impact_reason=$(field_val "impact_reason")
  feasibility_score=$(field_val "feasibility_score")
  feasibility_reason=$(field_val "feasibility_reason")
  resource_score=$(field_val "resource_score")
  resource_reason=$(field_val "resource_reason")

  {
    printf '%s\n' '---' \
      "id: \"$doc_id\"" \
      'type: "requirement-card"' \
      "projectId: \"$project_id\"" \
      "title: \"$title\"" \
      'status: "draft"' \
      'refs: []' \
      '---' \
      '' \
      "# $title" \
      ''
    print_flowchart '  ▲                        │                     │'
    printf '%s\n' '' \
      '## 需求基本信息' '' \
      '| 字段 | 内容 |' \
      '| --- | --- |' \
      "| 需求来源 | $requirement_source |" \
      "| 提出人/角色 | $requester |" \
      "| 触发时间/时机 | $trigger_time |" \
      "| 影响范围 | $affected_scope |" \
      "| 当前状态 | $current_status |" \
      '' \
      '## 现状描述' '' \
      "$current_state" '' \
      '## 痛点' '' \
      "$pain_points" '' \
      '## 问题本质还原' '' \
      "$root_problem" '' \
      '## 需求评估结果' '' \
      '| 维度 | 评分/结论 | 理由 |' \
      '| --- | --- | --- |' \
      "| 业务价值 | $business_value_score | $business_value_reason |" \
      "| 影响 | $impact_score | $impact_reason |" \
      "| 可行性 | $feasibility_score | $feasibility_reason |" \
      "| 资源 | $resource_score | $resource_reason |"
  } > "$output_file"
}

# ---- 渲染：Epic ----
render_epic() {
  check_fields \
    requirement_bg product_name positioning product_goals \
    user_roles core_scenarios product_value in_scope out_of_scope build_approach || true

  local req_id requirement_bg product_name positioning product_goals
  local user_roles core_scenarios product_value in_scope out_of_scope build_approach

  req_id=$(meta_val "req_id")
  requirement_bg=$(field_val "requirement_bg")
  product_name=$(field_val "product_name")
  positioning=$(field_val "positioning")
  product_goals=$(field_val "product_goals")
  user_roles=$(field_val "user_roles")
  core_scenarios=$(field_val "core_scenarios")
  product_value=$(field_val "product_value")
  in_scope=$(field_val "in_scope")
  out_of_scope=$(field_val "out_of_scope")
  build_approach=$(field_val "build_approach")

  {
    printf '%s\n' '---' \
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
      ''
    print_flowchart '  │                        ▲                     │'
    printf '%s\n' '' \
      '## 需求背景' '' \
      "本 Epic 派生自 [@$req_id]：$requirement_bg" '' \
      '## 产品名称' '' \
      "$product_name" '' \
      '## 产品定位' '' \
      "$positioning" '' \
      '## 产品目标' '' \
      "$product_goals" '' \
      '## 用户角色' '' \
      "$user_roles" '' \
      '## 核心场景' '' \
      "$core_scenarios" '' \
      '## 产品价值' '' \
      "$product_value" '' \
      '## 产品范围与边界' '' \
      '### 范围内' '' \
      "$in_scope" '' \
      '### 范围外' '' \
      "$out_of_scope" '' \
      '## 建设思路' '' \
      "$build_approach"
  } > "$output_file"
}

# ---- 渲染：Feature ----
render_feature() {
  check_fields \
    requirement_bg capability_name capability_description capability_goal \
    user_roles business_value business_scenarios business_process business_rules \
    tech_feasibility resource_investment priority priority_reason || true

  local req_id epic_id requirement_bg capability_name capability_description
  local capability_goal user_roles business_value business_scenarios
  local business_process business_rules tech_feasibility resource_investment
  local priority priority_reason

  req_id=$(meta_val "req_id")
  epic_id=$(meta_val "epic_id")
  requirement_bg=$(field_val "requirement_bg")
  capability_name=$(field_val "capability_name")
  capability_description=$(field_val "capability_description")
  capability_goal=$(field_val "capability_goal")
  user_roles=$(field_val "user_roles")
  business_value=$(field_val "business_value")
  business_scenarios=$(field_val "business_scenarios")
  business_process=$(field_val "business_process")
  business_rules=$(field_val "business_rules")
  tech_feasibility=$(field_val "tech_feasibility")
  resource_investment=$(field_val "resource_investment")
  priority=$(field_val "priority")
  priority_reason=$(field_val "priority_reason")

  {
    printf '%s\n' '---' \
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
      ''
    print_flowchart '  │                        │                     ▲'
    printf '%s\n' '' \
      '## 需求背景' '' \
      "本 Feature 回应 [@$req_id] 中的需求：$requirement_bg" '' \
      '## 能力名称' '' \
      "$capability_name" '' \
      '## 能力描述' '' \
      "$capability_description" '' \
      '## 能力目标' '' \
      "$capability_goal" '' \
      '## 用户角色' '' \
      "引用 [@$epic_id] 中的角色：$user_roles" '' \
      '## 业务价值' '' \
      "$business_value" '' \
      '## 业务场景' '' \
      "$business_scenarios" '' \
      '## 业务流程' '' \
      "$business_process" '' \
      '## 业务规则' '' \
      "$business_rules" '' \
      '## 技术可行性' '' \
      "$tech_feasibility" '' \
      '## 资源投入' '' \
      "$resource_investment" '' \
      '## 优先级' '' \
      "$priority（排序依据：$priority_reason）"
  } > "$output_file"
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
