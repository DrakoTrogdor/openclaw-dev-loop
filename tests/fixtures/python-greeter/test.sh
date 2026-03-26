#!/usr/bin/env bash
# test.sh — Structural assertions for the python-greeter fixture.
# Sourced by run-tests.sh. Uses assert_* helpers defined there.
# FIXTURE_DIR is set by the caller.

run_fixture_structural() {
  echo ""
  echo "  [python-greeter: required files]"
  assert_file_exists "$FIXTURE_DIR/README.md"              "README.md"
  assert_file_exists "$FIXTURE_DIR/STATUS.md"              "STATUS.md"
  assert_file_exists "$FIXTURE_DIR/build.sh"               "build.sh"
  assert_file_exists "$FIXTURE_DIR/src/greeter.py"         "src/greeter.py"
  assert_file_exists "$FIXTURE_DIR/tests/test_greeter.py"  "tests/test_greeter.py"

  echo ""
  echo "  [python-greeter: README documents build command]"
  assert_file_contains "$FIXTURE_DIR/README.md" "./build.sh" \
    "README.md references build.sh"

  echo ""
  echo "  [python-greeter: STATUS.md has known issues]"
  assert_file_contains "$FIXTURE_DIR/STATUS.md" "Known Issues" \
    "STATUS.md has Known Issues section"
  assert_file_contains "$FIXTURE_DIR/STATUS.md" "times 0" \
    "STATUS.md documents --times 0 bug"

  echo ""
  echo "  [python-greeter: F1 — Step 1 (README/code mismatch)]"
  assert_file_contains "$FIXTURE_DIR/README.md" "\-\-reverse" \
    "README documents --reverse flag"
  assert_file_not_contains "$FIXTURE_DIR/src/greeter.py" '"--reverse"' \
    "--reverse not implemented in code"

  echo ""
  echo "  [python-greeter: F2 — Step 2 (help text mismatch)]"
  assert_file_contains "$FIXTURE_DIR/src/greeter.py" 'default=3' \
    "actual default is 3"
  assert_file_contains "$FIXTURE_DIR/src/greeter.py" 'default: 1' \
    "help text claims default is 1"

  echo ""
  echo "  [python-greeter: F3a — Step 3 (no guard on times <= 0)]"
  assert_file_not_contains "$FIXTURE_DIR/src/greeter.py" \
    '^\s*(if|elif|while).*times\s*(<=\s*0|<\s*1|==\s*0)|raise.*times|ValueError.*times' \
    "no guard against times <= 0"

  echo ""
  echo "  [python-greeter: F3b — Step 3 (silently discarded encode)]"
  assert_file_contains "$FIXTURE_DIR/src/greeter.py" 'args.name.encode' \
    "encode() call present (result discarded)"

  echo ""
  echo "  [python-greeter: F3c — Step 3 (unused import)]"
  assert_file_contains "$FIXTURE_DIR/src/greeter.py" 'import os' \
    "unused import os present"

  echo ""
  echo "  [python-greeter: F3E — Step 3E (empty name → broken output)]"
  assert_file_not_contains "$FIXTURE_DIR/src/greeter.py" \
    'if not name|if len\(name\) == 0|if name ==' \
    "no validation on empty name in build_greeting"
  assert_file_contains "$FIXTURE_DIR/src/greeter.py" \
    'f"Hello, \{name\}!"' \
    "f-string greeting present (breaks on empty name)"

  echo ""
  echo "  [python-greeter: build passes]"
  assert_build_passes "$FIXTURE_DIR" "build.sh --no-commit"
}
