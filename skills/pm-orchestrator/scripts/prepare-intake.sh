#!/usr/bin/env bash
#
# prepare-intake.sh - Create intake directory and minimal v2 progress.json.
#
# Creates:
#   <target_dir>/.pm-orchestrator-intake
#   <target_dir>/docs/background/.gitkeep
#   <target_dir>/progress.json  (v2 schema, status=intake)
#
# Usage:
#   bash prepare-intake.sh <project_id> <project_name> <product_short_name> <target_dir> \
#     <selected_product_library_id> <selected_product_library_path> <initial_description>
#
set -euo pipefail

project_id="${1:?missing project_id}"
project_name="${2:?missing project_name}"
product_short_name="${3:?missing product_short_name}"
target_dir="${4:?missing target_dir}"
library_id="${5:?missing library_id}"
library_path="${6:?missing library_path}"
initial_desc="${7:?missing initial_description}"

# ---- 校验 ----

if ! printf '%s' "$project_id" | grep -Eq '^[a-z0-9][a-z0-9-]{0,62}$'; then
  echo "ERROR: invalid project_id (need ^[a-z0-9][a-z0-9-]{0,62}\$): $project_id" >&2
  exit 2
fi

# 产品简称格式校验：2-5 个字，可包含中文、字母、数字
if [ -z "$product_short_name" ]; then
  echo "ERROR: product_short_name cannot be empty" >&2
  exit 2
fi

if [ -e "$target_dir" ] && [ ! -f "$target_dir/.pm-orchestrator-intake" ] && [ ! -f "$target_dir/progress.json" ]; then
  echo "ERROR: target_dir already exists and is not an intake directory: $target_dir" >&2
  exit 3
fi

if [ ! -d "$library_path" ]; then
  echo "ERROR: selected product library path not found: $library_path" >&2
  exit 3
fi

# ---- 产品库重名校验 ----

# 检查产品库中是否已存在同名产品目录
if [ -d "$library_path/$product_name" ]; then
  echo "WARNING: product with same name already exists in library: $product_name" >&2
  echo "DUPLICATE_PRODUCT_NAME" >&2
fi

# 检查是否存在以产品简称开头的目录
duplicate_count=$(find "$library_path" -maxdepth 1 -type d -name "${product_short_name}*" 2>/dev/null | wc -l || echo 0)
if [ "$duplicate_count" -gt 0 ]; then
  echo "WARNING: found $duplicate_count directories starting with product short name: $product_short_name" >&2
  echo "DUPLICATE_SHORT_NAME" >&2
fi

# ---- 创建目录 ----

mkdir -p "$target_dir/docs/background"
: > "$target_dir/docs/background/.gitkeep"
printf '%s\n' "$project_id" > "$target_dir/.pm-orchestrator-intake"

# ---- JSON 字符串转义 ----

json_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\r'/\\r}"
  s="${s//$'\t'/\\t}"
  printf '%s' "$s"
}

esc_name=$(json_escape "$project_name")
esc_short_name=$(json_escape "$product_short_name")
esc_desc=$(json_escape "$initial_desc")
esc_library_id=$(json_escape "$library_id")
esc_library_path=$(json_escape "$library_path")

# ---- 时间戳 ----

ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# ---- 写最小 v2 progress.json ----

# background 目录的规范化路径
bg_dir="${target_dir}/docs/background"

printf '{
  "schemaVersion": 2,
  "projectId": "%s",
  "projectName": "%s",
  "productShortName": "%s",
  "projectType": "pending",
  "description": "%s",
  "status": "intake",
  "workflow": {
    "state": "collect-background",
    "revision": 1,
    "updatedAt": "%s"
  },
  "intake": {
    "selectedProductLibraryId": "%s",
    "selectedProductLibraryPath": "%s",
    "initialDescription": "%s",
    "briefConfirmation": "pending",
    "background": {
      "status": "awaiting-user",
      "directory": "%s",
      "files": [],
      "pastedContent": [],
      "explicitlySkipped": false
    },
    "reuseAnalysis": {
      "status": "not-started",
      "result": null
    },
    "projectTypeConfirmation": "pending"
  },
  "lastUpdated": "%s"
}
' "$project_id" "$esc_name" "$esc_short_name" "$esc_desc" "$ts" "$esc_library_id" "$esc_library_path" "$esc_desc" "$bg_dir" "$ts" \
  > "$target_dir/progress.json"

# ---- 紧凑机器可读输出 ----

printf '{"status":"ok","projectPath":"%s","backgroundDirectory":"%s","workflowState":"collect-background"}\n' \
  "$target_dir" "$bg_dir"
