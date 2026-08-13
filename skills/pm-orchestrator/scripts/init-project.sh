#!/usr/bin/env bash
#
# init-project.sh - 从 project-template 创建项目骨架并生成记忆文件。
#
# 跨平台：通过 Claude Code 的 Bash 工具运行，Windows(Git Bash)/macOS/Linux 通用。
# 只用 bash + cp + find + printf + date，无 perl/awk/python/jq 等外部依赖。
#
# 安全性说明：
# - JSON 填充用 printf 的 %s + 变量参数，而非 bash 参数扩展替换。
#   原因：Git Bash 的参数扩展 replacement 会把 & 当作“匹配文本引用”，
#   含 & 的项目名/描述会被破坏（& 被替换成刚匹配到的占位符文本）。
#   printf %s 不解释 &，且变量在双引号内只展开一次（值里的反引号/$() 不会被
#   二次扫描执行），故 &/`/$()/换行/引号/% 均按字面安全写入。
# - 写入 JSON 的字符串先经 json_escape 转义 \、" 和控制字符；该函数的 replacement
#   不含 &，参数扩展安全。
# - 若 target_dir 已由 prepare-intake.sh 创建为 intake 目录，初始化时会保留
#   docs/background/ 下用户已放入的背景材料，并合并项目模板。
#
# 用法：
#   bash init-project.sh <project_id> <project_name> <product_short_name> <description> <project_type> <selected_product_library_id> <selected_product_library_path> <matched_product_id> <product_library_match> <template_dir> <target_dir> [initial_workflow_state] [source_product_id]
#
#   project_id            : 匹配 ^[a-z0-9][a-z0-9-]{0,62}$
#   project_name          : 项目名称（可含任意字符，写入 JSON 时自动转义）
#   product_short_name    : 产品简称（2-5 个字，可含中文、字母、数字）
#   description           : 需求描述（可含任意字符/多行，写入 JSON 时自动转义）
#   project_type          : new | iteration | refactor
#   selected_product_library_id   : 本轮确认的产品库目录名（可为中文，可为空）
#   selected_product_library_path : 本轮确认的产品库目录（可为空；位于 product-library/ 下）
#   matched_product_id    : 关联的已有产品全名（可为空）
#   product_library_match : 产品匹配度 high | medium | low | none（可为空）
#   template_dir          : .../skills/pm-orchestrator/project-template 的绝对路径
#   target_dir            : <workspace>/.claude/product-design-projects/<project-id> 的绝对路径
#                           可为 prepare-intake.sh 预先创建的 intake 目录
#   initial_workflow_state : requirement-analysis（默认）| user-story-breakdown | detailed-design
#   source_product_id      : 直启后续阶段时显式选择的只读产品库产品全名（可为空）
#
# 退出码：0 成功；2 参数非法；3 路径/模板问题。
#
set -euo pipefail

project_id="${1:?missing project_id}"
project_name="${2:?missing project_name}"
product_short_name="${3:?missing product_short_name}"
description="${4:?missing description}"
project_type="${5:?missing project_type}"
selected_product_library_id="${6:-}"  # can be empty
selected_product_library_path="${7:-}"  # can be empty
matched_product_id="${8:-}"  # can be empty
product_library_match="${9:-}"  # can be empty (high|medium|low|none)
template_dir="${10:?missing template_dir}"
target_dir="${11:?missing target_dir}"
initial_workflow_state="${12:-requirement-analysis}"
source_product_id="${13:-}"

# ---- 校验 ----

# project_id 格式（与 SKILL.md 一致）
if ! printf '%s' "$project_id" | grep -Eq '^[a-z0-9][a-z0-9-]{0,62}$'; then
  echo "ERROR: invalid project_id (need ^[a-z0-9][a-z0-9-]{0,62}\$): $project_id" >&2
  exit 2
fi

# 产品简称格式校验：2-5 个字，可包含中文、字母、数字
if [ -z "$product_short_name" ]; then
  echo "ERROR: product_short_name cannot be empty" >&2
  exit 2
fi

# project_type 枚举
case "$project_type" in
  new|iteration|refactor) ;;
  *) echo "ERROR: invalid project_type (new|iteration|refactor): $project_type" >&2; exit 2 ;;
esac
case "$initial_workflow_state" in
  requirement-analysis|user-story-breakdown|detailed-design) ;;
  *) echo "ERROR: invalid initial_workflow_state: $initial_workflow_state" >&2; exit 2 ;;
esac

# product_library_match 枚举（可为空）
if [ -n "$product_library_match" ]; then
  case "$product_library_match" in
    high|medium|low|none) ;;
    *) echo "ERROR: invalid product_library_match (high|medium|low|none): $product_library_match" >&2; exit 2 ;;
  esac
fi
# 产品库路径必须显式传入并与目录名一致。
if [ -n "$selected_product_library_path" ]; then
  if [ ! -d "$selected_product_library_path" ]; then
    echo "ERROR: selected product library path not found: $selected_product_library_path" >&2
    exit 3
  fi
  if [ "$(basename "$selected_product_library_path")" != "$selected_product_library_id" ]; then
    echo "ERROR: selected product library id must equal directory name: $selected_product_library_id" >&2
    exit 3
  fi

  # ---- 产品库重名校验 ----

  # 检查产品库中是否已存在同名产品目录
  if [ -d "$selected_product_library_path/$product_name" ]; then
    echo "WARNING: product with same name already exists in library: $product_name" >&2
    echo "DUPLICATE_PRODUCT_NAME" >&2
  fi

  # 检查是否存在以产品简称开头的目录
  duplicate_count=$(find "$selected_product_library_path" -maxdepth 1 -type d -name "${product_short_name}*" 2>/dev/null | wc -l || echo 0)
  if [ "$duplicate_count" -gt 0 ]; then
    echo "WARNING: found $duplicate_count directories starting with product short name: $product_short_name" >&2
    echo "DUPLICATE_SHORT_NAME" >&2
  fi
elif [ -n "$selected_product_library_id" ]; then
  echo "ERROR: selected_product_library_id requires an explicit selected_product_library_path" >&2
  exit 3
fi
# matched_product_id 使用产品全名，并校验对应目录。
if [ -n "$matched_product_id" ]; then
  case "$matched_product_id" in ''|'.'|'..'|*'/'*|*'\'*) echo "ERROR: invalid matched_product_id: $matched_product_id" >&2; exit 2 ;; esac
  # 校验已选产品库中对应产品目录存在
  if [ -z "$selected_product_library_path" ]; then
    echo "ERROR: matched_product_id requires selected_product_library_path" >&2
    exit 3
  fi
  product_lib_dir="$selected_product_library_path/$matched_product_id"
  if [ ! -d "$product_lib_dir" ]; then
    echo "ERROR: product library directory not found: $product_lib_dir" >&2
    exit 3
  fi
fi

if [ -n "$source_product_id" ]; then
  case "$source_product_id" in ''|'.'|'..'|*'/'*|*'\\'*) echo "ERROR: invalid source_product_id: $source_product_id" >&2; exit 2 ;; esac
  [ -d "$selected_product_library_path/$source_product_id" ] || { echo "ERROR: source product directory not found: $source_product_id" >&2; exit 3; }
fi

# 模板必须存在
if [ ! -d "$template_dir" ]; then
  echo "ERROR: template_dir not found: $template_dir" >&2
  exit 3
fi

# 目标通常不能已存在；唯一例外是 prepare-intake.sh 创建的 intake 目录。
intake_mode=0
if [ -e "$target_dir" ]; then
  if [ -f "$target_dir/.pm-orchestrator-intake" ]; then
    marker_id=$(tr -d '\r\n' < "$target_dir/.pm-orchestrator-intake" 2>/dev/null || true)
    if [ "$marker_id" != "$project_id" ]; then
      echo "ERROR: intake marker project_id mismatch: $target_dir" >&2
      exit 3
    fi
    intake_mode=1
  else
    echo "ERROR: target_dir already exists: $target_dir" >&2
    exit 3
  fi
fi

# 防止 target 在 template 内部（避免递归复制）
case "$target_dir/" in
  "$template_dir"/*) echo "ERROR: target_dir must not be inside template_dir" >&2; exit 3 ;;
esac

# ---- 复制骨架 ----

mkdir -p "$(dirname "$target_dir")"
if [ "$intake_mode" -eq 1 ]; then
  cp -R "$template_dir"/. "$target_dir"
  rm -f "$target_dir/.pm-orchestrator-intake"
  : > "$target_dir/docs/background/.gitkeep"
else
  cp -R "$template_dir" "$target_dir"
  # 清空 background 目录下的示例/遗留文件，只保留 .gitkeep。
  # project-template 不应携带特定项目的背景材料；此处作为双保险。
  find "$target_dir/docs/background" -type f ! -name '.gitkeep' -delete 2>/dev/null || true
fi

# ---- 生成记忆文件 ----

# 时间戳（UTC，跨平台一致）
ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# JSON 字符串转义。所有 replacement 均不含 &，参数扩展安全。
json_escape() {
  local s="$1"
  s="${s//\\/\\\\}"     # 反斜杠最先
  s="${s//\"/\\\"}"     # 双引号
  s="${s//$'\n'/\\n}"   # 换行 -> \n
  s="${s//$'\r'/\\r}"   # 回车 -> \r
  s="${s//$'\t'/\\t}"   # tab -> \t
  s="${s//$'\b'/\\b}"   # 退格 -> \b
  s="${s//$'\f'/\\f}"   # 换页 -> \f
  printf '%s' "$s"
}

esc_name=$(json_escape "$project_name")
esc_short_name=$(json_escape "$product_short_name")
esc_desc=$(json_escape "$description")
esc_library_id=$(json_escape "$selected_product_library_id")
esc_library_path=$(json_escape "$selected_product_library_path")
esc_matched=$(json_escape "$matched_product_id")
esc_match=$(json_escape "$product_library_match")
esc_source_product=$(json_escape "$source_product_id")
case "$initial_workflow_state" in
  requirement-analysis) req_status='in_progress'; req_time="\"$ts\""; story_status='pending'; story_time='null'; design_status='pending'; design_time='null' ;;
  user-story-breakdown) req_status='pending'; req_time='null'; story_status='in_progress'; story_time="\"$ts\""; design_status='pending'; design_time='null' ;;
  detailed-design) req_status='pending'; req_time='null'; story_status='pending'; story_time='null'; design_status='in_progress'; design_time="\"$ts\"" ;;
esac

# 如果是 intake 模式，备份 intake progress.json（保留 intake 审计数据）
if [ "$intake_mode" -eq 1 ] && [ -f "$target_dir/progress.json" ]; then
  cp "$target_dir/progress.json" "$target_dir/progress.intake.json"
fi

# 用 printf %s 填充 JSON：format 串用单引号保持字面，值作为参数在双引号内安全展开。
# 不用参数扩展替换，规避 Git Bash 把 & 当匹配引用的行为。
printf '{
  "schemaVersion": 2,
  "projectId": "%s",
  "projectName": "%s",
  "productShortName": "%s",
  "projectType": "%s",
  "selectedProductLibraryId": "%s",
  "selectedProductLibraryPath": "%s",
  "matchedProductId": "%s",
  "productLibraryMatch": "%s",
  "sourceProductId": "%s",
  "description": "%s",
  "status": "active",
  "workflow": {
    "state": "%s",
    "revision": 1,
    "updatedAt": "%s"
  },
  "phases": {
    "requirement-analysis": {
      "status": "%s",
      "startedAt": %s,
      "completedAt": null,
      "lastUpdated": %s
    },
    "user-story-breakdown": {
      "status": "%s",
      "startedAt": %s,
      "completedAt": null,
      "lastUpdated": %s
    },
    "detailed-design": {
      "status": "%s",
      "startedAt": %s,
      "completedAt": null,
      "lastUpdated": %s
    }
  },
  "lastUpdated": "%s"
}
' "$project_id" "$esc_name" "$esc_short_name" "$project_type" "$esc_library_id" "$esc_library_path" "$esc_matched" "$esc_match" "$esc_source_product" "$esc_desc" "$initial_workflow_state" "$ts" "$req_status" "$req_time" "$req_time" "$story_status" "$story_time" "$story_time" "$design_status" "$design_time" "$design_time" "$ts" > "$target_dir/progress.json"
printf '{
  "projectId": "%s",
  "lastUpdated": "%s",
  "nodes": [],
  "edges": []
}
' "$project_id" "$ts" > "$target_dir/refs.json"

printf '{
  "projectId": "%s",
  "lastUpdated": "%s",
  "facts": []
}
' "$project_id" "$ts" > "$target_dir/facts.json"

echo "OK: skeleton created at $target_dir"
