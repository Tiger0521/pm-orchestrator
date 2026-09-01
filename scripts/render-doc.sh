#!/usr/bin/env bash
#
# render-doc.sh - 从 JSON 字段文件渲染 Markdown 文档并写入产品库。
#
# 跨平台：通过 Claude Code 的 Bash 工具运行，Windows(Git Bash)/macOS/Linux 通用。
# 只用 bash + grep + printf，无外部依赖。
#
# 用法：
#   bash render-doc.sh <json_file> <output_dir> <产品简称> <产品全名> [能力路径]
#
#   json_file  : AI 生成的字段值 JSON 文件
#   output_dir : 产品库中产品目录的绝对路径
#   产品简称   : 如 网资
#   产品全名   : 如 网资：网络资源全生命周期管理
#   能力路径   : Feature 的能力路径（如 设备管理能力/领用审批能力），需求卡片和 Epic 不传
#
# JSON 格式见各文档类型的模板文件。
#
set -euo pipefail

json_file="${1:?missing json_file}"
output_dir="${2:?missing output_dir}"
product_short="${3:?missing 产品简称}"
product_full="${4:?missing 产品全名}"
capability_path="${5:-}"

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

# requirement_bg 只应包含背景正文；兼容旧输入中的完整引用句，使渲染保持幂等。
normalize_requirement_bg() {
  local value="$1" doc_kind="$2" req_id="$3" prefix
  value="${value#$'\357\273\277'}"
  if [ "$doc_kind" = "epic" ]; then
    prefix="本 Epic 派生自 [[$req_id]]"
  else
    prefix="本 Feature 回应 [[$req_id]] 中的需求"
  fi
  while :; do
    case "$value" in
      "$prefix"：*) value="${value#"$prefix"：}" ;;
      "$prefix":*) value="${value#"$prefix":}" ;;
      *) break ;;
    esac
    value="${value#"${value%%[![:space:]]*}"}"
  done
  printf '%s' "$value"
}
# user_roles 只应包含角色正文；兼容旧输入中的完整引用句"引用 [[epic-id]] 中的角色：..."，使渲染保持幂等。
normalize_user_roles() {
  local value="$1" epic_id="$2" prefix
  value="${value#$'\357\273\277'}"
  prefix="引用 [[$epic_id]] 中的角色"
  while :; do
    case "$value" in
      "$prefix"：*) value="${value#"$prefix"：}" ;;
      "$prefix":*) value="${value#"$prefix":}" ;;
      *) break ;;
    esac
    value="${value#"${value%%[![:space:]]*}"}"
  done
  printf '%s' "$value"
}
# priority_reason 只应含排序依据正文；兼容旧输入中的"排序依据：..."前缀，使渲染保持幂等。
# 注：Feature 已删除「优先级」字段，本函数不再被调用，保留仅用于读取旧版字段 JSON 的幂等渲染。
normalize_priority_reason() {
  local value="$1"
  value="${value#$'\357\273\277'}"
  while :; do
    case "$value" in
      "排序依据"：*) value="${value#"排序依据"：}" ;;
      "排序依据":*) value="${value#"排序依据":}" ;;
      *) break ;;
    esac
    value="${value#"${value%%[![:space:]]*}"}"
  done
  printf '%s' "$value"
}
# ---- 读取公共字段 ----
doc_type=$(json_val "type")
title=$(json_val "title")

# ---- 产品库类型映射 ----
case "$doc_type" in
  requirement-card) lib_type="需求卡片" ;;
  epic)             lib_type="设计文档" ;;
  feature)          lib_type="能力文档" ;;
  structure-flow)     lib_type="结构流程图" ;;
  prototype)          lib_type="原型" ;;
  interaction-contract) lib_type="交互契约" ;;
  rules-summary)      lib_type="规则摘要" ;;
  sprint)             lib_type="迭代规划" ;;
  *)
    echo "ERROR: unknown document type: $doc_type" >&2
    exit 3
    ;;
esac

# ---- 产品库 ID 分配 ----
# 从已有文档的 frontmatter id 定位，若存在则沿用原 ID；否则分配新 ID。
read_frontmatter_id() {
  local file="$1"
  [ -f "$file" ] || { printf ''; return; }
  awk '
    NR == 1 { sub(/^\xef\xbb\xbf/, ""); if ($0 != "---") exit; in_fm=1; next }
    in_fm && $0 == "---" { exit }
    in_fm && index($0, "id:") == 1 { sub("^[^:]+:[[:space:]]*", ""); gsub(/^["\x27]|["\x27]$/, ""); print; exit }
  ' "$file"
}

allocate_feature_id() {
  local short="$1" max_num=0 num id_val
  while IFS= read -r -d '' f; do
    id_val=$(read_frontmatter_id "$f")
    if [[ "$id_val" =~ ^${short}-EPIC-F([0-9]+)$ ]]; then
      num=$((10#${BASH_REMATCH[1]}))
      [ "$num" -gt "$max_num" ] && max_num="$num"
    fi
  done < <(find "$output_dir_abs" -type f -name '*.md' -print0 2>/dev/null)
  printf "%s-EPIC-F%02d" "$short" "$((max_num + 1))"
}

# ---- 详细设计文档 ID 分配 ----
# 扫描 详细设计/<子目录>/ 下已有文档的 frontmatter id，按类型前缀取最大序号 +1。
allocate_design_id() {
  local short="$1" prefix="$2" subdir="$3"
  local design_dir="$output_dir_abs/详细设计/$subdir"
  local max_num=0 num id_val
  while IFS= read -r -d '' f; do
    id_val=$(read_frontmatter_id "$f")
    if [[ "$id_val" =~ ^${short}-DF-${prefix}([0-9]+)$ ]]; then
      num=$((10#${BASH_REMATCH[1]}))
      [ "$num" -gt "$max_num" ] && max_num="$num"
    fi
  done < <(find "$design_dir" -type f -name '*.md' -print0 2>/dev/null)
  printf "%s-DF-%s%02d" "$short" "$prefix" "$((max_num + 1))"
}

# ---- 确定输出路径和 ID ----
case "$doc_type" in
  requirement-card)
    library_id="${product_short}-REQ"
    output_file="$output_dir_abs/${product_short}-需求卡片.md"
    existing_id=$(read_frontmatter_id "$output_file")
    [ -n "$existing_id" ] && library_id="$existing_id"
    ;;
  epic)
    library_id="${product_short}-EPIC"
    output_file="$output_dir_abs/${product_short}-设计文档.md"
    existing_id=$(read_frontmatter_id "$output_file")
    [ -n "$existing_id" ] && library_id="$existing_id"
    ;;
  feature)
    if [ -z "$capability_path" ]; then
      echo "ERROR: Feature 文档需要能力路径参数" >&2
      exit 2
    fi
    capability_slug="${capability_path//\//-}"
    feature_dir="$output_dir_abs/${capability_path}"
    mkdir -p "$feature_dir"
    output_file="$feature_dir/${product_short}-${capability_slug}-能力文档.md"
    existing_id=$(read_frontmatter_id "$output_file")
    if [ -n "$existing_id" ]; then
      library_id="$existing_id"
    else
      library_id=$(allocate_feature_id "$product_short")
    fi
    ;;
  structure-flow)
    design_subdir="结构与流程图"
    design_dir="$output_dir_abs/详细设计/$design_subdir"
    mkdir -p "$design_dir"
    output_file="$design_dir/${product_short}-结构与流程图.md"
    existing_id=$(read_frontmatter_id "$output_file")
    if [ -n "$existing_id" ]; then
      library_id="$existing_id"
    else
      library_id=$(allocate_design_id "$product_short" "FLOW" "$design_subdir")
    fi
    ;;
  prototype)
    design_subdir="原型"
    design_dir="$output_dir_abs/详细设计/$design_subdir"
    mkdir -p "$design_dir"
    output_file="$design_dir/${product_short}-原型交互说明.md"
    existing_id=$(read_frontmatter_id "$output_file")
    if [ -n "$existing_id" ]; then
      library_id="$existing_id"
    else
      library_id=$(allocate_design_id "$product_short" "PROTO" "$design_subdir")
    fi
    ;;
  interaction-contract)
    design_subdir="交互契约"
    design_dir="$output_dir_abs/详细设计/$design_subdir"
    mkdir -p "$design_dir"
    output_file="$design_dir/${product_short}-交互契约.md"
    existing_id=$(read_frontmatter_id "$output_file")
    if [ -n "$existing_id" ]; then
      library_id="$existing_id"
    else
      library_id=$(allocate_design_id "$product_short" "CONTRACT" "$design_subdir")
    fi
    ;;
  rules-summary)
    design_subdir="规则摘要"
    design_dir="$output_dir_abs/详细设计/$design_subdir"
    mkdir -p "$design_dir"
    output_file="$design_dir/${product_short}-规则摘要.md"
    existing_id=$(read_frontmatter_id "$output_file")
    if [ -n "$existing_id" ]; then
      library_id="$existing_id"
    else
      library_id=$(allocate_design_id "$product_short" "RULES" "$design_subdir")
    fi
    ;;
  sprint)
    design_subdir="迭代规划"
    design_dir="$output_dir_abs/详细设计/$design_subdir"
    mkdir -p "$design_dir"
    output_file="$design_dir/${product_short}-迭代规划.md"
    existing_id=$(read_frontmatter_id "$output_file")
    if [ -n "$existing_id" ]; then
      library_id="$existing_id"
    else
      library_id=$(allocate_design_id "$product_short" "SPRINT" "$design_subdir")
    fi
    ;;
esac

case "$output_file" in
  "$output_dir_abs"/*) ;;
  *) echo "ERROR: output file escaped output_dir: $output_file" >&2; exit 2 ;;
esac

# ---- 产品库 frontmatter 生成 ----
generate_frontmatter() {
  local cap="${1:-}"
  printf '%s\n' '---'
  printf 'id: "%s"\n' "$library_id"
  printf 'product: "%s"\n' "$product_full"
  printf 'type: "%s"\n' "$lib_type"
  if [ -n "$cap" ]; then
    printf 'capability: "%s"\n' "$cap"
  fi
  printf '%s\n' 'aliases:'
  if [ -n "$cap" ]; then
    printf '  - %s\n' "$cap"
  else
    printf '  - %s\n' "$product_full"
  fi
  printf '%s\n' 'tags:'
  printf '  - %s\n' "$product_short"
  printf '  - %s\n' "$lib_type"
  if [ -n "$cap" ]; then
    printf '  - %s\n' "$cap"
  fi
  printf '%s\n' '---'
}

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

  {
    generate_frontmatter
    printf '\n<!-- ID: %s -->\n\n' "$library_id"
    printf '%s\n' \
    "# $title" \
    '' \
    '```' \
    '需求卡片 ──────────────→ Epic ──────────────→ Feature' \
    '  ▲                        │                     │' \
    '  │ 5 个字段                │ 9 个字段             │ 5 个字段' \
    '  │                        │                     │' \
    '  ├ 需求基本信息             ├ 产品名称             ├ 需求背景' \
    '  ├ 现状描述                ├ 产品定位             ├ 能力名称' \
    '  ├ 痛点                   ├ 产品目标             ├ 能力描述' \
    '  ├ 问题本质还原             ├ 用户角色             ├ 能力目标' \
    '  └ 需求评估结果             ├ 核心场景             └ 用户角色' \
    '                           ├ 产品价值' \
    '                           ├ 范围边界' \
    '                           └ 建设思路' \
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
    "| 资源 | $resource_score | $resource_reason |"
  } > "$output_file"
}

render_epic() {
  local req_id requirement_bg product_name positioning product_goals
  local user_roles core_scenarios product_value in_scope out_of_scope
  local build_approach

  req_id=$(json_val "req_id")
  requirement_bg=$(json_val "requirement_bg")
  requirement_bg=$(normalize_requirement_bg "$requirement_bg" "epic" "$req_id")
  product_name=$(json_val "product_name")
  positioning=$(json_val "positioning")
  product_goals=$(json_val "product_goals")
  user_roles=$(json_val "user_roles")
  core_scenarios=$(json_val "core_scenarios")
  product_value=$(json_val "product_value")
  in_scope=$(json_val "in_scope")
  out_of_scope=$(json_val "out_of_scope")
  build_approach=$(json_val "build_approach")

  {
    generate_frontmatter
    printf '\n<!-- ID: %s -->\n\n' "$library_id"
    printf '%s\n' \
    "# $title" \
    '' \
    '```' \
    '需求卡片 ──────────────→ Epic ──────────────→ Feature' \
    '  │                        ▲                     │' \
    '  │ 5 个字段                │ 9 个字段             │ 5 个字段' \
    '  │                        │                     │' \
    '  ├ 需求基本信息             ├ 产品名称             ├ 需求背景' \
    '  ├ 现状描述                ├ 产品定位             ├ 能力名称' \
    '  ├ 痛点                   ├ 产品目标             ├ 能力描述' \
    '  ├ 问题本质还原             ├ 用户角色             ├ 能力目标' \
    '  └ 需求评估结果             ├ 核心场景             └ 用户角色' \
    '                           ├ 产品价值' \
    '                           ├ 范围边界' \
    '                           └ 建设思路' \
    '```' \
    '' \
    '## 需求背景' \
    '' \
    "本 Epic 派生自 [[${product_short}-需求卡片]]：$requirement_bg" \
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
    "$build_approach"
  } > "$output_file"
}

render_feature() {
  local req_id epic_id requirement_bg capability_name capability_description
  local capability_goal user_roles

  req_id=$(json_val "req_id")
  epic_id=$(json_val "epic_id")
  requirement_bg=$(json_val "requirement_bg")
  requirement_bg=$(normalize_requirement_bg "$requirement_bg" "feature" "$req_id")
  capability_name=$(json_val "capability_name")
  capability_description=$(json_val "capability_description")
  capability_goal=$(json_val "capability_goal")
  user_roles=$(json_val "user_roles")
  user_roles=$(normalize_user_roles "$user_roles" "$epic_id")

  {
    generate_frontmatter "$capability_path"
    printf '\n<!-- ID: %s -->\n\n' "$library_id"
    printf '%s\n' \
    "# $title" \
    '' \
    '```' \
    '需求卡片 ──────────────→ Epic ──────────────→ Feature' \
    '  │                        │                     ▲' \
    '  │ 5 个字段                │ 9 个字段             │ 5 个字段' \
    '  │                        │                     │' \
    '  ├ 需求基本信息             ├ 产品名称             ├ 需求背景' \
    '  ├ 现状描述                ├ 产品定位             ├ 能力名称' \
    '  ├ 痛点                   ├ 产品目标             ├ 能力描述' \
    '  ├ 问题本质还原             ├ 用户角色             ├ 能力目标' \
    '  └ 需求评估结果             ├ 核心场景             └ 用户角色' \
    '                           ├ 产品价值' \
    '                           ├ 范围边界' \
    '                           └ 建设思路' \
    '```' \
    '' \
    '> 业务价值、业务场景、业务流程、业务规则由《业务文档》按扁平 4 字段承载；技术可行性、资源投入已删除；优先级唯一来源为需求台账条目优先级。' \
    '' \
    '## 需求背景' \
    '' \
    "本 Feature 回应 [[${product_short}-需求卡片]] 中的需求：$requirement_bg" \
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
    "引用 [[${product_short}-设计文档]] 中的角色：$user_roles" \
    '' \
    '## 关联业务文档' \
    '' \
    "本 Feature 的业务价值、业务场景、业务流程、业务规则见 [[${product_short}-业务文档]]（业务场景与业务规则表按「所属能力」列定位本能力）。"
  } > "$output_file"
}

# ---- 详细设计文档 frontmatter ----
generate_design_frontmatter() {
  printf '%s\n' '---'
  printf 'id: "%s"\n' "$library_id"
  printf 'product: "%s"\n' "$product_full"
  printf 'type: "%s"\n' "$lib_type"
  printf '%s\n' 'aliases:'
  printf '  - %s %s\n' "$product_full" "$lib_type"
  printf '%s\n' 'tags:'
  printf '  - %s\n' "$product_short"
  printf '  - %s\n' "$lib_type"
  printf '%s\n' '---'
}

# ---- 详细设计渲染函数 ----
# 字段值为已格式化的 Markdown 片段（表格/代码块/列表字符串），脚本只拼 frontmatter + 章节标题 + 字段值。
render_flow() {
  local system_boundary page_mapping business_flow architecture_diagram
  system_boundary=$(json_val "system_boundary")
  page_mapping=$(json_val "page_mapping")
  business_flow=$(json_val "business_flow")
  architecture_diagram=$(json_val "architecture_diagram")
  {
    generate_design_frontmatter
    printf '\n<!-- ID: %s -->\n\n' "$library_id"
    printf '# %s\n\n' "$title"
    if [ -n "$architecture_diagram" ]; then
      printf '## 功能架构图\n\n%s\n\n' "$architecture_diagram"
    fi
    printf '## 系统边界\n\n%s\n\n' "$system_boundary"
    printf '## 页面映射表\n\n%s\n\n' "$page_mapping"
    printf '## 业务流程图\n\n> 纯用户操作与页面动线（Mermaid flowchart），不涉及底层技术实现\n\n%s\n' "$business_flow"
  } > "$output_file"
}

render_proto() {
  local proto_method page_list page_detail component_reuse ui_spec_ref design_decision
  proto_method=$(json_val "proto_method")
  page_list=$(json_val "page_list")
  page_detail=$(json_val "page_detail")
  component_reuse=$(json_val "component_reuse")
  ui_spec_ref=$(json_val "ui_spec_ref")
  design_decision=$(json_val "design_decision")
  {
    generate_design_frontmatter
    printf '\n<!-- ID: %s -->\n\n' "$library_id"
    printf '# %s\n\n' "$title"
    printf '## 原型生成方式\n\n%s\n\n' "$proto_method"
    printf '## 页面列表\n\n%s\n\n' "$page_list"
    printf '## 页面详情\n\n%s\n\n' "$page_detail"
    printf '## 组件复用\n\n%s\n\n' "$component_reuse"
    printf '## UI 规范引用\n\n%s\n\n' "$ui_spec_ref"
    printf '## 设计决策记录\n\n%s\n' "$design_decision"
  } > "$output_file"
}

render_contract() {
  local state_machine interaction_rules error_prompt api_convention
  state_machine=$(json_val "state_machine")
  interaction_rules=$(json_val "interaction_rules")
  error_prompt=$(json_val "error_prompt")
  api_convention=$(json_val "api_convention")
  {
    generate_design_frontmatter
    printf '\n<!-- ID: %s -->\n\n' "$library_id"
    printf '# %s\n\n' "$title"
    printf '## 状态机\n\n%s\n\n' "$state_machine"
    printf '## 交互规则表\n\n%s\n\n' "$interaction_rules"
    printf '## 错误提示\n\n%s\n\n' "$error_prompt"
    printf '## API 约定（如有）\n\n%s\n' "$api_convention"
  } > "$output_file"
}

render_rules() {
  local global_rules business_rules data_dict auth_control security_audit exception_fallback
  global_rules=$(json_val "global_rules")
  business_rules=$(json_val "business_rules")
  data_dict=$(json_val "data_dict")
  auth_control=$(json_val "auth_control")
  security_audit=$(json_val "security_audit")
  exception_fallback=$(json_val "exception_fallback")
  {
    generate_design_frontmatter
    printf '\n<!-- ID: %s -->\n\n' "$library_id"
    printf '# %s\n\n' "$title"
    printf '## 全局规则\n\n%s\n\n' "$global_rules"
    printf '## 业务规则\n\n%s\n\n' "$business_rules"
    printf '## 数据字典\n\n%s\n\n' "$data_dict"
    printf '## 权限控制\n\n%s\n\n' "$auth_control"
    printf '## 安全审计\n\n%s\n\n' "$security_audit"
    printf '## 异常兜底规则\n\n%s\n' "$exception_fallback"
  } > "$output_file"
}

render_sprint() {
  local project_overview sprint_list risk_annotation key_dependency
  project_overview=$(json_val "project_overview")
  sprint_list=$(json_val "sprint_list")
  risk_annotation=$(json_val "risk_annotation")
  key_dependency=$(json_val "key_dependency")
  {
    generate_design_frontmatter
    printf '\n<!-- ID: %s -->\n\n' "$library_id"
    printf '# %s\n\n' "$title"
    printf '## 项目总览\n\n%s\n\n' "$project_overview"
    printf '## Sprint 列表\n\n%s\n\n' "$sprint_list"
    printf '## 风险标注\n\n%s\n\n' "$risk_annotation"
    printf '## 关键依赖\n\n%s\n' "$key_dependency"
  } > "$output_file"
}

# ---- 路由 ----

case "$doc_type" in
  requirement-card) render_requirement_card ;;
  epic)             render_epic ;;
  feature)          render_feature ;;
  structure-flow)     render_flow ;;
  prototype)          render_proto ;;
  interaction-contract) render_contract ;;
  rules-summary)      render_rules ;;
  sprint)             render_sprint ;;
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
