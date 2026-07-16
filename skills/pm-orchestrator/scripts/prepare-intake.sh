#!/usr/bin/env bash
#
# prepare-intake.sh - Create the fixed background-material intake directory before projectType is known.
#
# Usage:
#   bash prepare-intake.sh <project_id> <target_dir>
#
# Creates:
#   <target_dir>/.pm-orchestrator-intake
#   <target_dir>/docs/background/.gitkeep
#
set -euo pipefail

project_id="${1:?missing project_id}"
target_dir="${2:?missing target_dir}"

if ! printf '%s' "$project_id" | grep -Eq '^[a-z0-9][a-z0-9-]{0,62}$'; then
  echo "ERROR: invalid project_id (need ^[a-z0-9][a-z0-9-]{0,62}\$): $project_id" >&2
  exit 2
fi

if [ -e "$target_dir" ] && [ ! -f "$target_dir/.pm-orchestrator-intake" ]; then
  echo "ERROR: target_dir already exists and is not an intake directory: $target_dir" >&2
  exit 3
fi

mkdir -p "$target_dir/docs/background"
: > "$target_dir/docs/background/.gitkeep"
printf '%s\n' "$project_id" > "$target_dir/.pm-orchestrator-intake"

echo "OK: background intake directory ready at $target_dir/docs/background"