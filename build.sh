#!/usr/bin/env bash
# build.sh
# Syncs skill files into the OpenClaw skills directory, then stages and commits.
#
# Usage: ./build.sh [--msg "commit body"] [--skills-dir <path>] [--no-commit]
#   --msg          Optional commit body appended to the timestamp title
#   --skills-dir   Override the target skills directory (default: /workspace/skills/dev-loop)
#   --no-commit    Sync files only; skip git add + commit

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="/workspace/skills/dev-loop"
COMMIT_BODY=""
NO_COMMIT=false

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --msg)        COMMIT_BODY="$2"; shift 2 ;;
    --skills-dir) SKILLS_DIR="$2";  shift 2 ;;
    --no-commit)  NO_COMMIT=true;   shift   ;;
    *) echo "Unknown argument: $1"; exit 1  ;;
  esac
done

# ── Sync skill files ──────────────────────────────────────────────────────────
echo "[build] Source:      $REPO_DIR"
echo "[build] Destination: $SKILLS_DIR"

mkdir -p "$SKILLS_DIR/references"

cp "$REPO_DIR/SKILL.md"               "$SKILLS_DIR/SKILL.md"
cp "$REPO_DIR/references/DEV-LOOP.md" "$SKILLS_DIR/references/DEV-LOOP.md"

echo "[build] Synced:"
echo "  SKILL.md → $SKILLS_DIR/SKILL.md"
echo "  references/DEV-LOOP.md → $SKILLS_DIR/references/DEV-LOOP.md"

# ── Commit ────────────────────────────────────────────────────────────────────
if [[ "$NO_COMMIT" == true ]]; then
  echo "[build] Skipping commit (--no-commit)"
  exit 0
fi

COMMIT_DATE="$(date '+%Y-%m-%d')"
COMMIT_TIME="$(date '+%H:%M:%S')"
COMMIT_TITLE="${COMMIT_DATE} ${COMMIT_TIME}"

if [[ -n "$COMMIT_BODY" ]]; then
  COMMIT_MSG="${COMMIT_TITLE} - ${COMMIT_BODY}"
else
  COMMIT_MSG="$COMMIT_TITLE"
fi

cd "$REPO_DIR"
git add -A

if git diff --cached --quiet; then
  echo "[build] Nothing to commit."
else
  git commit -m "$COMMIT_MSG"
  echo "[build] Committed: $COMMIT_MSG"
fi

git push origin main
echo "[build] Pushed to origin/main."
