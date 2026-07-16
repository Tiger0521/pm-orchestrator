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
#
# 用法：
#   bash init-project.sh <project_id> <project_name> <description> <project_type> <matched_product_id> <product_library_match> <template_dir> <target_dir>
#
#   project_id            : 匹配 ^[a-z0-9][a-z0-9-]{0,62}$
#   project_name          : 项目名称（可含任意字符，写入 JSON 时自动转义）
#   description           : 需求描述（可含任意字符/多行，写入 JSON 时自动转义）
#   project_type          : new | iteration | refactor
#   matched_product_id    : 关联的已有产品 ID（可为空）
#   product_library_match : 产品匹配度 high | medium | low | none（可为空）
#   template_dir          : .../skills/pm-orchestrator/project-template 的绝对路径
#   target_dir            : <workspace>/.claude/product-design-projects/<project-id> 的绝对路径
#
# 退出码：0 成功；2 参数非法；3 路径/模板问题。
#
set -euo pipefail

project_id="${1:?missing project_id}"
project_name="${2:?missing project_name}"
description="${3:?missing description}"
project_type="${4:?missing project_type}"
matched_product_id="${5:-}"  # can be empty
product_library_match="${6:-}"  # can be empty (high|medium|low|none)
template_dir="${7:?missing template_dir}"
target_dir="${8:?missing target_dir}"

# ---- 校验 ----

# project_id 格式（与 SKILL.md 一致）
if ! printf '%s' "$project_id" | grep -Eq '^[a-z0-9][a-z0-9-]{0,62}$'; then
  echo "ERROR: invalid project_id (need ^[a-z0-9][a-z0-9-]{0,62}\$): $project_id" >&2
  exit 2
fi

# project_type 枚举
case "$project_type" in
  new|iteration|refactor) ;;
  *) echo "ERROR: invalid project_type (new|iteration|refactor): $project_type" >&2; exit 2 ;;
esac

# product_library_match 枚举（可为空）
if [ -n "$product_library_match" ]; then
  case "$product_library_match" in
    high|medium|low|none) ;;
    *) echo "ERROR: invalid product_library_match (high|medium|low|none): $product_library_match" >&2; exit 2 ;;
  esac
fi

# matched_product_id 格式校验（非空时）
if [ -n "$matched_product_id" ]; then
  if ! printf '%s' "$matched_product_id" | grep -Eq '^[a-z0-9][a-z0-9-]{0,62}$'; then
    echo "ERROR: invalid matched_product_id (need ^[a-z0-9][a-z0-9-]{0,62}\$): $matched_product_id" >&2
    exit 2
  fi
  # 校验产品库中对应产品目录存在
  product_lib_dir="$HOME/.product-library/$matched_product_id"
  if [ ! -d "$product_lib_dir" ]; then
    echo "ERROR: product library directory not found: $product_lib_dir" >&2
    exit 3
  fi
fi

# 模板必须存在
if [ ! -d "$template_dir" ]; then
  echo "ERROR: template_dir not found: $template_dir" >&2
  exit 3
fi

# 目标不能已存在（避免覆盖既有项目）
if [ -e "$target_dir" ]; then
  echo "ERROR: target_dir already exists: $target_dir" >&2
  exit 3
fi

# 防止 target 在 template 内部（避免递归复制）
case "$target_dir/" in
  "$template_dir"/*) echo "ERROR: target_dir must not be inside template_dir" >&2; exit 3 ;;
esac

# ---- 复制骨架 ----

mkdir -p "$(dirname "$target_dir")"
cp -R "$template_dir" "$target_dir"

# 清空 background 目录下的示例/遗留文件，只保留 .gitkeep。
# project-template 不应携带特定项目的背景材料；此处作为双保险。
find "$target_dir/docs/background" -type f ! -name '.gitkeep' -delete 2>/dev/null || true

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
esc_desc=$(json_escape "$description")
esc_matched=$(json_escape "$matched_product_id")
esc_match=$(json_escape "$product_library_match")

# 用 printf %s 填充 JSON：format 串用单引号保持字面，值作为参数在双引号内安全展开。
# 不用参数扩展替换，规避 Git Bash 把 & 当匹配引用的行为。
printf '{
  "schemaVersion": 1,
  "projectId": "%s",
  "projectName": "%s",
  "projectType": "%s",
  "matchedProductId": "%s",
  "productLibraryMatch": "%s",
  "description": "%s",
  "status": "active",
  "currentPhase": "requirement-analysis",
  "phases": {
    "requirement-analysis": {
      "status": "in_progress",
      "startedAt": "%s",
      "completedAt": null,
      "lastUpdated": "%s"
    },
    "user-story-breakdown": {
      "status": "pending",
      "startedAt": null,
      "completedAt": null,
      "lastUpdated": null
    },
    "detailed-design": {
      "status": "pending",
      "startedAt": null,
      "completedAt": null,
      "lastUpdated": null
    }
  },
  "lastUpdated": "%s"
}
' "$project_id" "$esc_name" "$project_type" "$esc_matched" "$esc_match" "$esc_desc" "$ts" "$ts" "$ts" > "$target_dir/progress.json"

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
