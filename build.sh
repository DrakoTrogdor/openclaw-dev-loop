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

# Resolve SKILLS_DIR in priority order:
#   1. --skills-dir flag (set later in arg parsing)
#   2. Sibling skills/ folder (workspace layout: repo lives next to skills/)
#   3. ~/.openclaw/skills/dev-loop (standard OpenClaw install location)
_SIBLING_SKILLS="$(dirname "$REPO_DIR")/skills/dev-loop"
_DEFAULT_SKILLS="$HOME/.openclaw/skills/dev-loop"
if [[ -d "$(dirname "$REPO_DIR")/skills" ]]; then
  SKILLS_DIR="$_SIBLING_SKILLS"
else
  SKILLS_DIR="$_DEFAULT_SKILLS"
fi
COMMIT_BODY=""
NO_COMMIT=false
SKILLS_DIR_OVERRIDE=""

usage() {
  cat <<EOF
Usage: ./build.sh [options]

Syncs skill files into the OpenClaw skills directory, then commits and pushes.

Options:
  --msg <message>       Commit body appended to the timestamp title
                        e.g. --msg "feat: improve step 3 instructions"
  --skills-dir <path>   Override the target skills directory
                        Auto-detected in order:
                          1. <repo-parent>/skills/dev-loop  (if sibling skills/ exists)
                          2. ~/.openclaw/skills/dev-loop    (standard install location)
  --no-commit           Sync files only; skip git add, commit, and push
  -h, --help            Show this help message

Commit message format:
  YYYY-MM-DD HH:MM:SS - <msg>   (with --msg)
  YYYY-MM-DD HH:MM:SS           (without --msg)

Examples:
  ./build.sh --msg "feat: add adversarial eval section"
  ./build.sh --no-commit
  ./build.sh --msg "fix: typo" --skills-dir ~/.openclaw/skills/dev-loop
EOF
}

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --msg)        COMMIT_BODY="$2"; shift 2 ;;
    --skills-dir) SKILLS_DIR="$2"; SKILLS_DIR_OVERRIDE="$2"; shift 2 ;;
    --no-commit)  NO_COMMIT=true;   shift   ;;
    -h|--help)    usage; exit 0             ;;
    *) echo "Unknown argument: $1"; echo ""; usage; exit 1 ;;
  esac
done

# ── Sync skill files ──────────────────────────────────────────────────────────
echo "[build] Source:      $REPO_DIR"
echo "[build] Destination: $SKILLS_DIR"
if [[ -z "$SKILLS_DIR_OVERRIDE" ]]; then
  if [[ "$SKILLS_DIR" == "$_SIBLING_SKILLS" ]]; then
    echo "[build] (resolved: sibling skills/ folder)"
  else
    echo "[build] (resolved: ~/.openclaw/skills/dev-loop)"
  fi
else
  echo "[build] (resolved: --skills-dir override)"
fi

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
