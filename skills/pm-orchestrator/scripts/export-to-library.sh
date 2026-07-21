#!/usr/bin/env bash
#
# export-to-library.sh
#
# Export completed project artifacts to a selected product library.
#
# Cross-platform: Windows Git Bash / macOS / Linux.
# Dependencies: bash + standard Unix tools only (cp, find, printf, date,
# grep, sed, mkdir, dirname, basename, wc, tr). No jq / perl / python.
#
# Usage:
#   bash export-to-library.sh <project_dir> <product_library_dir> <skill_path>
#
# Arguments:
#   project_dir         Project directory, e.g. .claude/product-design-projects/my-project
#   product_library_dir Target product directory, e.g. ~/.product-library/network-resource-center-product-library/my-product
#   skill_path          Plugin skill path (reserved for future use; currently unused)
#
# Exit codes:
#   0  Success
#   1  Invalid arguments or missing required input
#
# NOTE: Uses `set -u` (not `set -e`) so that legitimate "no match" results from
# grep (e.g. a missing key in progress.json / _product.md) do not abort the run.
# Critical operations (cp, mkdir) are checked explicitly.

set -u

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
note()  { printf '  [NOTE] %s\n'  "$*"; }
warn()  { printf '  [WARN] %s\n'  "$*"; }
error() { printf '  [ERROR] %s\n' "$*" >&2; }

print_usage() {
    cat <<'EOF'
Usage: bash export-to-library.sh <project_dir> <product_library_dir> <skill_path>

Arguments:
  project_dir         Project directory (e.g. .claude/product-design-projects/my-project)
  product_library_dir Target product directory (e.g. ~/.product-library/network-resource-center-product-library/my-product)
  skill_path          Plugin skill path (reserved for future use, currently unused)

Exit codes:
  0  Success
  1  Invalid arguments or missing required input
EOF
}

# Copy a single file into a destination directory, reporting status.
# Returns non-zero on failure so callers can decide to abort.
#   $1 = source file
#   $2 = destination directory
copy_file() {
    local src="$1"
    local ddir="$2"
    if cp -- "$src" "$ddir/"; then
        printf '  copied: %s -> %s/%s\n' "$src" "$ddir" "$(basename -- "$src")"
        return 0
    fi
    error "failed to copy $src into $ddir"
    return 1
}

# Extract a quoted JSON string value for a given key using grep + sed (no jq).
#   $1 = json file
#   $2 = key name (without quotes)
# Prints the value (without surrounding quotes) to stdout; empty if not found.
# Robust against values that contain ':' (sed backtracks to the key's colon).
json_string_value() {
    local file="$1"
    local key="$2"
    local value
    value=$(grep -o "\"${key}\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" "$file" \
            | head -n1 \
            | sed 's/.*:[[:space:]]*"//; s/"[[:space:]]*$//')
    printf '%s' "$value"
}

# Read the raw value (everything after "key:") of a top-level YAML key from a
# markdown frontmatter file. Preserves the exact on-disk formatting (including
# any surrounding quotes / array brackets). Strips a trailing CR for CRLF files.
#   $1 = file
#   $2 = key name
# Prints the raw value to stdout; empty if the key is absent.
frontmatter_raw_value() {
    local file="$1"
    local key="$2"
    local value
    # Strip "key:" plus any surrounding whitespace so preserved values do not
    # end up with a stray leading space (e.g. "createdAt:  \"...\"" double-space).
    value=$(grep -E "^${key}[[:space:]]*:" "$file" | head -n1 | sed "s/^${key}[[:space:]]*:[[:space:]]*//" | tr -d '\r')
    printf '%s' "$value"
}

canonical_dir() {
    local dir="$1"
    local label="$2"
    [[ -d "$dir" ]] || { error "$label does not exist or is not a directory: $dir"; return 1; }
    (cd -P "$dir" 2>/dev/null && pwd) || { error "cannot resolve $label: $dir"; return 1; }
}

# ---------------------------------------------------------------------------
# Argument parsing & validation
# ---------------------------------------------------------------------------
if [[ "$#" -ne 3 ]]; then
    error "expected exactly 3 arguments, got $#. See usage below."
    print_usage >&2
    exit 1
fi

project_dir="$1"
product_library_dir="$2"
skill_path="$3"   # reserved for future use; intentionally unused beyond assignment

# project_dir must exist and be a directory.
if [[ ! -d "$project_dir" ]]; then
    error "project_dir does not exist or is not a directory: $project_dir"
    exit 1
fi

# project_dir must contain docs/requirement-analysis/ with at least one .md file.
ra_src="$project_dir/docs/requirement-analysis"
if [[ ! -d "$ra_src" ]]; then
    error "requirement-analysis directory not found under project: $ra_src"
    exit 1
fi

# Count .md files anywhere under docs/requirement-analysis/ (files live in
# subdirectories: requirement-cards/, epics/, features/). Over-counting from
# unusual filenames is harmless here: we only need to distinguish 0 from >=1.
ra_md_count=$(find "$ra_src" -type f -name '*.md' | wc -l | tr -d '[:space:]')
if [[ -z "$ra_md_count" || "$ra_md_count" -eq 0 ]]; then
    error "no .md files found under $ra_src"
    exit 1
fi

# product_library_dir must be ~/.product-library/<product-library-id>/<product-id>.
if [[ -n "${HOME:-}" ]]; then
    library_collection_root="$HOME/.product-library"
elif [[ -n "${USERPROFILE:-}" ]]; then
    library_collection_root="$USERPROFILE/.product-library"
else
    error "cannot determine home directory (HOME and USERPROFILE both empty)"
    exit 1
fi

parent_dir=$(dirname -- "$product_library_dir")
product_id=$(basename -- "$product_library_dir")
if ! printf '%s' "$product_id" | grep -Eq '^[a-z0-9][a-z0-9-]{0,62}$'; then
    error "invalid product id in product_library_dir: $product_id"
    exit 1
fi

if [[ ! -d "$parent_dir" ]]; then
    error "parent directory of product_library_dir does not exist: $parent_dir"
    error "please create the selected product library first (e.g. ~/.product-library/network-resource-center-product-library)."
    exit 1
fi

product_library_id=$(basename -- "$parent_dir")
if ! printf '%s' "$product_library_id" | grep -Eq '^[a-z0-9][a-z0-9-]{0,62}$'; then
    error "invalid product library id in product_library_dir: $product_library_id"
    exit 1
fi

collection_root_abs=$(canonical_dir "$library_collection_root" "product library collection root") || exit 1
parent_dir_abs=$(canonical_dir "$parent_dir" "selected product library") || exit 1
grandparent_dir=$(dirname -- "$parent_dir")
grandparent_dir_abs=$(canonical_dir "$grandparent_dir" "product library collection parent") || exit 1
if [[ "$grandparent_dir_abs" != "$collection_root_abs" ]]; then
    error "product_library_dir must be under ~/.product-library/<product-library-id>/<product-id>: $product_library_dir"
    exit 1
fi

if [[ -L "$product_library_dir" ]]; then
    error "product_library_dir must not be a symbolic link: $product_library_dir"
    exit 1
fi

# Warn (but allow) overwrite inside the validated product library root.
if [[ -d "$product_library_dir" ]]; then
    warn "product_library_dir already exists; existing product files will be overwritten: $product_library_dir"
fi

mkdir -p -- "$product_library_dir" || { error "cannot create product_library_dir: $product_library_dir"; exit 1; }

# UTC timestamp (ISO-8601, cross-platform consistent).
now=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# Counters for the summary.
ra_copied=0
story_copied=0
matrix_copied=0

# ---------------------------------------------------------------------------
# 1) Copy docs/requirement-analysis/**.md -> requirement-analysis/
#    Preserves subdirectory structure:
#      requirement-cards/ -> requirement-analysis/requirement-cards/
#      epics/             -> requirement-analysis/epics/
#      features/          -> requirement-analysis/features/
# ---------------------------------------------------------------------------
ra_dst="$product_library_dir/requirement-analysis"
mkdir -p -- "$ra_dst" || { error "cannot create $ra_dst"; exit 1; }

while IFS= read -r -d '' f; do
    # Relative path under ra_src (quoted pattern => literal prefix removal,
    # safe even if the path contains glob characters).
    rel="${f#"$ra_src"/}"
    dst_subdir="$ra_dst/$(dirname -- "$rel")"
    mkdir -p -- "$dst_subdir" || { error "cannot create $dst_subdir"; exit 1; }
    copy_file "$f" "$dst_subdir" || exit 1
    ra_copied=$((ra_copied + 1))
done < <(find "$ra_src" -type f -name '*.md' -print0)

# ---------------------------------------------------------------------------
# 2) Copy docs/design/story-*.md and docs/design/matrix-*.md
#    story-*.md  -> requirement-breakdown/user-stories/
#    matrix-*.md -> requirement-breakdown/traceability-matrices/
#    In the project, both live in docs/design/; in the library they are split
#    into the two requirement-breakdown subfolders.
# ---------------------------------------------------------------------------
design_src="$project_dir/docs/design"
if [[ -d "$design_src" ]]; then
    us_dst="$product_library_dir/requirement-breakdown/user-stories"
    tm_dst="$product_library_dir/requirement-breakdown/traceability-matrices"
    mkdir -p -- "$us_dst" || { error "cannot create $us_dst"; exit 1; }
    mkdir -p -- "$tm_dst" || { error "cannot create $tm_dst"; exit 1; }

    while IFS= read -r -d '' f; do
        copy_file "$f" "$us_dst" || exit 1
        story_copied=$((story_copied + 1))
    done < <(find "$design_src" -maxdepth 1 -type f -name 'story-*.md' -print0)

    while IFS= read -r -d '' f; do
        copy_file "$f" "$tm_dst" || exit 1
        matrix_copied=$((matrix_copied + 1))
    done < <(find "$design_src" -maxdepth 1 -type f -name 'matrix-*.md' -print0)
else
    note "docs/design/ not found under project; skipping user story & matrix export."
fi

# ---------------------------------------------------------------------------
# 3) Create / update _product.md
# ---------------------------------------------------------------------------
progress_json="$project_dir/progress.json"
projectId=""
projectName=""
if [[ -f "$progress_json" ]]; then
    projectId=$(json_string_value "$progress_json" "projectId")
    projectName=$(json_string_value "$progress_json" "projectName")
else
    warn "progress.json not found at $progress_json; id and name will be empty."
fi

product_md="$product_library_dir/_product.md"

# Default raw values (match the spec's quoted-string / inline-array style).
# On an existing _product.md, preserve createdAt, businessDomain, keywords and
# summary exactly as written (reusing existing product assets); only id/name
# (from progress.json) and lastUpdated are regenerated.
raw_createdAt="\"$now\""
raw_businessDomain='""'
raw_keywords='[]'
raw_summary='""'

if [[ -f "$product_md" ]]; then
    v=""
    v=$(frontmatter_raw_value "$product_md" "createdAt");       [[ -n "$v" ]] && raw_createdAt="$v"
    v=$(frontmatter_raw_value "$product_md" "businessDomain");  [[ -n "$v" ]] && raw_businessDomain="$v"
    v=$(frontmatter_raw_value "$product_md" "keywords");        [[ -n "$v" ]] && raw_keywords="$v"
    v=$(frontmatter_raw_value "$product_md" "summary");         [[ -n "$v" ]] && raw_summary="$v"
fi

# Write _product.md with YAML frontmatter. Values are passed as printf %s
# arguments (not via parameter-expansion replacement), so characters such as
# '&', '%', '`' or '$()' inside values are written literally and never
# re-interpreted (mirrors the safety approach used by init-project.sh).
{
    printf '%s\n' '---'
    printf 'id: "%s"\n'            "$projectId"
    printf 'name: "%s"\n'          "$projectName"
    printf 'summary: %s\n'        "$raw_summary"
    printf 'keywords: %s\n'       "$raw_keywords"
    printf 'businessDomain: %s\n' "$raw_businessDomain"
    printf 'createdAt: %s\n'       "$raw_createdAt"
    printf 'lastUpdated: "%s"\n'  "$now"
    printf '%s\n' '---'
} > "$product_md"

printf '  created/updated: %s\n' "$product_md"

# _manifest.md is intentionally NOT modified by this script (too complex for
# bash to do safely); remind the user to update it by hand.
note "_manifest.md was not modified. Please update it manually if needed."

# ---------------------------------------------------------------------------
# 4) Summary + git reminder
# ---------------------------------------------------------------------------
printf '\n'
printf '==================== Export summary ====================\n'
printf '  Product library directory         : %s\n' "$product_library_dir"
printf '  Requirement-analysis files copied : %d\n' "$ra_copied"
printf '  User stories copied               : %d\n' "$story_copied"
printf '  Traceability matrices copied      : %d\n' "$matrix_copied"
printf '  _product.md lastUpdated           : %s\n' "$now"
printf '=======================================================\n'
printf '\n'
printf '请手动更新 _manifest.md 并执行 git add && git commit && git push 上传到远程仓库\n'

exit 0
