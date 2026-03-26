#!/usr/bin/env bash
# build.sh
# Runs structural tests, syncs skill files into the OpenClaw skills directory,
# then stages, commits, and pushes.
#
# Usage: ./build.sh [--msg "commit body"] [--skills-dir <path>] [--no-commit] [-h|--help]
#   --msg          Optional commit body appended to the timestamp title
#   --skills-dir   Override the target skills directory (default: auto-detected)
#   --no-commit    Run tests and sync files; skip git add, commit, and push

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Resolve SKILLS_DIR in priority order:
#   1. --skills-dir flag (set later in arg parsing)
#   2. Sibling skills/ folder (workspace layout: repo lives next to skills/)
#   3. ~/.openclaw/skills/dev-loop (standard OpenClaw install location)
_SIBLING_SKILLS="$(dirname "$REPO_DIR")/skills/dev-loop"
if [[ -d "$(dirname "$REPO_DIR")/skills" ]]; then
  SKILLS_DIR="$_SIBLING_SKILLS"
elif [[ -n "${HOME:-}" ]]; then
  SKILLS_DIR="$HOME/.openclaw/skills/dev-loop"
else
  # HOME is unset and no sibling skills/ directory exists.
  # Can't compute default skills path. Require --skills-dir.
  SKILLS_DIR=""
fi
COMMIT_BODY=""
NO_COMMIT=false
SKILLS_DIR_OVERRIDE=""

usage() {
  cat <<EOF
Usage: ./build.sh [options]

Runs structural tests, syncs skill files into the OpenClaw skills directory,
then commits and pushes.

Options:
  --msg <message>       Commit body appended to the timestamp title
                        e.g. --msg "feat: improve step 3 instructions"
  --skills-dir <path>   Override the target skills directory
                        Auto-detected in order:
                          1. <repo-parent>/skills/dev-loop  (if sibling skills/ exists)
                          2. ~/.openclaw/skills/dev-loop    (standard install location)
  --no-commit           Run tests and sync files; skip git add, commit, and push
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
    --msg)        [[ $# -ge 2 ]] || { echo "Error: --msg requires an argument"; usage; exit 1; }
                  COMMIT_BODY="$2"; shift 2 ;;
    --skills-dir) [[ $# -ge 2 ]] || { echo "Error: --skills-dir requires an argument"; usage; exit 1; }
                  [[ -n "$2" ]] || { echo "Error: --skills-dir cannot be empty"; exit 1; }
                  SKILLS_DIR="$2"; SKILLS_DIR_OVERRIDE="$2"; shift 2 ;;
    --no-commit)  NO_COMMIT=true;   shift   ;;
    -h|--help)    usage; exit 0             ;;
    *) echo "Unknown argument: $1"; echo ""; usage; exit 1 ;;
  esac
done

# ── Validate SKILLS_DIR ────────────────────────────────────────────────────────
if [[ -z "$SKILLS_DIR" ]]; then
  echo "Error: Cannot determine skills directory. \$HOME is unset and no sibling skills/ directory exists."
  echo "       Use --skills-dir <path> to specify the target explicitly."
  exit 1
fi

# ── Validate --skills-dir path safety ─────────────────────────────────────────
case "$SKILLS_DIR" in
  /etc/*|/usr/*|/bin/*|/sbin/*|/sys/*|/proc/*)
    echo "Error: --skills-dir path '$SKILLS_DIR' looks like a system directory."
    echo "       Refusing to write skill files there. Use a path under your home or workspace."
    exit 1
    ;;
esac

# ── Run tests ─────────────────────────────────────────────────────────────────
echo "[build] Running structural tests..."
bash "$REPO_DIR/tests/run-tests.sh"

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

# Clean target to remove stale files from previous versions, then copy fresh
if [[ -d "$SKILLS_DIR" ]]; then
  rm -rf "$SKILLS_DIR"
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
  BRANCH="$(git rev-parse --abbrev-ref HEAD)"
  if [[ "$BRANCH" != "HEAD" ]] && git rev-parse --verify "origin/$BRANCH" >/dev/null 2>&1; then
    UNPUSHED="$(git log "origin/$BRANCH..HEAD" --oneline 2>/dev/null)"
    if [[ -n "$UNPUSHED" ]]; then
      echo "[build] Warning: unpushed commits on $BRANCH:"
      echo "$UNPUSHED" | sed 's/^/  /'
    fi
  fi
else
  git commit -m "$COMMIT_MSG"
  echo "[build] Committed: $COMMIT_MSG"
  BRANCH="$(git rev-parse --abbrev-ref HEAD)"
  git push origin "$BRANCH"
  echo "[build] Pushed to origin/$BRANCH."
fi
