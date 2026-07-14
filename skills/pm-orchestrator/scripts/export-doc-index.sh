#!/usr/bin/env bash
#
# Export a formal document index or a Mermaid traceability graph.
# Cross-platform target: Git Bash on Windows, macOS, and Linux.
#
set -u

project_root=""
project_path=""
format="index"
output_path=""

usage() {
  echo "Usage: bash export-doc-index.sh --project-root <root> --project-path <project> [--format index|graph] [--output-path <file>]" >&2
}

fail() {
  echo "ERROR: $1" >&2
  exit 1
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --project-root|-projectRoot)
      project_root="${2:-}"
      shift 2
      ;;
    --project-path|-projectPath)
      project_path="${2:-}"
      shift 2
      ;;
    --format|-format)
      format="${2:-}"
      shift 2
      ;;
    --output-path|-outputPath)
      output_path="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage
      fail "unknown argument: $1"
      ;;
  esac
done

[ -n "$project_root" ] || { usage; fail "missing --project-root"; }
[ -n "$project_path" ] || { usage; fail "missing --project-path"; }
case "$format" in
  index|graph) ;;
  *) fail "invalid format: $format" ;;
esac

canonical_dir() {
  [ -d "$1" ] || fail "$2 does not exist: $1"
  (cd -P "$1" 2>/dev/null && pwd) || fail "cannot resolve $2: $1"
}

canonical_parent_for_file() {
  local target="$1"
  local parent
  parent=$(dirname "$target")
  mkdir -p "$parent" || fail "cannot create output directory: $parent"
  parent=$(cd -P "$parent" 2>/dev/null && pwd) || fail "cannot resolve output directory: $parent"
  printf '%s/%s' "$parent" "$(basename "$target")"
}

trim() {
  local value="$1"
  value="${value#"${value%%[!$' \t\r\n']*}"}"
  value="${value%"${value##*[!$' \t\r\n']}"}"
  printf '%s' "$value"
}

remove_yaml_quotes() {
  local value
  value=$(trim "$1")
  value="${value%\"}"
  value="${value#\"}"
  value="${value%\'}"
  value="${value#\'}"
  printf '%s' "$value"
}

get_frontmatter() {
  local file="$1"
  local line
  local started=0
  local found_end=0
  FM_TEXT=""

  while IFS= read -r line || [ -n "$line" ]; do
    line="${line#$'\xef\xbb\xbf'}"
    line="${line%$'\r'}"
    if [ "$started" -eq 0 ]; then
      [ "$line" = "---" ] || return 1
      started=1
      continue
    fi
    if [ "$line" = "---" ]; then
      found_end=1
      break
    fi
    FM_TEXT="${FM_TEXT}${line}"$'\n'
  done < "$file"

  [ "$found_end" -eq 1 ]
}

fm_value() {
  local key="$1"
  local line
  while IFS= read -r line; do
    if [[ "$line" =~ ^${key}[[:space:]]*:[[:space:]]*(.*)$ ]]; then
      remove_yaml_quotes "${BASH_REMATCH[1]}"
      return 0
    fi
  done <<< "$FM_TEXT"
  printf ''
}

split_json_objects() {
  sed 's/}[[:space:]]*,[[:space:]]*{/}\
{/g'
}

json_array_between() {
  local key="$1"
  local next_key="$2"
  local json="$3"
  if [ -n "$next_key" ]; then
    printf '%s' "$json" | sed -n "s/.*\"$key\"[[:space:]]*:[[:space:]]*\[\(.*\)\][[:space:]]*,[[:space:]]*\"$next_key\".*/\1/p"
  else
    printf '%s' "$json" | sed -n "s/.*\"$key\"[[:space:]]*:[[:space:]]*\[\(.*\)\].*/\1/p"
  fi
}

json_field_from_object() {
  local object="$1"
  local key="$2"
  printf '%s\n' "$object" | sed -n "s/.*\"$key\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p"
}

safe_mermaid_id() {
  printf '%s' "$1" | sed 's/[^A-Za-z0-9_]/_/g'
}

escape_md_cell() {
  printf '%s' "$1" | sed 's/|/\\|/g'
}

root=$(canonical_dir "$project_root" "Project root")
project=$(canonical_dir "$project_path" "Project path")

if [ "$(dirname "$project")" != "$root" ]; then
  fail "Project path must be a direct child of project root."
fi
if [ -L "$project_path" ]; then
  fail "Project path must not be a symbolic link."
fi

export_graph() {
  local refs_path="$project/refs.json"
  [ -f "$refs_path" ] || fail "Missing refs.json."

  local refs_json nodes_json edges_json object id title from to relation safe_id safe_from safe_to
  refs_json=$(tr -d '\r\n' < "$refs_path")
  nodes_json=$(json_array_between "nodes" "edges" "$refs_json")
  edges_json=$(json_array_between "edges" "" "$refs_json")

  echo "graph TD"
  while IFS= read -r object; do
    [ -n "$object" ] || continue
    id=$(json_field_from_object "$object" "id")
    title=$(json_field_from_object "$object" "title" | sed 's/"/'\''/g')
    safe_id=$(safe_mermaid_id "$id")
    echo "  ${safe_id}[\"${id}: ${title}\"]"
  done < <(printf '%s\n' "$nodes_json" | split_json_objects)

  while IFS= read -r object; do
    [ -n "$object" ] || continue
    from=$(json_field_from_object "$object" "from")
    to=$(json_field_from_object "$object" "to")
    relation=$(json_field_from_object "$object" "relation" | sed 's/"/'\''/g')
    safe_from=$(safe_mermaid_id "$from")
    safe_to=$(safe_mermaid_id "$to")
    echo "  ${safe_from} -->|${relation}| ${safe_to}"
  done < <(printf '%s\n' "$edges_json" | split_json_objects)
}

export_index() {
  local tmp
  tmp=$(mktemp) || fail "cannot create temp file"
  trap 'rm -f "$tmp"' RETURN

  local layer layer_order doc rel_path id type title status
  for layer in requirement-analysis design execution; do
    case "$layer" in
      requirement-analysis) layer_order=1 ;;
      design) layer_order=2 ;;
      execution) layer_order=3 ;;
    esac
    [ -d "$project/docs/$layer" ] || continue
    while IFS= read -r -d '' doc; do
      if get_frontmatter "$doc"; then
        rel_path="${doc#$project/}"
        id=$(fm_value id)
        type=$(fm_value type)
        title=$(fm_value title)
        status=$(fm_value status)
        printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$layer_order" "$layer" "$id" "$type" "$title" "$status" "$rel_path" >> "$tmp"
      fi
    done < <(find "$project/docs/$layer" -type f -name '*.md' -print0)
  done

  echo "# Document Index"
  echo
  echo "Project: $project"
  echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
  echo "Documents: $(wc -l < "$tmp" | tr -d ' ')"
  echo
  echo "| Layer | ID | Type | Title | Status | Path |"
  echo "|---|---|---|---|---|---|"
  sort -t "$(printf '\t')" -k1,1n -k3,3 "$tmp" | while IFS=$'\t' read -r _ layer id type title status rel_path; do
    echo "| $(escape_md_cell "$layer") | $(escape_md_cell "$id") | $(escape_md_cell "$type") | $(escape_md_cell "$title") | $(escape_md_cell "$status") | $(escape_md_cell "$rel_path") |"
  done
}

if [ "$format" = "graph" ]; then
  output=$(export_graph)
else
  output=$(export_index)
fi

if [ -n "$output_path" ]; then
  target=$(canonical_parent_for_file "$output_path")
  case "$target" in
    "$project"/*) ;;
    *) fail "Output path must be inside the project directory." ;;
  esac
  printf '%s\n' "$output" > "$target"
  echo "Exported: $target"
else
  printf '%s\n' "$output"
fi
