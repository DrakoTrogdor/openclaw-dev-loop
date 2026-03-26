#!/usr/bin/env bash
# build.sh — build and test entry point for the bookmark-manager skill fixture.
#
# Validates skill structure and runs basic smoke tests.
#
# Usage: ./build.sh [--no-commit]
#   --no-commit   Run tests only, skip commit

set -euo pipefail

FIXTURE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<EOF
Usage: ./build.sh [--no-commit]

  --no-commit   Run tests only, skip commit
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

echo "[bookmark-manager] Running checks..."

# Validate skill structure
echo "[bookmark-manager] Checking skill structure..."

if [[ ! -f "$FIXTURE_DIR/SKILL.md" ]]; then
  echo "  ERROR: SKILL.md not found"
  exit 1
fi
echo "  SKILL.md exists"

if ! head -5 "$FIXTURE_DIR/SKILL.md" | grep -q '^name:'; then
  echo "  ERROR: SKILL.md missing 'name:' in frontmatter"
  exit 1
fi
echo "  SKILL.md has name field"

if ! head -5 "$FIXTURE_DIR/SKILL.md" | grep -q '^description:'; then
  echo "  ERROR: SKILL.md missing 'description:' in frontmatter"
  exit 1
fi
echo "  SKILL.md has description field"

if [[ ! -f "$FIXTURE_DIR/scripts/bookmarks.sh" ]]; then
  echo "  ERROR: scripts/bookmarks.sh not found"
  exit 1
fi
echo "  scripts/bookmarks.sh exists"

# Smoke test: run help
echo "[bookmark-manager] Running smoke tests..."
if bash "$FIXTURE_DIR/scripts/bookmarks.sh" help > /dev/null 2>&1; then
  echo "  help command works"
else
  echo "  ERROR: help command failed"
  exit 1
fi

# Smoke test: save and search in a temp dir
TMPDIR="$(mktemp -d)"
export BOOKMARK_DIR="$TMPDIR"
bash "$FIXTURE_DIR/scripts/bookmarks.sh" save "https://example.com" --title "Test" --tags "test" > /dev/null 2>&1
RESULT="$(bash "$FIXTURE_DIR/scripts/bookmarks.sh" search "example" 2>&1)"
if echo "$RESULT" | grep -q "example.com"; then
  echo "  save + search smoke test passed"
else
  echo "  ERROR: save + search smoke test failed"
  rm -rf "$TMPDIR"
  exit 1
fi
rm -rf "$TMPDIR"

echo "[bookmark-manager] All checks passed."

if [[ "$NO_COMMIT" == true ]]; then
  echo "[bookmark-manager] Skipping commit (--no-commit)."
  exit 0
fi

echo "[bookmark-manager] (No git commit configured for fixture project.)"
