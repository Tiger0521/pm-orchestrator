#!/usr/bin/env bash
#
# init-product-library.sh
#
# Initialize one product library under the product-library collection root:
#   ~/.product-library/<product-library-id>/
#
# Four modes:
#   1. bootstrap-network : clone the built-in private network resource center library
#   2. clone             : git clone <remote_url> into the selected product library directory
#   3. copy              : copy an existing local directory into the selected product library directory
#   4. new               : create an empty library with _manifest.md, a design-standard doc, and git init
#
# Usage:
#   bash init-product-library.sh <product_library_id> <mode> [source_path]
#
#   product_library_id : kebab-case library id, e.g. network-resource-center-product-library
#   mode               : clone | copy | new
#   source_path        : required for clone (git remote URL) and copy (local dir);
#                        ignored for new
#
# Backward compatibility:
#   bash init-product-library.sh <mode> [source_path]
#   uses product_library_id=network-resource-center-product-library.
#
# Cross-platform: Windows Git Bash / macOS / Linux.

set -u

DEFAULT_PRODUCT_LIBRARY_ID="network-resource-center-product-library"
DEFAULT_REMOTE_URL="https://github.com/Tiger0521/network-resource-center-product-library.git"
DEFAULT_REMOTE_USER="Tiger0521"
PRODUCT_LIBRARY_ID=""
MODE=""
SOURCE=""

if [ -n "${HOME:-}" ]; then
  COLLECTION_ROOT="$HOME/.product-library"
elif [ -n "${USERPROFILE:-}" ]; then
  COLLECTION_ROOT="${USERPROFILE}/.product-library"
else
  echo "ERROR: cannot determine home directory (HOME and USERPROFILE both empty)" >&2
  exit 1
fi

usage() {
  cat <<'EOF'
Usage: bash init-product-library.sh <product_library_id> <mode> [source_path]

Modes:
  bootstrap-network       Clone the built-in network resource center product library
  clone <git_remote_url>   Clone a remote git repository as the selected product library
  copy  <local_dir_path>   Copy an existing local directory as the selected product library
  new                      Create an empty selected product library with _manifest.md

Example:
  bash init-product-library.sh bootstrap-network
  bash init-product-library.sh network-resource-center-product-library new

Backward compatible form:
  bash init-product-library.sh <bootstrap-network|clone|copy|new> [source_path]
  uses product_library_id=network-resource-center-product-library.

The library is created at ~/.product-library/<product-library-id>/
EOF
}

if [ "$#" -lt 1 ]; then
  usage >&2
  exit 2
fi

case "$1" in
  -h|--help)
    usage
    exit 0
    ;;
  bootstrap-network|clone|copy|new)
    PRODUCT_LIBRARY_ID="$DEFAULT_PRODUCT_LIBRARY_ID"
    MODE="$1"
    if [ "$#" -ge 2 ]; then
      SOURCE="$2"
    fi
    ;;
  *)
    PRODUCT_LIBRARY_ID="$1"
    if [ "$#" -lt 2 ]; then
      echo "ERROR: missing mode (expected: bootstrap-network | clone | copy | new)" >&2
      usage >&2
      exit 2
    fi
    MODE="$2"
    if [ "$#" -ge 3 ]; then
      SOURCE="$3"
    fi
    ;;
esac

if ! printf '%s' "$PRODUCT_LIBRARY_ID" | grep -Eq '^[a-z0-9][a-z0-9-]{0,62}$'; then
  echo "ERROR: invalid product_library_id (need ^[a-z0-9][a-z0-9-]{0,62}\$): $PRODUCT_LIBRARY_ID" >&2
  exit 2
fi

case "$MODE" in
  bootstrap-network)
    SOURCE="$DEFAULT_REMOTE_URL"
    ;;
  clone|copy)
    [ -n "$SOURCE" ] || { echo "ERROR: mode '$MODE' requires a source path argument" >&2; usage >&2; exit 2; }
    ;;
  new)
    ;;
  *)
    echo "ERROR: invalid mode '$MODE' (expected: bootstrap-network | clone | copy | new)" >&2
    usage >&2
    exit 2
    ;;
esac

LIBRARY_DIR="$COLLECTION_ROOT/$PRODUCT_LIBRARY_ID"

if [ -e "$LIBRARY_DIR" ]; then
  if [ "$MODE" = "bootstrap-network" ] && [ -d "$LIBRARY_DIR/.git" ]; then
    echo "LIBRARY_STATUS=EXISTS"
    echo "Product library already exists at: $LIBRARY_DIR"
    exit 0
  fi
  echo "ERROR: target already exists: $LIBRARY_DIR" >&2
  echo "       To re-initialize, remove or rename the existing directory first." >&2
  exit 1
fi

mkdir -p "$COLLECTION_ROOT" || { echo "ERROR: cannot create collection root: $COLLECTION_ROOT" >&2; exit 1; }

architecture_doc_name() {
  if [ "$PRODUCT_LIBRARY_ID" = "$DEFAULT_PRODUCT_LIBRARY_ID" ]; then
    printf '%s' "网络资源中心总体架构设计.md"
  else
    printf '%s' "总体架构设计.md"
  fi
}

ensure_architecture_doc() {
  local doc
  doc="$LIBRARY_DIR/$(architecture_doc_name)"
  if [ ! -f "$doc" ]; then
    cat > "$doc" <<ARCH_EOF
# 总体架构设计

请在本文件中维护该产品库的最高产品设计标准。Skill 每次使用该产品库前会读取本文件，并将其作为本轮需求分析、拆解和详细设计的最高设计依据。
ARCH_EOF
  fi
}

do_clone() {
  TOKEN="${PRODUCT_LIBRARY_GITHUB_TOKEN:-${GITHUB_TOKEN:-${GH_TOKEN:-}}}"
  if [ -z "$TOKEN" ]; then
    echo "AUTH_REQUIRED=1"
    echo "ERROR: GitHub read-only token is required before cloning" >&2
    exit 3
  fi
  if ! command -v base64 >/dev/null 2>&1; then
    echo "ERROR: base64 command is required for token-based private clone" >&2
    exit 1
  fi

  echo "Cloning product library from: $SOURCE"
  AUTH="$(printf '%s:%s' "$DEFAULT_REMOTE_USER" "$TOKEN" | base64 | tr -d '\n\r')"
  git -c "http.extraHeader=AUTHORIZATION: Basic $AUTH" clone "$SOURCE" "$LIBRARY_DIR" || {
    unset AUTH TOKEN
    echo "ERROR: git clone failed" >&2
    exit 1
  }
  unset AUTH TOKEN
  git -C "$LIBRARY_DIR" remote set-url origin "$SOURCE" >/dev/null 2>&1 || true
  ensure_architecture_doc
  echo ""
  echo "Product library cloned successfully at: $LIBRARY_DIR"
}


do_bootstrap_network() {
  echo "LIBRARY_STATUS=BOOTSTRAPPING"
  echo "Cloning default product library from: $DEFAULT_REMOTE_URL"

  TOKEN="${PRODUCT_LIBRARY_GITHUB_TOKEN:-${GITHUB_TOKEN:-${GH_TOKEN:-}}}"
  if [ -z "$TOKEN" ]; then
    echo "AUTH_REQUIRED=1"
    echo "ERROR: GitHub read-only token is required before cloning" >&2
    exit 3
  fi
  if ! command -v base64 >/dev/null 2>&1; then
    echo "ERROR: base64 command is required for token-based private clone" >&2
    exit 1
  fi

  AUTH="$(printf '%s:%s' "$DEFAULT_REMOTE_USER" "$TOKEN" | base64 | tr -d '\n\r')"
  git -c "http.extraHeader=AUTHORIZATION: Basic $AUTH" clone "$DEFAULT_REMOTE_URL" "$LIBRARY_DIR" || {
    unset AUTH TOKEN
    echo "ERROR: git clone failed" >&2
    exit 1
  }
  unset AUTH TOKEN

  git -C "$LIBRARY_DIR" remote set-url origin "$DEFAULT_REMOTE_URL" >/dev/null 2>&1 || true
  ensure_architecture_doc
  echo ""
  echo "Product library bootstrapped successfully at: $LIBRARY_DIR"
}
do_copy() {
  if [ ! -d "$SOURCE" ]; then
    echo "ERROR: source directory does not exist: $SOURCE" >&2
    exit 1
  fi

  echo "Copying product library from: $SOURCE"
  cp -R "$SOURCE" "$LIBRARY_DIR" || {
    echo "ERROR: copy failed" >&2
    exit 1
  }

  if [ -d "$LIBRARY_DIR/.git" ]; then
    rm -rf "$LIBRARY_DIR/.git"
    echo "  (removed existing .git directory)"
  fi

  ensure_architecture_doc

  ( cd "$LIBRARY_DIR" && git init && git add -A && git commit -m "init product library (copied from $SOURCE)" ) >/dev/null 2>&1 || {
    echo "WARNING: git init failed, library files are still copied successfully" >&2
  }

  echo ""
  echo "Product library copied successfully at: $LIBRARY_DIR"
  echo "  (a new git repo was initialized; please set your remote with: git remote add origin <url>)"
}

do_new() {
  echo "Creating empty product library at: $LIBRARY_DIR"
  mkdir -p "$LIBRARY_DIR" || { echo "ERROR: cannot create directory: $LIBRARY_DIR" >&2; exit 1; }

  TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)

  cat > "$LIBRARY_DIR/_manifest.md" <<MANIFEST_EOF
---
version: "1.0"
lastUpdated: "$TS"
products: []
---

# 产品库清单

本文件由 init-product-library.sh 自动生成。
每新增产品时，请手动在 products 数组中添加对应条目。
MANIFEST_EOF

  ensure_architecture_doc

  ( cd "$LIBRARY_DIR" && git init && git add -A && git commit -m "init empty product library" ) >/dev/null 2>&1 || {
    echo "WARNING: git init failed, library files are still created successfully" >&2
  }

  echo ""
  echo "Product library created successfully at: $LIBRARY_DIR"
  echo ""
  echo "Next steps:"
  echo "  1. Fill in: $LIBRARY_DIR/$(architecture_doc_name)"
  echo "  2. When you complete a project, use export-to-library.sh to add products."
  echo "  3. To sync with a remote, run:"
  echo "       cd \"$LIBRARY_DIR\""
  echo "       git remote add origin <your-remote-url>"
  echo "       git push -u origin main"
}

case "$MODE" in
  bootstrap-network) do_bootstrap_network ;;
  clone) do_clone ;;
  copy)  do_copy ;;
  new)   do_new ;;
esac

echo ""
echo "Done."
exit 0