#!/usr/bin/env bash
# sync-to-skills.sh
# Copies the skill files from this repo into the OpenClaw skills directory.
# Run this after pulling changes from the remote.
#
# Usage: ./sync-to-skills.sh [--skills-dir <path>]
#   --skills-dir   Override the target skills directory (default: /workspace/skills/dev-loop)

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="/workspace/skills/dev-loop"

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --skills-dir) SKILLS_DIR="$2"; shift 2 ;;
    *) echo "Unknown argument: $1"; exit 1 ;;
  esac
done

echo "[sync] Source:      $REPO_DIR"
echo "[sync] Destination: $SKILLS_DIR"

mkdir -p "$SKILLS_DIR/references"

cp "$REPO_DIR/SKILL.md"                    "$SKILLS_DIR/SKILL.md"
cp "$REPO_DIR/references/DEV-LOOP.md"      "$SKILLS_DIR/references/DEV-LOOP.md"

echo "[sync] Done."
echo ""
echo "Files copied:"
echo "  SKILL.md → $SKILLS_DIR/SKILL.md"
echo "  references/DEV-LOOP.md → $SKILLS_DIR/references/DEV-LOOP.md"
