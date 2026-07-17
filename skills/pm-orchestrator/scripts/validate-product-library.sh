#!/usr/bin/env bash
#
# validate-product-library.sh
#
# Validates the structure of a global product library directory.
#
# Usage:
#   bash validate-product-library.sh [library_path] [spec_file]
#
#   library_path : Optional. Path to the product library (default: $HOME/.product-library)
#   spec_file    : Optional. Path to product-library-spec.md (default: ../product-library-spec.md)
#
# Cross-platform: Windows Git Bash / macOS / Linux.
# Dependencies: bash + standard Unix tools only (grep, find, sed, awk, head,
# tr, printf). No jq / perl / python required.
#
# Exit codes:
#   0 - all validation checks passed
#   1 - one or more validation checks failed
#   2 - usage error
#
# NOTE: Uses `set -u` (not `set -e`) so that every check runs and all issues
# are collected before reporting.

set -u

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
# A product folder name: lowercase alphanumerics and hyphens, 1-63 chars,
# must start with a letter or digit (excludes '_'/'.'-prefixed entries).
readonly PRODUCT_NAME_REGEX='^[a-z0-9][a-z0-9-]{0,62}$'

# ---------------------------------------------------------------------------
# Globals
# ---------------------------------------------------------------------------
LIBRARY_PATH=""
SPEC_FILE=""
ISSUES=()
PRODUCT_COUNT=0

# ---------------------------------------------------------------------------
# Output helpers
# ---------------------------------------------------------------------------
pass() { printf '  [PASS] %s\n' "$*"; }
fail() { printf '  [FAIL] %s\n' "$*"; }
note() { printf '  [NOTE] %s\n' "$*"; }
section() { printf '\n=== %s ===\n' "$*"; }

# ---------------------------------------------------------------------------
# Frontmatter helpers
# ---------------------------------------------------------------------------

# Trim leading and trailing whitespace from a string (portable bash).
trim() {
  local s="$1"
  s="${s#"${s%%[![:space:]]*}"}"   # leading whitespace
  s="${s%"${s##*[![:space:]]}"}"   # trailing whitespace
  printf '%s' "$s"
}

# Extract the YAML frontmatter block (text between the first and second '---'
# lines) from a markdown file. Prints the frontmatter text to stdout.
# Returns 0 if a valid (opening + closing) frontmatter block was found,
# 1 otherwise. Handles CRLF line endings.
extract_frontmatter() {
  local file="$1"
  [[ -f "$file" ]] || return 1

  # First line must be exactly '---' (strip a trailing CR for CRLF files).
  local first
  first=$(head -n 1 "$file" 2>/dev/null) || return 1
  first="${first%$'\r'}"
  [[ "$first" == "---" ]] || return 1

  # Print everything between the opening and closing '---'.
  # The END block sets the exit status: 0 if a closing '---' was seen, else 1.
  local output rc
  output=$(awk '
    NR == 1 { next }                       # skip opening ---
    /^---[[:space:]]*$/ { found = 1; exit } # closing ---
    { print }
    END { exit (found ? 0 : 1) }
  ' "$file" 2>/dev/null)
  rc=$?
  [[ $rc -eq 0 ]] || return 1

  # Normalize CRLF -> LF so subsequent line-based greps behave consistently.
  printf '%s' "$output" | tr -d '\r'
  return 0
}

# Return 0 if the given frontmatter text contains a top-level key.
# Matches 'key:' or 'key :' at the start of a line (no indentation => top-level).
frontmatter_has_key() {
  local fm="$1"
  local key="$2"
  printf '%s\n' "$fm" | grep -Eq "^${key}[[:space:]]*:"
}

# ---------------------------------------------------------------------------
# Generic existence checks
# ---------------------------------------------------------------------------

# Check a directory exists; record an issue if missing. Returns 0/1.
check_dir() {
  local dir="$1"
  local label="$2"
  if [[ -d "$dir" ]]; then
    pass "$label exists"
    return 0
  else
    fail "$label missing: $dir"
    ISSUES+=("$label missing: $dir")
    return 1
  fi
}

# Check 8: every (non-meta) .md file in a directory matches the expected
# prefix pattern. Meta/hidden files (starting with '_' or '.') are skipped.
check_doc_prefix() {
  local dir="$1"
  local prefix="$2"
  local label="$3"
  local pattern="${prefix}*.md"

  [[ -d "$dir" ]] || return 0

  local count=0
  local f base
  while IFS= read -r -d '' f; do
    base=$(basename "$f")

    # Skip meta/hidden files (templates, .DS_Store-like, etc.).
    case "$base" in
      _*|.*)
        note "Skipping meta/hidden file: $base"
        continue
        ;;
    esac

    count=$((count + 1))

    # Glob-match against the expected prefix pattern. The prefix is quoted
    # (treated literally, safe even if it contained shell metacharacters) while
    # the trailing '*.md' stays unquoted so '*' acts as a glob wildcard.
    case "$base" in
      "${prefix}"*.md)
        pass "$label document matches '$pattern': $base"
        ;;
      *)
        fail "$label document does not match '$pattern': $base"
        ISSUES+=("$label document does not match '$pattern': $base (in $dir)")
        ;;
    esac
  done < <(find "$dir" -maxdepth 1 -type f -name '*.md' -print0 2>/dev/null)

  if [[ "$count" -eq 0 ]]; then
    note "$label contains no documents (empty directory is allowed)"
  fi
  return 0
}

# ---------------------------------------------------------------------------
# Check 1: library directory exists
# ---------------------------------------------------------------------------
# Special case: if the library directory does not exist at all, this is NOT
# a validation failure. The orchestrator will guide the user through
# init-product-library.sh. We print "LIBRARY_NOT_EXISTS" as a machine-readable
# marker and exit 0 so the caller can branch on stdout.
check_library_exists() {
  if [[ -d "$LIBRARY_PATH" ]]; then
    pass "Library directory exists: $LIBRARY_PATH"
    return 0
  else
    note "LIBRARY_NOT_EXISTS: $LIBRARY_PATH"
    note "Product library directory not found. Use init-product-library.sh to create it."
    # Machine-readable marker for the orchestrator to grep.
    echo "LIBRARY_STATUS=NOT_EXISTS"
    return 99  # special return code: not-exists (caller treats as pass+branch)
  fi
}

# ---------------------------------------------------------------------------
# Check 2: _manifest.md exists with valid YAML frontmatter (products: key)
# ---------------------------------------------------------------------------
check_manifest() {
  local manifest="$LIBRARY_PATH/_manifest.md"
  section "Check 2: _manifest.md frontmatter"

  if [[ ! -f "$manifest" ]]; then
    fail "_manifest.md not found at library root: $manifest"
    ISSUES+=("_manifest.md not found at library root: $manifest")
    return 1
  fi
  pass "_manifest.md exists: $manifest"

  local fm
  fm=$(extract_frontmatter "$manifest") || {
    fail "_manifest.md does not have valid YAML frontmatter (missing opening/closing '---')"
    ISSUES+=("_manifest.md has invalid YAML frontmatter: $manifest")
    return 1
  }

  if [[ -z "$fm" ]]; then
    fail "_manifest.md has empty YAML frontmatter"
    ISSUES+=("_manifest.md has empty YAML frontmatter: $manifest")
    return 1
  fi
  pass "_manifest.md has non-empty YAML frontmatter"

  if ! frontmatter_has_key "$fm" "products"; then
    fail "_manifest.md frontmatter is missing required key: products:"
    ISSUES+=("_manifest.md frontmatter missing 'products:' key: $manifest")
    return 1
  fi
  pass "_manifest.md frontmatter contains 'products:' key"

  # Informational: detect an empty products array (not a failure).
  detect_empty_products_array "$fm"
  return 0
}

# Print a note if the manifest's products array appears empty (informational).
# Returns 0 if empty, 1 otherwise.
detect_empty_products_array() {
  local fm="$1"
  local products_line val item_count
  products_line=$(printf '%s\n' "$fm" | grep -E '^products[[:space:]]*:' | head -n 1)
  val=$(trim "${products_line#*:}")

  if [[ "$val" == "[]" ]]; then
    note "Manifest 'products' array is empty (products: [])"
    return 0
  fi

  if [[ -z "$val" ]]; then
    # Block style: look for list items ('- ') in the frontmatter.
    item_count=$(printf '%s\n' "$fm" | grep -Ec '^[[:space:]]+-[[:space:]]')
    if [[ "$item_count" -eq 0 ]]; then
      note "Manifest 'products' array appears empty (no list items)"
      return 0
    fi
  fi
  return 1
}

# ---------------------------------------------------------------------------
# Check 3: identify product folders by name regex
# ---------------------------------------------------------------------------
is_product_name() {
  printf '%s' "$1" | grep -Eq "$PRODUCT_NAME_REGEX"
}

# ---------------------------------------------------------------------------
# Checks 4-8: validate a single product folder
# ---------------------------------------------------------------------------
validate_product() {
  local product_dir="$1"
  local name
  name=$(basename "$product_dir")

  section "Product: $name  ($product_dir)"

  # (Check 3 established the name matches the rule; restate for clarity.)
  pass "Folder name matches product naming rule: $name"

  # ---- Check 4: _product.md with valid frontmatter (id, name, businessDomain)
  local product_md="$product_dir/_product.md"
  section "Check 4: _product.md frontmatter ($name)"
  if [[ ! -f "$product_md" ]]; then
    fail "[$name] _product.md not found: $product_md"
    ISSUES+=("[$name] _product.md not found: $product_md")
  else
    pass "[$name] _product.md exists: $product_md"
    local pfm
    pfm=$(extract_frontmatter "$product_md") || {
      fail "[$name] _product.md has invalid YAML frontmatter: $product_md"
      ISSUES+=("[$name] _product.md has invalid YAML frontmatter: $product_md")
      pfm=""
    }
    if [[ -n "$pfm" ]]; then
      pass "[$name] _product.md has non-empty YAML frontmatter"
      local missing_keys=()
      frontmatter_has_key "$pfm" "id"             || missing_keys+=("id")
      frontmatter_has_key "$pfm" "name"           || missing_keys+=("name")
      frontmatter_has_key "$pfm" "businessDomain" || missing_keys+=("businessDomain")
      if [[ ${#missing_keys[@]} -gt 0 ]]; then
        fail "[$name] _product.md frontmatter missing keys: ${missing_keys[*]}"
        ISSUES+=("[$name] _product.md frontmatter missing keys: ${missing_keys[*]}")
      else
        pass "[$name] _product.md frontmatter has keys: id, name, businessDomain"
      fi
    fi
  fi

  # ---- Check 5: requirement-analysis/ and requirement-breakdown/ directories
  local ra="$product_dir/requirement-analysis"
  local rb="$product_dir/requirement-breakdown"
  section "Check 5: requirement-analysis/ & requirement-breakdown/ ($name)"
  check_dir "$ra" "requirement-analysis/"
  check_dir "$rb" "requirement-breakdown/"

  # ---- Check 6 & 8: requirement-analysis subdirs + prefix patterns
  section "Check 6: requirement-analysis subdirectories ($name)"
  if [[ -d "$ra" ]]; then
    check_dir "$ra/requirement-cards" "requirement-analysis/requirement-cards/"
    check_dir "$ra/epics"             "requirement-analysis/epics/"
    check_dir "$ra/features"          "requirement-analysis/features/"
    section "Check 8: document prefix patterns under requirement-analysis ($name)"
    check_doc_prefix "$ra/requirement-cards" "req-"     "requirement-cards"
    check_doc_prefix "$ra/epics"             "epic-"    "epics"
    check_doc_prefix "$ra/features"          "feature-" "features"
  else
    note "Skipping requirement-analysis subdirectory checks (parent missing)"
  fi

  # ---- Check 7 & 8: requirement-breakdown subdirs + prefix patterns
  section "Check 7: requirement-breakdown subdirectories ($name)"
  if [[ -d "$rb" ]]; then
    check_dir "$rb/user-stories"          "requirement-breakdown/user-stories/"
    check_dir "$rb/traceability-matrices" "requirement-breakdown/traceability-matrices/"
    section "Check 8: document prefix patterns under requirement-breakdown ($name)"
    check_doc_prefix "$rb/user-stories"          "story-"  "user-stories"
    check_doc_prefix "$rb/traceability-matrices" "matrix-" "traceability-matrices"
  else
    note "Skipping requirement-breakdown subdirectory checks (parent missing)"
  fi
}

# ---------------------------------------------------------------------------
# Scan product folders (Check 3) and validate each (Checks 4-8)
# ---------------------------------------------------------------------------
scan_products() {
  section "Check 3: scan product folders"

  local subdir bname
  while IFS= read -r -d '' subdir; do
    bname=$(basename "$subdir")

    # Explicitly exclude meta/hidden entries (the regex also rejects these,
    # but this keeps the skip message clear and is defensive).
    case "$bname" in
      _*|.*)
        note "Skipping non-product entry: $bname"
        continue
        ;;
    esac

    if is_product_name "$bname"; then
      PRODUCT_COUNT=$((PRODUCT_COUNT + 1))
      validate_product "$subdir"
    else
      note "Skipping directory (does not match product naming rule): $bname"
    fi
  done < <(find "$LIBRARY_PATH" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null)
}

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
print_summary() {
  local issue_count=${#ISSUES[@]}
  section "Summary"
  printf 'Products scanned : %d\n' "$PRODUCT_COUNT"
  printf 'Issues found     : %d\n' "$issue_count"

  if [[ "$issue_count" -eq 0 ]]; then
    if [[ "$PRODUCT_COUNT" -eq 0 ]]; then
      note "Product library is empty (0 products). This is valid."
    fi
    printf '\nValidation passed for %d product(s)\n' "$PRODUCT_COUNT"
    return 0
  fi

  printf '\nIssue details:\n'
  local i
  for i in "${!ISSUES[@]}"; do
    printf '  %d. %s\n' "$((i + 1))" "${ISSUES[$i]}"
  done
  printf '\nValidation failed with %d issue(s)\n' "$issue_count"
  return 1
}

# ---------------------------------------------------------------------------
# Usage & main
# ---------------------------------------------------------------------------
usage() {
  cat <<'EOF'
Usage: bash validate-product-library.sh [library_path] [spec_file]

Arguments:
  library_path  Optional. Path to the product library (default: $HOME/.product-library)
  spec_file     Optional. Path to product-library-spec.md (default: ../product-library-spec.md)

Exit codes:
  0  all validation checks passed, or product library is not initialized yet
  1  one or more validation checks failed
  2  usage error
EOF
}

main() {
  if [[ $# -gt 2 ]]; then
    usage >&2
    exit 2
  fi

  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

  LIBRARY_PATH="${1:-$HOME/.product-library}"
  SPEC_FILE="${2:-$script_dir/../product-library-spec.md}"

  printf 'Validating product library:\n'
  printf '  library : %s\n' "$LIBRARY_PATH"
  printf '  spec    : %s\n' "$SPEC_FILE"

  # Informational: spec file existence (reference only; does not affect exit).
  if [[ -f "$SPEC_FILE" ]]; then
    note "Spec file exists: $SPEC_FILE"
  else
    note "Spec file not found (used for reference only): $SPEC_FILE"
  fi

  # Check 1: library directory exists.
  section "Check 1: library directory exists"
  check_library_exists
  rc=$?
  if [[ $rc -eq 99 ]]; then
    # Library does not exist; this is not a failure. Exit 0 with the
    # LIBRARY_NOT_EXISTS marker already printed by check_library_exists.
    printf '\nValidation skipped: library does not exist.\n'
    exit 0
  elif [[ $rc -ne 0 ]]; then
    print_summary
    exit 1
  fi

  # Check 2: manifest.
  check_manifest

  # Checks 3-8: product folders.
  scan_products

  # Summary & exit code.
  print_summary
  exit $?
}

main "$@"
