#!/usr/bin/env bash
#
# Validate pm-orchestrator phase artifacts and traceability metadata.
# Cross-platform target: Git Bash on Windows, macOS, and Linux.
#
set -u

project_root=""
project_path=""
phase=""

usage() {
  echo "Usage: bash validate-phase.sh --project-root <root> --project-path <project> --phase <phase>" >&2
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
    --phase|-phase)
      phase="${2:-}"
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
[ -n "$phase" ] || { usage; fail "missing --phase"; }

case "$phase" in
  requirement-analysis|user-story-breakdown|detailed-design) ;;
  *) fail "invalid phase: $phase" ;;
esac

canonical_dir() {
  [ -d "$1" ] || fail "$2 does not exist: $1"
  (cd -P "$1" 2>/dev/null && pwd) || fail "cannot resolve $2: $1"
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

json_string_value() {
  local file="$1"
  local key="$2"
  sed -n "s/.*\"$key\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" "$file" | head -n 1
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

fm_has_key() {
  local key="$1"
  local line
  while IFS= read -r line; do
    [[ "$line" =~ ^${key}[[:space:]]*: ]] && return 0
  done <<< "$FM_TEXT"
  return 1
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

parse_refs() {
  REF_IDS=()
  REF_RELS=()
  local in_refs=0
  local current_id=""
  local current_relation=""
  local line

  while IFS= read -r line; do
    if [[ "$line" =~ ^refs[[:space:]]*: ]]; then
      in_refs=1
      continue
    fi
    if [ "$in_refs" -eq 1 ] && [[ "$line" =~ ^[A-Za-z][A-Za-z0-9_-]*[[:space:]]*: ]]; then
      in_refs=0
    fi
    [ "$in_refs" -eq 1 ] || continue

    if [[ "$line" =~ ^[[:space:]]*-[[:space:]]+id[[:space:]]*:[[:space:]]*(.+)$ ]]; then
      if [ -n "$current_id" ]; then
        REF_IDS+=("$current_id")
        REF_RELS+=("$current_relation")
      fi
      current_id=$(remove_yaml_quotes "${BASH_REMATCH[1]}")
      current_relation=""
    elif [ -n "$current_id" ] && [[ "$line" =~ ^[[:space:]]+relation[[:space:]]*:[[:space:]]*(.+)$ ]]; then
      current_relation=$(remove_yaml_quotes "${BASH_REMATCH[1]}")
    fi
  done <<< "$FM_TEXT"

  if [ -n "$current_id" ]; then
    REF_IDS+=("$current_id")
    REF_RELS+=("$current_relation")
  fi
}

add_issue() {
  ISSUES+=("$1")
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

contains_value() {
  local needle="$1"
  shift
  local value
  for value in "$@"; do
    [ "$value" = "$needle" ] && return 0
  done
  return 1
}

count_value() {
  local needle="$1"
  shift
  local count=0
  local value
  for value in "$@"; do
    [ "$value" = "$needle" ] && count=$((count + 1))
  done
  printf '%s' "$count"
}

root=$(canonical_dir "$project_root" "Project root")
project=$(canonical_dir "$project_path" "Project path")

if [ "$(dirname "$project")" != "$root" ]; then
  fail "Project path must be a direct child of project root."
fi
if [ -L "$project_path" ]; then
  fail "Project path must not be a symbolic link."
fi

progress_path="$project/progress.json"
[ -f "$progress_path" ] || fail "Missing progress.json."
project_id=$(json_string_value "$progress_path" "projectId")
[[ "$project_id" =~ ^[a-z0-9][a-z0-9-]{0,62}$ ]] || fail "Invalid projectId in progress.json."
[ "$(basename "$project")" = "$project_id" ] || fail "Project directory name must equal progress.json projectId."

case "$phase" in
  requirement-analysis)
    expectations=$'requirement-analysis/req-*.md|requirement-card|req-\nrequirement-analysis/epic-*.md|epic|epic-\nrequirement-analysis/feature-*.md|feature|feature-'
    ;;
  user-story-breakdown)
    expectations=$'design/story-*.md|user-story|story-\ndesign/matrix-*.md|traceability-matrix|matrix-'
    ;;
  detailed-design)
    expectations=$'design/flow-*.md|structure-flow|flow-\ndesign/proto-*.md|prototype|proto-\ndesign/contract-*.md|interaction-contract|contract-\nexecution/rules-*.md|rules-summary|rules-\nexecution/sprint-*.md|sprint|sprint-'
    ;;
esac

ISSUES=()
DOC_IDS=()
DOC_PATHS=()
DOC_REF_IDS=()
DOC_REF_RELS=()
DOC_REF_DOCS=()
allowed_statuses=(draft review approved)
allowed_relations=(derived-from belongs-to implements contains references)

docs_path="$project/docs"
shopt -s nullglob
while IFS='|' read -r pattern expected_type expected_prefix; do
  [ -n "$pattern" ] || continue
  found=( "$docs_path"/$pattern )
  file_found=0
  for file in "${found[@]}"; do
    [ -f "$file" ] || continue
    file_found=1
    filename=$(basename "$file")
    basename_no_ext="${filename%.md}"

    if ! get_frontmatter "$file"; then
      add_issue "[frontmatter] $filename: missing block"
      continue
    fi

    missing=0
    for field in id type projectId title status refs; do
      if ! fm_has_key "$field"; then
        add_issue "[frontmatter] $filename: missing $field"
        missing=1
      fi
    done
    [ "$missing" -eq 0 ] || continue

    doc_id=$(fm_value id)
    doc_type=$(fm_value type)
    doc_project_id=$(fm_value projectId)
    status=$(fm_value status)
    title=$(fm_value title)
    parse_refs

    [[ "$doc_id" =~ ^${expected_prefix}[0-9]{3,}$ ]] || add_issue "[id] $filename: invalid id $doc_id"
    [ "$basename_no_ext" = "$doc_id" ] || add_issue "[id] $filename: filename must equal id"
    [ "$doc_type" = "$expected_type" ] || add_issue "[type] $filename: expected $expected_type, got $doc_type"
    [ "$doc_project_id" = "$project_id" ] || add_issue "[projectId] $filename: expected $project_id"
    contains_value "$status" "${allowed_statuses[@]}" || add_issue "[status] $filename: invalid status $status"
    [ -n "$(trim "$title")" ] || add_issue "[title] $filename: title is empty"
    if [ "$doc_type" != "requirement-card" ] && [ "${#REF_IDS[@]}" -eq 0 ]; then
      add_issue "[refs] $filename: at least one reference is required"
    fi

    for index in "${!REF_IDS[@]}"; do
      ref_id="${REF_IDS[$index]}"
      relation="${REF_RELS[$index]}"
      [ -n "$(trim "$ref_id")" ] || add_issue "[refs] $filename: reference id is empty"
      contains_value "$relation" "${allowed_relations[@]}" || add_issue "[refs] $filename: invalid relation $relation"
      DOC_REF_DOCS+=("$doc_id")
      DOC_REF_IDS+=("$ref_id")
      DOC_REF_RELS+=("$relation")
    done

    rel_path="${file#$project/}"
    DOC_IDS+=("$doc_id")
    DOC_PATHS+=("$rel_path")
  done

  [ "$file_found" -eq 1 ] || add_issue "[missing] $pattern"
done <<< "$expectations"
shopt -u nullglob

for doc_id in "${DOC_IDS[@]}"; do
  if [ "$(count_value "$doc_id" "${DOC_IDS[@]}")" -gt 1 ]; then
    add_issue "[duplicate] document id $doc_id"
  fi
done

if [ "$phase" = "requirement-analysis" ]; then
  shopt -s nullglob
  for legacy_pattern in "strategic/req-*.md" "strategic/epic-*.md" "requirement/feature-*.md"; do
    legacy_found=( "$docs_path"/$legacy_pattern )
    for file in "${legacy_found[@]}"; do
      [ -f "$file" ] && { add_issue "[directory] legacy artifact found: $legacy_pattern"; break; }
    done
  done
  shopt -u nullglob
fi

refs_path="$project/refs.json"
if [ ! -f "$refs_path" ]; then
  add_issue "[missing] refs.json"
else
  refs_json=$(tr -d '\r\n' < "$refs_path")
  nodes_json=$(json_array_between "nodes" "edges" "$refs_json")
  edges_json=$(json_array_between "edges" "" "$refs_json")
  NODE_IDS=()
  NODE_PATHS=()
  EDGE_FROM=()
  EDGE_TO=()
  EDGE_REL=()

  while IFS= read -r object; do
    [ -n "$object" ] || continue
    NODE_IDS+=("$(json_field_from_object "$object" "id")")
    NODE_PATHS+=("$(json_field_from_object "$object" "path" | sed 's#\\#/#g')")
  done < <(printf '%s\n' "$nodes_json" | split_json_objects)

  while IFS= read -r object; do
    [ -n "$object" ] || continue
    EDGE_FROM+=("$(json_field_from_object "$object" "from")")
    EDGE_TO+=("$(json_field_from_object "$object" "to")")
    EDGE_REL+=("$(json_field_from_object "$object" "relation")")
  done < <(printf '%s\n' "$edges_json" | split_json_objects)

  for node_id in "${NODE_IDS[@]}"; do
    [ -n "$node_id" ] && [ "$(count_value "$node_id" "${NODE_IDS[@]}")" -gt 1 ] && add_issue "[refs.json] duplicate node id $node_id"
  done
  for node_path in "${NODE_PATHS[@]}"; do
    [ -n "$node_path" ] && [ "$(count_value "$node_path" "${NODE_PATHS[@]}")" -gt 1 ] && add_issue "[refs.json] duplicate node path $node_path"
  done

  for index in "${!DOC_IDS[@]}"; do
    doc_id="${DOC_IDS[$index]}"
    doc_path="${DOC_PATHS[$index]}"
    match_count=$(count_value "$doc_id" "${NODE_IDS[@]}")
    if [ "$match_count" -ne 1 ]; then
      add_issue "[refs.json] $doc_id: expected exactly one node"
      continue
    fi
    node_path=""
    for node_index in "${!NODE_IDS[@]}"; do
      if [ "${NODE_IDS[$node_index]}" = "$doc_id" ]; then
        node_path="${NODE_PATHS[$node_index]}"
        break
      fi
    done
    [ "$node_path" = "$doc_path" ] || add_issue "[refs.json] $doc_id: node path mismatch"
  done

  for index in "${!DOC_REF_DOCS[@]}"; do
    doc_id="${DOC_REF_DOCS[$index]}"
    ref_id="${DOC_REF_IDS[$index]}"
    relation="${DOC_REF_RELS[$index]}"
    contains_value "$ref_id" "${NODE_IDS[@]}" || add_issue "[refs.json] $doc_id: missing target node $ref_id"
    edge_exists=0
    for edge_index in "${!EDGE_FROM[@]}"; do
      if [ "${EDGE_FROM[$edge_index]}" = "$doc_id" ] && [ "${EDGE_TO[$edge_index]}" = "$ref_id" ] && [ "${EDGE_REL[$edge_index]}" = "$relation" ]; then
        edge_exists=1
        break
      fi
    done
    [ "$edge_exists" -eq 1 ] || add_issue "[refs.json] $doc_id: missing edge to $ref_id ($relation)"
  done
fi

# ---- iteration/refactor: 校验已有产物未被修改 ----
project_type=$(json_string_value "$progress_path" "projectType")
selected_product_library_path=$(json_string_value "$progress_path" "selectedProductLibraryPath")
selected_product_library_id=$(json_string_value "$progress_path" "selectedProductLibraryId")
matched_product_id=$(json_string_value "$progress_path" "matchedProductId")

if [ -n "$matched_product_id" ] && [ "$project_type" != "new" ]; then
  if [ -z "$selected_product_library_path" ] && [ -n "$selected_product_library_id" ]; then
    selected_product_library_path="$HOME/.product-library/$selected_product_library_id"
  fi
  if [ -z "$selected_product_library_path" ]; then
    add_issue "[progress.json] matchedProductId requires selectedProductLibraryPath or selectedProductLibraryId"
    product_lib=""
  else
    product_lib="$selected_product_library_path/$matched_product_id"
  fi

  if [ -n "$product_lib" ] && [ ! -d "$product_lib" ]; then
    add_issue "[progress.json] matched product not found in selected product library: $product_lib"
  fi

  if [ -d "$product_lib" ]; then
    check_pairs=""
    if [ "$project_type" = "iteration" ]; then
      check_pairs=$'epics|epic-\nfeatures|feature-'
    elif [ "$project_type" = "refactor" ]; then
      check_pairs=$'epics|epic-\nfeatures|feature-\nuser-stories|story-'
    fi

    while IFS='|' read -r subdir prefix; do
      [ -n "$subdir" ] || continue

      if [ "$subdir" = "user-stories" ]; then
        lib_dir="$product_lib/requirement-breakdown/user-stories"
        proj_dir="$docs_path/design"
      else
        lib_dir="$product_lib/requirement-analysis/$subdir"
        proj_dir="$docs_path/requirement-analysis"
      fi

      [ -d "$lib_dir" ] || continue

      shopt -s nullglob
      for lib_file in "$lib_dir"/${prefix}*.md; do
        [ -f "$lib_file" ] || continue
        filename=$(basename "$lib_file")
        proj_file="$proj_dir/$filename"

        if [ -f "$proj_file" ]; then
          if ! diff -q "$lib_file" "$proj_file" >/dev/null 2>&1; then
            add_issue "[$project_type] $filename: modified from product library version"
          fi
        else
          add_issue "[$project_type] $filename: exists in product library but missing from project"
        fi
      done
      shopt -u nullglob
    done <<< "$check_pairs"
  fi
fi

if [ "${#ISSUES[@]}" -gt 0 ]; then
  echo "Validation failed with ${#ISSUES[@]} issue(s)."
  for issue in "${ISSUES[@]}"; do
    echo "  - $issue"
  done
  exit 1
fi

echo "Validation passed for ${#DOC_IDS[@]} document(s)."
exit 0
