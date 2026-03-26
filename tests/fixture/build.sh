#!/usr/bin/env bash
# build.sh — build and test entry point for the greeter fixture project.
#
# Usage: ./build.sh [--no-commit]
#   --no-commit   Run tests only, skip git commit

set -euo pipefail

FIXTURE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<EOF
Usage: ./build.sh [--no-commit]

  --no-commit   Run tests only, skip git commit
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

echo "[greeter] Running tests..."
cd "$FIXTURE_DIR"
python3 -m pytest tests/ -v 2>&1 || { echo "[greeter] Tests failed."; exit 1; }

echo "[greeter] All tests passed."

if [[ "$NO_COMMIT" == true ]]; then
  echo "[greeter] Skipping commit (--no-commit)."
  exit 0
fi

echo "[greeter] (No git commit configured for fixture project.)"
