#!/usr/bin/env bash
#
# transition-project-state.sh - 确定性状态迁移脚本。
#
# 校验当前状态与目标状态是否存在合法边，原子更新 workflow.state、revision 和时间戳。
# 不做任何业务语义推断。
#
# 用法：
#   bash transition-project-state.sh <progress.json> <from_state> <to_state> [event]
#
#   progress.json : 项目 progress.json 的绝对路径
#   from_state    : 当前预期状态（用于防并发：如果不匹配则拒绝）
#   to_state      : 目标状态
#   event         : 触发迁移的事件名（可选，用于日志）
#
# 退出码：0 成功；2 参数非法；3 状态非法/迁移边不存在；4 文件问题。
#
set -euo pipefail

progress_path="${1:?missing progress.json}"
from_state="${2:?missing from_state}"
to_state="${3:?missing to_state}"
event="${4:-}"

[ -f "$progress_path" ] || { echo "ERROR: progress.json not found: $progress_path" >&2; exit 4; }

# ---- 读取当前状态 ----

# 读取 workflow.state（v2 schema）
current_state=$(sed -n 's/.*"state"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$progress_path" | head -n 1)

# v1 兼容：如果没有 workflow.state，检查 currentPhase
if [ -z "$current_state" ]; then
  current_phase=$(sed -n 's/.*"currentPhase"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$progress_path" | head -n 1)
  if [ -n "$current_phase" ]; then
    echo "ERROR: progress.json is v1 schema (currentPhase=$current_phase). Migration required before state transition." >&2
    exit 3
  fi
  echo "ERROR: cannot read workflow.state from progress.json" >&2
  exit 4
fi

# 防并发：当前状态必须与 from_state 匹配
if [ "$current_state" != "$from_state" ]; then
  echo "ERROR: state mismatch. Expected $from_state, got $current_state" >&2
  exit 3
fi

# ---- 校验合法迁移边 ----

# 状态机合法边（from -> to）
valid_edge() {
  local from="$1"
  local to="$2"
  case "$from->$to" in
    # Intake 状态机
    "select-library->collect-brief") return 0 ;;
    "collect-brief->collect-background") return 0 ;;
    "collect-background->prepare-intake-summary") return 0 ;;
    "prepare-intake-summary->confirm-intake-summary") return 0 ;;
    "prepare-intake-summary->prepare-intake-summary") return 0 ;;  # 用户修正，回环
    "confirm-intake-summary->analyze-reuse") return 0 ;;
    "confirm-intake-summary->prepare-intake-summary") return 0 ;;  # 用户修正，回环
    "analyze-reuse->confirm-project-type") return 0 ;;
    "confirm-project-type->initialize-project") return 0 ;;
    "initialize-project->requirement-analysis") return 0 ;;
    # 阶段转换
    "requirement-analysis->user-story-breakdown") return 0 ;;
    "user-story-breakdown->detailed-design") return 0 ;;
    "detailed-design->completed") return 0 ;;
    # 回退（!back）
    "user-story-breakdown->requirement-analysis") return 0 ;;
    "detailed-design->user-story-breakdown") return 0 ;;
    *) return 1 ;;
  esac
}

if ! valid_edge "$from_state" "$to_state"; then
  echo "ERROR: invalid state transition: $from_state -> $to_state" >&2
  exit 3
fi

# 同状态不算迁移（prepare-intake-summary 回环保留 revision 不变）
if [ "$from_state" = "$to_state" ]; then
  echo "OK: state unchanged ($to_state), event=$event"
  exit 0
fi

# ---- 原子更新 ----

# 读取当前 revision（数字）
current_revision=$(sed -n 's/.*"revision"[[:space:]]*:[[:space:]]*\([0-9]*\).*/\1/p' "$progress_path" | head -n 1)
new_revision=$((current_revision + 1))

# 时间戳（UTC）
new_ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# 写入临时文件，然后原子替换
tmp_file="${progress_path}.tmp.$$"
trap 'rm -f "$tmp_file"' EXIT

# 使用 sed 更新三个字段
sed \
  -e "s/\"state\"[[:space:]]*:[[:space:]]*\"[^\"]*\"/\"state\": \"$to_state\"/" \
  -e "s/\"revision\"[[:space:]]*:[[:space:]]*[0-9]*/\"revision\": $new_revision/" \
  -e "s/\"updatedAt\"[[:space:]]*:[[:space:]]*\"[^\"]*\"/\"updatedAt\": \"$new_ts\"/" \
  "$progress_path" > "$tmp_file"

# 校验临时文件非空
[ -s "$tmp_file" ] || { echo "ERROR: temp file is empty after sed" >&2; exit 4; }

# 原子替换
mv "$tmp_file" "$progress_path"

# 紧凑机器可读输出
printf '{"status":"ok","from":"%s","to":"%s","revision":%d,"event":"%s"}\n' \
  "$from_state" "$to_state" "$new_revision" "$event"
