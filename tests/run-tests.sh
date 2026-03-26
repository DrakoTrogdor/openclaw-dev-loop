#!/usr/bin/env bash
# run-tests.sh — Test suite for the dev-loop skill.
#
# Modes:
#   structural   Verify the fixture has correct structure and planted flaws are present.
#                Fully automated, no agent required.
#
#   integration  (Future) Spawn an agent with the skill + fixture, assert checklist output.
#
# Usage: ./run-tests.sh [--mode structural|integration] [-v]

set -euo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FIXTURE_DIR="$TESTS_DIR/fixture"
MODE="structural"
VERBOSE=false
PASS=0
FAIL=0

usage() {
  cat <<EOF
Usage: ./run-tests.sh [options]

Options:
  --mode <mode>   Test mode: structural (default) or integration
  -v, --verbose   Show details for passing checks too
  -h, --help      Show this help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode)      MODE="$2"; shift 2 ;;
    -v|--verbose) VERBOSE=true; shift ;;
    -h|--help)   usage; exit 0 ;;
    *) echo "Unknown argument: $1"; usage; exit 1 ;;
  esac
done

# ── Helpers ───────────────────────────────────────────────────────────────────

pass() { PASS=$((PASS+1)); [[ "$VERBOSE" == true ]] && echo "  [PASS] $1" || true; }
fail() { FAIL=$((FAIL+1)); echo "  [FAIL] $1"; }

assert_file_exists() {
  local file="$1" label="$2"
  if [[ -f "$file" ]]; then pass "$label exists"; else fail "$label missing: $file"; fi
}

assert_file_contains() {
  local file="$1" pattern="$2" label="$3"
  if grep -Eq "$pattern" "$file" 2>/dev/null; then
    pass "$label"
  else
    fail "$label — pattern not found: '$pattern' in $file"
  fi
}

assert_file_not_contains() {
  local file="$1" pattern="$2" label="$3"
  if ! grep -Eq "$pattern" "$file" 2>/dev/null; then
    pass "$label"
  else
    fail "$label — unexpected pattern found: '$pattern' in $file"
  fi
}

assert_build_passes() {
  local dir="$1" label="$2"
  if bash "$dir/build.sh" --no-commit > /dev/null 2>&1; then
    pass "$label"
  else
    fail "$label — build.sh exited non-zero"
  fi
}

# ── Structural tests ──────────────────────────────────────────────────────────

run_structural() {
  echo ""
  echo "── Structural Tests ─────────────────────────────────────────────────────────"

  echo ""
  echo "  [fixture: required files]"
  assert_file_exists "$FIXTURE_DIR/README.md"          "README.md"
  assert_file_exists "$FIXTURE_DIR/STATUS.md"          "STATUS.md"
  assert_file_exists "$FIXTURE_DIR/build.sh"           "build.sh"
  assert_file_exists "$FIXTURE_DIR/src/greeter.py"     "src/greeter.py"
  assert_file_exists "$FIXTURE_DIR/tests/test_greeter.py" "tests/test_greeter.py"

  echo ""
  echo "  [fixture: README documents build command]"
  assert_file_contains "$FIXTURE_DIR/README.md" "./build.sh" \
    "README.md references build.sh"

  echo ""
  echo "  [fixture: STATUS.md has known issues]"
  assert_file_contains "$FIXTURE_DIR/STATUS.md" "Known Issues" \
    "STATUS.md has Known Issues section"
  assert_file_contains "$FIXTURE_DIR/STATUS.md" "times 0" \
    "STATUS.md documents --times 0 bug"

  echo ""
  echo "  [fixture: planted flaw — Step 1 (README/code mismatch)]"
  assert_file_contains  "$FIXTURE_DIR/README.md"       "\-\-reverse" \
    "README documents --reverse flag"
  assert_file_not_contains "$FIXTURE_DIR/src/greeter.py" '"--reverse"' \
    "--reverse not implemented in code"

  echo ""
  echo "  [fixture: planted flaw — Step 2 (help text mismatch)]"
  assert_file_contains "$FIXTURE_DIR/src/greeter.py" 'default=3' \
    "actual default is 3"
  assert_file_contains "$FIXTURE_DIR/src/greeter.py" 'default: 1' \
    "help text claims default is 1"

  echo ""
  echo "  [fixture: planted flaw — Step 3a (no guard on times <= 0)]"
  assert_file_not_contains "$FIXTURE_DIR/src/greeter.py" 'times.*<=.*0\|times < 1\|times <= 0' \
    "no guard against times <= 0"

  echo ""
  echo "  [fixture: planted flaw — Step 3b (silently discarded encode)]"
  assert_file_contains "$FIXTURE_DIR/src/greeter.py" 'args.name.encode' \
    "encode() call present (result discarded)"

  echo ""
  echo "  [fixture: planted flaw — Step 3c (unused import)]"
  assert_file_contains "$FIXTURE_DIR/src/greeter.py" 'import os' \
    "unused import os present"

  echo ""
  echo "  [fixture: build passes (tests are green before dev-loop runs)]"
  assert_build_passes "$FIXTURE_DIR" "fixture build.sh --no-commit"

  echo ""
  echo "  [skill: required files]"
  assert_file_exists "$TESTS_DIR/../SKILL.md"                    "SKILL.md"
  assert_file_exists "$TESTS_DIR/../references/DEV-LOOP.md"      "references/DEV-LOOP.md"

  echo ""
  echo "  [skill: SKILL.md has required frontmatter]"
  assert_file_contains "$TESTS_DIR/../SKILL.md" "^name:" \
    "SKILL.md has name field"
  assert_file_contains "$TESTS_DIR/../SKILL.md" "^description:" \
    "SKILL.md has description field"

  echo ""
  echo "  [skill: DEV-LOOP.md has all 6 steps]"
  for step in "STEP 1" "STEP 2" "STEP 3" "STEP 4" "STEP 5" "STEP 6"; do
    assert_file_contains "$TESTS_DIR/../references/DEV-LOOP.md" "$step" \
      "DEV-LOOP.md contains $step"
  done

  echo ""
  echo "  [skill: DEV-LOOP.md references README and STATUS]"
  assert_file_contains "$TESTS_DIR/../references/DEV-LOOP.md" "README.md" \
    "DEV-LOOP.md references README.md"
  assert_file_contains "$TESTS_DIR/../references/DEV-LOOP.md" "STATUS.md" \
    "DEV-LOOP.md references STATUS.md"
}

# ── Integration tests (stub) ──────────────────────────────────────────────────

run_integration() {
  echo ""
  echo "── Integration Tests ────────────────────────────────────────────────────────"
  echo ""
  echo "  Integration tests require spawning an agent with the skill loaded."
  echo "  To run manually:"
  echo ""
  echo "    1. Point your agent at: $FIXTURE_DIR"
  echo "    2. Trigger: 'Run the dev loop on this project'"
  echo "    3. After completion, assert DEV-LOOP-CHECKLIST.md in fixture root contains:"
  echo "       - '--reverse' (Step 1 finding)"
  echo "       - 'default' (Step 2 finding)"
  echo "       - 'times' and '0' or 'guard' (Step 3a finding)"
  echo "       - 'encode' (Step 3b finding)"
  echo "       - 'import os' or 'unused' (Step 3c finding)"
  echo "       - Build: PASS"
  echo ""
  echo "  Automated integration tests: TODO"
  echo ""
  pass "Integration stub (manual)"
}

# ── Run ───────────────────────────────────────────────────────────────────────

case "$MODE" in
  structural)  run_structural ;;
  integration) run_structural; run_integration ;;
  *) echo "Unknown mode: $MODE"; usage; exit 1 ;;
esac

echo ""
echo "─────────────────────────────────────────────────────────────────────────────"
echo "  Results: $PASS passed, $FAIL failed"
echo "─────────────────────────────────────────────────────────────────────────────"
echo ""

[[ $FAIL -eq 0 ]] && exit 0 || exit 1
