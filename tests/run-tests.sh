#!/usr/bin/env bash
# run-tests.sh — Test suite for the dev-loop skill.
#
# Modes:
#   structural   Verify the fixture has correct structure and planted flaws are present.
#                Fully automated, no agent required. Runs against the real fixture (read-only).
#
#   integration  Copies the fixture into a temp directory, prints instructions for running
#                the agent against the copy, asserts on DEV-LOOP-CHECKLIST.md output if
#                present, then cleans up.  The real fixture is never modified.
#
# Usage: ./run-tests.sh [--mode structural|integration] [--work-dir <path>] [-v] [-h|--help]

set -euo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FIXTURES_DIR="$TESTS_DIR/fixtures"
FIXTURE_DIR="$FIXTURES_DIR/python-greeter"  # default fixture for integration tests
WORK_DIR=""                        # temp copy used by integration tests (set at runtime)
WORK_DIR_USER=false                # true if --work-dir was provided (skip cleanup)
MODE="structural"
VERBOSE=false
PASS=0
FAIL=0

usage() {
  cat <<EOF
Usage: ./run-tests.sh [options]

Options:
  --mode <mode>        Test mode: structural (default) or integration
  --work-dir <path>    Re-use an existing temp fixture dir for integration assertions
                       (skips setup; useful after an agent has already run)
  -v, --verbose        Show details for passing checks too
  -h, --help           Show this help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode)      [[ $# -ge 2 ]] || { echo "Error: --mode requires an argument"; usage; exit 1; }
                 MODE="$2"; shift 2 ;;
    --work-dir)  [[ $# -ge 2 ]] || { echo "Error: --work-dir requires an argument"; usage; exit 1; }
                 if [[ ! -d "$2" ]]; then
                   echo "Error: --work-dir path is not a directory or does not exist: $2"; exit 1
                 fi
                 WORK_DIR="$2"; WORK_DIR_USER=true; shift 2 ;;
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
  if [[ ! -f "$file" ]]; then
    fail "$label — file missing: $file"
    return
  fi
  if grep -Eq "$pattern" "$file" 2>/dev/null; then
    pass "$label"
  else
    fail "$label — pattern not found: '$pattern' in $file"
  fi
}

assert_file_not_contains() {
  local file="$1" pattern="$2" label="$3"
  if [[ ! -f "$file" ]]; then
    fail "$label — file missing: $file"
    return
  fi
  if ! grep -Eq "$pattern" "$file" 2>/dev/null; then
    pass "$label"
  else
    fail "$label — unexpected pattern found: '$pattern' in $file"
  fi
}

assert_build_passes() {
  local dir="$1" label="$2"
  local build_output
  if build_output="$(bash "$dir/build.sh" --no-commit 2>&1)"; then
    pass "$label"
  else
    fail "$label — build.sh exited non-zero"
    echo "    ── build output ──"
    echo "$build_output" | sed 's/^/    /'
    echo "    ───────────────────"
  fi
}

# ── Temp workspace ────────────────────────────────────────────────────────────
# Creates an isolated copy of the fixture for agent runs.
# The real fixture is never touched during integration tests.

setup_work_dir() {
  if [[ -n "$WORK_DIR" && -d "$WORK_DIR" ]]; then
    # Re-use an existing temp dir (agent already ran; just assert)
    return
  fi
  WORK_DIR="$(mktemp -d /tmp/dev-loop-test-XXXXXX)"
  # Register cleanup trap — respects WORK_DIR_USER flag (don't delete user-provided dirs)
  trap 'teardown_work_dir' EXIT INT TERM
  cp -r "$FIXTURE_DIR/." "$WORK_DIR/"
  # Remove cache dirs copied from fixture (stale .pyc files, pytest metadata)
  find "$WORK_DIR" -type d \( -name '__pycache__' -o -name '.pytest_cache' \) -exec rm -rf {} + 2>/dev/null || true
  # Remove any leftover checklist from a previous run (shouldn't exist in the
  # canonical fixture, but guard anyway so assertions start clean)
  rm -f "$WORK_DIR/DEV-LOOP-CHECKLIST.md"
}

teardown_work_dir() {
  if [[ "$WORK_DIR_USER" == true ]]; then
    echo "  [teardown] Skipping cleanup (user-provided --work-dir)"
    return
  fi
  if [[ -n "$WORK_DIR" && -d "$WORK_DIR" ]]; then
    rm -rf "$WORK_DIR"
    WORK_DIR=""
  fi
}

# ── Structural tests ──────────────────────────────────────────────────────────

run_structural() {
  echo ""
  echo "── Structural Tests ─────────────────────────────────────────────────────────"

  # ── Test each fixture ─────────────────────────────────────────────────────────
  for fixture_dir in "$FIXTURES_DIR"/*/; do
    local fixture_name
    fixture_name="$(basename "$fixture_dir")"
    local test_file="$fixture_dir/test.sh"

    echo ""
    echo "  ── fixture: $fixture_name ──"

    if [[ ! -f "$test_file" ]]; then
      fail "$fixture_name: missing test.sh"
      continue
    fi

    # Source the fixture's test definitions (provides run_fixture_structural)
    FIXTURE_DIR="$fixture_dir"
    source "$test_file"

    if declare -f run_fixture_structural > /dev/null 2>&1; then
      run_fixture_structural
      unset -f run_fixture_structural
    else
      fail "$fixture_name: test.sh does not define run_fixture_structural()"
    fi
  done

  # ── Skill-level tests (not fixture-specific) ─────────────────────────────────
  echo ""
  echo "  [skill: required files]"
  assert_file_exists "$TESTS_DIR/../SKILL.md"                    "SKILL.md"
  assert_file_exists "$TESTS_DIR/../references/DEV-LOOP.md"      "references/DEV-LOOP.md"

  echo ""
  echo "  [skill: SKILL.md has valid YAML frontmatter]"
  assert_file_contains "$TESTS_DIR/../SKILL.md" "^name:" \
    "SKILL.md has name field"
  assert_file_contains "$TESTS_DIR/../SKILL.md" "^description:" \
    "SKILL.md has description field"
  # Validate YAML frontmatter is actually parseable
  if python3 -c "
import yaml, sys
with open(sys.argv[1]) as f:
    fm = f.read().split('---')[1]
yaml.safe_load(fm)
" "$TESTS_DIR/../SKILL.md" 2>/dev/null; then
    pass "SKILL.md YAML frontmatter is valid"
  else
    fail "SKILL.md YAML frontmatter is invalid (colons, quotes, or syntax error)"
  fi

  echo ""
  echo "  [skill: DEV-LOOP.md has all steps including adversarial]"
  for step in "STEP 1" "STEP 2" "STEP 3" "STEP 3E" "STEP 4" "STEP 5" "STEP 6"; do
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

# ── Integration tests ─────────────────────────────────────────────────────────
# Sets up a temp copy of the fixture for the agent to run against (manually).
# Call setup_work_dir to create the copy; teardown_work_dir after assertions.

run_integration() {
  echo ""
  echo "── Integration Tests ────────────────────────────────────────────────────────"
  echo ""

  setup_work_dir
  local work="$WORK_DIR"
  echo "  [setup] Temp fixture:  $work"
  echo "  [setup] Real fixture:  $FIXTURE_DIR (untouched)"
  echo ""

  # ── Manual instructions (until agent invocation is automated) ────────────────
  echo "  Integration tests require an agent run. To execute manually:"
  echo ""
  echo "    1. Point your agent at the temp fixture: $work"
  echo "    2. Trigger: 'Run the dev loop on this project'"
  echo "    3. After the agent finishes, re-run this script with:"
  echo "         --mode integration --work-dir $work"
  echo "       to assert against the checklist without recreating the temp dir."
  echo ""
  echo "  Expected findings in \$WORK_DIR/DEV-LOOP-CHECKLIST.md:"
  echo "    Step 1:  --reverse flag documented but not implemented"
  echo "    Step 2:  --times help text says 'default: 1' but code defaults to 3"
  echo "    Step 3:  no guard on times <= 0 (silently produces no output)"
  echo "    Step 3:  encode() result silently discarded"
  echo "    Step 3:  unused import os"
  echo "    Step 3E: empty name produces 'Hello, !' (adversarial eval)"
  echo "    Step 4:  build passes (all 4 pytest tests green)"
  echo ""

  # ── Assertions (run if WORK_DIR already has a checklist) ─────────────────────
  if [[ -f "$work/DEV-LOOP-CHECKLIST.md" ]]; then
    echo "  [found checklist — asserting output]"
    echo ""

    echo "  [Step 1 findings]"
    assert_file_contains "$work/DEV-LOOP-CHECKLIST.md" \
      "--reverse.*not implemented|--reverse.*missing|--reverse.*documented.*not" \
      "Checklist mentions --reverse doc/code mismatch (Step 1)"

    echo "  [Step 2 findings]"
    assert_file_contains "$work/DEV-LOOP-CHECKLIST.md" \
      "default.*1.*3|default.*3.*1|default.*mismatch|help.*default" \
      "Checklist mentions default mismatch (Step 2)"

    echo "  [Step 3 findings]"
    assert_file_contains "$work/DEV-LOOP-CHECKLIST.md" \
      "times.*(guard|<=.*0|negative|zero)|no.*(guard|validation).*times" \
      "Checklist mentions times<=0 guard (Step 3a)"
    assert_file_contains "$work/DEV-LOOP-CHECKLIST.md" \
      "encode.*discard|discard.*encode|\.encode\(.*unused|result.*encode.*lost" \
      "Checklist mentions encode result discarded (Step 3b)"
    assert_file_contains "$work/DEV-LOOP-CHECKLIST.md" \
      "unused.*import|import os.*unused|import os.*never" \
      "Checklist mentions unused import (Step 3c)"

    echo "  [Step 3E findings (adversarial)]"
    assert_file_contains "$work/DEV-LOOP-CHECKLIST.md" \
      "empty.*name.*Hello|Hello, !|name.*empty.*greeting|empty.*name.*broken" \
      "Checklist mentions empty name issue (Step 3E)"

    echo "  [Step 4 build result]"
    assert_file_contains "$work/DEV-LOOP-CHECKLIST.md" \
      "[Pp]ass(ed|ing)|tests.*green|0 fail|all.*pass" \
      "Checklist records passing build (Step 4)"

    echo "  [fixture not destroyed]"
    assert_file_contains "$FIXTURE_DIR/src/greeter.py" \
      "import os" "Real fixture still has unused import (untouched)"
    if [[ ! -f "$FIXTURE_DIR/DEV-LOOP-CHECKLIST.md" ]]; then
      pass "Real fixture has no checklist (untouched)"
    else
      fail "Real fixture was modified — DEV-LOOP-CHECKLIST.md found in $FIXTURE_DIR"
    fi

    teardown_work_dir
    echo ""
    echo "  [teardown] Temp dir cleaned up."
  else
    echo "  [skip] No checklist found in temp dir — agent hasn't run yet."
    echo "         Temp dir preserved at: $work"
    pass "Integration setup (agent run pending)"
  fi
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
