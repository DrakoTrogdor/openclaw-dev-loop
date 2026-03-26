#!/usr/bin/env bash
# build.sh — build and test entry point for the counter fixture project.
#
# Since Rust may not be available in all environments, this script performs
# static analysis checks rather than a full cargo build.
#
# Usage: ./build.sh [--no-commit]
#   --no-commit   Run checks only, skip any commit step

set -euo pipefail

FIXTURE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<EOF
Usage: ./build.sh [--no-commit]

  --no-commit   Run checks only, skip commit
  -h, --help    Show this help
EOF
}

NO_COMMIT=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-commit) NO_COMMIT=true; shift ;;
    -h|--help)   usage; exit 0 ;;
    *) echo "Unknown argument: $1"; usage; exit 1 ;;
  esac
done

echo "[counter] Running checks..."

# Verify source exists
if [[ ! -f "$FIXTURE_DIR/src/main.rs" ]]; then
  echo "[counter] ERROR: src/main.rs not found"
  exit 1
fi

# Verify Cargo.toml exists
if [[ ! -f "$FIXTURE_DIR/Cargo.toml" ]]; then
  echo "[counter] ERROR: Cargo.toml not found"
  exit 1
fi

# Basic syntax/structure checks on main.rs
echo "[counter] Checking src/main.rs..."

# Check that fn main exists
if ! grep -q 'fn main()' "$FIXTURE_DIR/src/main.rs"; then
  echo "[counter] ERROR: fn main() not found in src/main.rs"
  exit 1
fi

# Check that count_word function exists
if ! grep -q 'fn count_word' "$FIXTURE_DIR/src/main.rs"; then
  echo "[counter] ERROR: fn count_word not found in src/main.rs"
  exit 1
fi

echo "[counter] All checks passed."

if [[ "$NO_COMMIT" == true ]]; then
  echo "[counter] Skipping commit (--no-commit)."
  exit 0
fi

echo "[counter] (No git commit configured for fixture project.)"
