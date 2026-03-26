#!/usr/bin/env bash
# test.sh — Structural assertions for the rust-counter fixture.
# Sourced by run-tests.sh. Uses assert_* helpers defined there.
# FIXTURE_DIR is set by the caller.

run_fixture_structural() {
  echo ""
  echo "  [rust-counter: required files]"
  assert_file_exists "$FIXTURE_DIR/README.md"       "README.md"
  assert_file_exists "$FIXTURE_DIR/STATUS.md"       "STATUS.md"
  assert_file_exists "$FIXTURE_DIR/build.sh"        "build.sh"
  assert_file_exists "$FIXTURE_DIR/Cargo.toml"      "Cargo.toml"
  assert_file_exists "$FIXTURE_DIR/src/main.rs"     "src/main.rs"

  echo ""
  echo "  [rust-counter: README documents build command]"
  assert_file_contains "$FIXTURE_DIR/README.md" "./build.sh" \
    "README.md references build.sh"

  echo ""
  echo "  [rust-counter: STATUS.md has known issues]"
  assert_file_contains "$FIXTURE_DIR/STATUS.md" "Known Issues" \
    "STATUS.md has Known Issues section"
  assert_file_contains "$FIXTURE_DIR/STATUS.md" "word" \
    "STATUS.md documents empty --word bug"

  echo ""
  echo "  [rust-counter: F1 — Step 1 (README/code mismatch)]"
  assert_file_contains "$FIXTURE_DIR/README.md" "\-\-ignore-case" \
    "README documents --ignore-case flag"
  # Check that no actual code (non-comment lines) implements case-insensitive matching
  if grep -Ev '^\s*//' "$FIXTURE_DIR/src/main.rs" | grep -Eq 'to_lowercase|to_ascii_lowercase|case_fold'; then
    fail "--ignore-case is implemented in code"
  else
    pass "--ignore-case not implemented in code"
  fi

  echo ""
  echo "  [rust-counter: F2 — Step 2 (help text mismatch)]"
  assert_file_contains "$FIXTURE_DIR/src/main.rs" 'Counts lines containing' \
    "help says 'counts lines containing'"
  # grep -F for fixed string (dots are literal in Rust, not regex)
  if grep -Fq '.matches(word).count()' "$FIXTURE_DIR/src/main.rs"; then
    pass "code actually counts occurrences (not lines)"
  else
    fail "code does not use .matches(word).count() — expected occurrence counting"
  fi

  echo ""
  echo "  [rust-counter: F3a — Step 3 (empty word panics)]"
  assert_file_not_contains "$FIXTURE_DIR/src/main.rs" \
    'word.is_empty|word.len\(\) == 0|if word ==' \
    "no guard against empty --word"

  echo ""
  echo "  [rust-counter: F3b — Step 3 (unwrap on line read)]"
  assert_file_contains "$FIXTURE_DIR/src/main.rs" 'line.unwrap()' \
    ".unwrap() on line read (panics on invalid UTF-8)"

  echo ""
  echo "  [rust-counter: F3c — Step 3 (unused import)]"
  assert_file_contains "$FIXTURE_DIR/src/main.rs" 'use std::collections::HashMap' \
    "unused HashMap import present"

  echo ""
  echo "  [rust-counter: F3E — Step 3E (per-line counting misses cross-boundary words)]"
  assert_file_contains "$FIXTURE_DIR/src/main.rs" 'for line in reader.lines()' \
    "per-line iteration present (misses words spanning line boundaries)"
  assert_file_not_contains "$FIXTURE_DIR/src/main.rs" \
    'read_to_string|BufReader.*read|whole.*input|entire.*input' \
    "no whole-input reading (only line-by-line)"

  echo ""
  echo "  [rust-counter: build passes]"
  assert_build_passes "$FIXTURE_DIR" "build.sh --no-commit"
}
