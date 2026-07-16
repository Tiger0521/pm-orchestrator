#!/usr/bin/env bash
#
# init-product-library.sh
#
# Initialize the global product library at ~/.product-library/.
#
# Three modes:
#   1. clone : git clone <remote_url> into ~/.product-library/
#   2. copy  : copy an existing local directory into ~/.product-library/
#   3. new   : create an empty library with _manifest.md and git init
#
# Usage:
#   bash init-product-library.sh <mode> [source_path]
#
#   mode        : clone | copy | new
#   source_path : required for clone (git remote URL) and copy (local dir);
#                 ignored for new
#
# Exit codes:
#   0 - success
#   1 - error (target exists, source missing, git/cp failure, etc.)
#   2 - usage error
#
# Cross-platform: Windows Git Bash / macOS / Linux.

set -u

# Resolve home directory in a cross-platform way.
if [ -n "${HOME:-}" ]; then
  LIBRARY_DIR="$HOME/.product-library"
elif [ -n "${USERPROFILE:-}" ]; then
  # Windows Git Bash may have empty HOME but set USERPROFILE.
  LIBRARY_DIR="${USERPROFILE}/.product-library"
else
  echo "ERROR: cannot determine home directory (HOME and USERPROFILE both empty)" >&2
  exit 1
fi

MODE=""
SOURCE=""

usage() {
  cat <<'EOF'
Usage: bash init-product-library.sh <mode> [source_path]

Modes:
  clone <git_remote_url>   Clone a remote git repository as the product library
  copy  <local_dir_path>   Copy an existing local directory as the product library
  new                      Create an empty product library with _manifest.md

The library is created at ~/.product-library/
EOF
}

# ---------------------------------------------------------------------------
# Parse arguments
# ---------------------------------------------------------------------------
if [ "$#" -lt 1 ]; then
  usage >&2
  exit 2
fi

MODE="$1"

case "$MODE" in
  clone|copy)
    if [ "$#" -lt 2 ]; then
      echo "ERROR: mode '$MODE' requires a source path argument" >&2
      usage >&2
      exit 2
    fi
    SOURCE="$2"
    [ -n "$SOURCE" ] || { echo "ERROR: source path is empty" >&2; exit 2; }
    ;;
  new)
    # No source needed.
    ;;
  -h|--help)
    usage
    exit 0
    ;;
  *)
    echo "ERROR: invalid mode '$MODE' (expected: clone | copy | new)" >&2
    usage >&2
    exit 2
    ;;
esac

# ---------------------------------------------------------------------------
# Guard: target must not already exist
# ---------------------------------------------------------------------------
if [ -e "$LIBRARY_DIR" ]; then
  echo "ERROR: target already exists: $LIBRARY_DIR" >&2
  echo "       To re-initialize, remove or rename the existing directory first." >&2
  exit 1
fi

# Create parent directory if needed.
PARENT_DIR=$(dirname "$LIBRARY_DIR")
if [ ! -d "$PARENT_DIR" ]; then
  mkdir -p "$PARENT_DIR" || { echo "ERROR: cannot create parent directory: $PARENT_DIR" >&2; exit 1; }
fi

# ---------------------------------------------------------------------------
# Mode: clone
# ---------------------------------------------------------------------------
do_clone() {
  echo "Cloning product library from: $SOURCE"
  git clone "$SOURCE" "$LIBRARY_DIR" || {
    echo "ERROR: git clone failed" >&2
    exit 1
  }
  echo ""
  echo "Product library cloned successfully at: $LIBRARY_DIR"
}

# ---------------------------------------------------------------------------
# Mode: copy
# ---------------------------------------------------------------------------
do_copy() {
  # Resolve source to absolute path for display.
  if [ ! -d "$SOURCE" ]; then
    echo "ERROR: source directory does not exist: $SOURCE" >&2
    exit 1
  fi

  echo "Copying product library from: $SOURCE"
  cp -R "$SOURCE" "$LIBRARY_DIR" || {
    echo "ERROR: copy failed" >&2
    exit 1
  }

  # Remove any existing .git to avoid accidental pushes to the source repo.
  if [ -d "$LIBRARY_DIR/.git" ]; then
    rm -rf "$LIBRARY_DIR/.git"
    echo "  (removed existing .git directory)"
  fi

  # Initialize a fresh git repo.
  ( cd "$LIBRARY_DIR" && git init && git add -A && git commit -m "init product library (copied from $SOURCE)" ) >/dev/null 2>&1 || {
    echo "WARNING: git init failed, library files are still copied successfully" >&2
  }

  echo ""
  echo "Product library copied successfully at: $LIBRARY_DIR"
  echo "  (a new git repo was initialized; please set your remote with: git remote add origin <url>)"
}

# ---------------------------------------------------------------------------
# Mode: new (empty library)
# ---------------------------------------------------------------------------
do_new() {
  echo "Creating empty product library at: $LIBRARY_DIR"
  mkdir -p "$LIBRARY_DIR" || { echo "ERROR: cannot create directory: $LIBRARY_DIR" >&2; exit 1; }

  # Generate UTC timestamp.
  TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)

  # Create _manifest.md with an empty products array.
  cat > "$LIBRARY_DIR/_manifest.md" <<MANIFEST_EOF
---
version: "1.0"
lastUpdated: "$TS"
products: []
---

# 产品库全局清单

本文件由 init-product-library.sh 自动生成。
每新增产品时，请手动在 products 数组中添加对应条目。
MANIFEST_EOF

  # Initialize git repo.
  ( cd "$LIBRARY_DIR" && git init && git add -A && git commit -m "init empty product library" ) >/dev/null 2>&1 || {
    echo "WARNING: git init failed, library files are still created successfully" >&2
  }

  echo ""
  echo "Product library created successfully at: $LIBRARY_DIR"
  echo ""
  echo "Next steps:"
  echo "  1. When you complete a project, use export-to-library.sh to add products."
  echo "  2. To sync with a remote, run:"
  echo "       cd \"$LIBRARY_DIR\""
  echo "       git remote add origin <your-remote-url>"
  echo "       git push -u origin main"
}

# ---------------------------------------------------------------------------
# Dispatch
# ---------------------------------------------------------------------------
case "$MODE" in
  clone) do_clone ;;
  copy)  do_copy ;;
  new)   do_new ;;
esac

echo ""
echo "Done."
exit 0
