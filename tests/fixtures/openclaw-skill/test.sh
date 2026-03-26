#!/usr/bin/env bash
# test.sh — Structural assertions for the openclaw-skill (bookmark-manager) fixture.
# Sourced by run-tests.sh. Uses assert_* helpers defined there.
# FIXTURE_DIR is set by the caller.

run_fixture_structural() {
  echo ""
  echo "  [openclaw-skill: required files]"
  assert_file_exists "$FIXTURE_DIR/README.md"                   "README.md"
  assert_file_exists "$FIXTURE_DIR/STATUS.md"                   "STATUS.md"
  assert_file_exists "$FIXTURE_DIR/build.sh"                    "build.sh"
  assert_file_exists "$FIXTURE_DIR/SKILL.md"                    "SKILL.md"
  assert_file_exists "$FIXTURE_DIR/scripts/bookmarks.sh"        "scripts/bookmarks.sh"
  assert_file_exists "$FIXTURE_DIR/references/STORAGE.md"       "references/STORAGE.md"
  assert_file_exists "$FIXTURE_DIR/references/SEARCH.md"        "references/SEARCH.md"

  echo ""
  echo "  [openclaw-skill: README documents build command]"
  assert_file_contains "$FIXTURE_DIR/README.md" "./build.sh" \
    "README.md references build.sh"

  echo ""
  echo "  [openclaw-skill: STATUS.md has known issues]"
  assert_file_contains "$FIXTURE_DIR/STATUS.md" "Known Issues" \
    "STATUS.md has Known Issues section"
  assert_file_contains "$FIXTURE_DIR/STATUS.md" "csv" \
    "STATUS.md documents csv export issue"

  echo ""
  echo "  [openclaw-skill: F1 — Step 1 (SKILL.md/code mismatch)]"
  assert_file_contains "$FIXTURE_DIR/SKILL.md" "csv" \
    "SKILL.md documents csv export format"
  assert_file_not_contains "$FIXTURE_DIR/scripts/bookmarks.sh" \
    '^\s*csv\)' \
    "csv format not implemented in export_bookmarks"

  echo ""
  echo "  [openclaw-skill: F2 — Step 2 (help text mismatch)]"
  assert_file_contains "$FIXTURE_DIR/scripts/bookmarks.sh" \
    'search by date range' \
    "help claims date range search"
  assert_file_not_contains "$FIXTURE_DIR/scripts/bookmarks.sh" \
    '--after|--before|date.*filter|date.*range.*\$' \
    "date range filtering not implemented"

  echo ""
  echo "  [openclaw-skill: F3a — Step 3 (no URL validation)]"
  assert_file_not_contains "$FIXTURE_DIR/scripts/bookmarks.sh" \
    'http.*://.*check|url.*valid|url.*regex|url.*pattern' \
    "no URL validation in save_bookmark"

  echo ""
  echo "  [openclaw-skill: F3b — Step 3 (grep -v with unescaped URL)]"
  assert_file_contains "$FIXTURE_DIR/scripts/bookmarks.sh" \
    'grep -v "\$url"' \
    "grep -v with raw URL variable (regex metachar vulnerability)"

  echo ""
  echo "  [openclaw-skill: F3c — Step 3 (unused variable)]"
  assert_file_contains "$FIXTURE_DIR/scripts/bookmarks.sh" 'BACKUP_DIR=' \
    "BACKUP_DIR defined"
  assert_file_not_contains "$FIXTURE_DIR/scripts/bookmarks.sh" \
    '\$BACKUP_DIR|\$\{BACKUP_DIR\}' \
    "BACKUP_DIR never referenced after definition"

  echo ""
  echo "  [openclaw-skill: F3E — Step 3E (tag case mismatch between save and search)]"
  assert_file_contains "$FIXTURE_DIR/scripts/bookmarks.sh" \
    "tr '\[:upper:\]' '\[:lower:\]'" \
    "save lowercases tags"
  # The flaw: tag variable is used directly in the tag filter without lowercasing.
  # The keyword search path uses .lower() but that's for query, not tags.
  # Check that $tag is never transformed before the grep/filter.
  if grep -Eq 'tag=.*lower|tag=.*tr.*upper|tag\)\.lower' "$FIXTURE_DIR/scripts/bookmarks.sh"; then
    fail "tag variable is lowercased before matching (flaw would be fixed)"
  else
    pass "search does not lowercase tag variable before matching"
  fi

  echo ""
  echo "  [openclaw-skill: build passes]"
  assert_build_passes "$FIXTURE_DIR" "build.sh --no-commit"
}
