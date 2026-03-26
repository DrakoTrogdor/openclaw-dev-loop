# DEV-LOOP-CHECKLIST — Pass 3 (All Fixtures)

## Project Commands
- **Build:** `./build.sh --msg "<description>"`
- **Test:** `./tests/run-tests.sh` (structural checks across all fixtures)
- **Commit:** `./build.sh --msg "<description>"`
- **Lint:** n/a

## Known issues
- No STATUS.md at project root

## Step 1 — Docs ↔ Code Sync (Pass 3)

### README.md — Project structure diagram
- [x] Finding: `test.sh` missing from all 3 fixture entries in the tree diagram → Fixed: added `test.sh` line to python-greeter, rust-counter, and openclaw-skill in the structure tree
- [x] Finding: `run-tests.sh` description didn't mention auto-discovery → Fixed: added "(auto-discovers fixtures via test.sh)" annotation

### README.md — Planted flaws table
- [x] Finding: Only python-greeter flaws (F1–F3E) documented; rust-counter and openclaw-skill flaws entirely missing → Fixed: added two new subsections "Planted flaws — rust-counter" (6 flaws) and "Planted flaws — openclaw-skill" (6 flaws), each with full ID/Step/Flaw/Description table matching the actual planted flaws in code

### README.md — Test harness section
- [x] Finding: Structural test description was python-greeter-specific (mentioned `--times 0`, `F1–F4`) → Fixed: rewrote to describe generic per-fixture checks and skill-level checks, documented auto-discovery mechanism via `test.sh`
- [x] Finding: Missing mention of YAML frontmatter validation in structural test description → Fixed: added "SKILL.md YAML frontmatter is valid (parseable by yaml.safe_load)" to skill-level checks list

### README.md — Cross-references
- [x] Finding: "What lives where" table referenced `tests/fixture/` (singular) → Fixed: corrected to `tests/fixtures/` (plural) with updated description
- [x] Finding: "Test Fixture" heading was singular → Fixed: changed to "Test Fixtures" with multi-fixture intro paragraph
- [x] Finding: "Adding new planted flaws" instructions were python-greeter-specific (`tests/fixture/src/greeter.py`) → Fixed: generalized to "the appropriate fixture's source file" and updated assertion step to reference `test.sh`

### README.md — Self-improvement section
- [x] Finding: "against the fixture" (singular) → Fixed: "against each fixture"
- [x] Finding: "F1–F3c but missing F4" used old F4 ID → Fixed: "F1–F3c but missing F3E across fixtures"

### README.md — Flaw ID consistency
- [x] Finding: Original table used "F4" for the adversarial flaw; now consistently uses "F3E" across all 3 fixture tables to match the step naming (Step 3E)

### SKILL.md — Matches DEV-LOOP.md
- [x] No issues found: SKILL.md Quick Start, Key Rules, Sub-Agent Mode, and References all accurately reflect the protocol in references/DEV-LOOP.md

### SKILL.md — YAML frontmatter validity
- [x] No issues found: frontmatter has `name: dev-loop` and `description:` with properly double-quoted value (colon inside quotes is valid YAML)

### DEV-LOOP.md — YAML frontmatter validation in Step 1
- [x] No issues found: Step 1 checklist includes "Structured metadata | YAML/TOML/JSON frontmatter, config files — parseable? Values with special characters (colons, quotes) properly quoted?"

### DEV-LOOP.md — Step accuracy
- [x] No issues found: All steps (1, 2, 3, 3E, 4, 5, 6) present, references to README.md and STATUS.md present, context management rules intact

### Cross-file reference integrity
- [x] SKILL.md → `references/DEV-LOOP.md`: valid (file exists)
- [x] README.md → `SKILL.md`: valid (file exists)
- [x] README.md → `references/DEV-LOOP.md`: valid (file exists)
- [x] README.md → `tests/run-tests.sh`: valid (file exists)
- [x] README.md → `tests/fixtures/`: valid (directory exists, contains 3 fixtures)
- [x] README.md → Anthropic blog post: external link (not verifiable offline, but correctly formatted)
- [x] README.md → `/workspace/research/harness-design-long-running-agents.md`: external path, not part of this repo

### Test suite validation
- [x] All structural checks pass after edits (confirmed via `./tests/run-tests.sh -v`)

## Step 2 — User-Facing Text ↔ Code Sync (Pass 3)

### build.sh
- [x] `--msg` help text matches behavior (commit body appended to timestamp title) ✓
- [x] `--skills-dir` help text matches auto-detection order (sibling → ~/.openclaw) ✓
- [x] `--no-commit` help text matches behavior (tests + sync, skip git) ✓
- [x] `-h, --help` works ✓
- [x] Commit message format description matches code ✓
- [x] Error messages for `--msg`, `--skills-dir`, system-dir guard all accurate ✓

### tests/run-tests.sh
- [x] **Fixed**: Header comment said "Verify **the fixture**" (singular) — updated to "every fixture in fixtures/" to match multi-fixture loop
- [x] **Fixed**: Header said "Runs against the real fixture (read-only)" (singular) — updated to "Loops over all fixtures (read-only)"
- [x] **Fixed**: Integration mode header comment said "Copies the fixture" — updated to "Copies the default fixture (python-greeter)"
- [x] **Fixed**: `--mode` help text didn't describe structural vs integration behavior — added sub-descriptions ("structural: loops over every fixture in fixtures/", "integration: runs structural, then sets up a temp copy of the default fixture for agent testing")
- [x] **Fixed**: `setup_work_dir` comment said "isolated copy of the fixture" — updated to "isolated copy of the default fixture (python-greeter)"
- [x] **Fixed**: `run_integration` comment said "temp copy of the fixture" — updated to "temp copy of the default fixture"
- [x] `--work-dir` help text accurate (re-use existing temp dir for integration assertions) ✓
- [x] Error messages for `--mode`, `--work-dir` are accurate ✓
- [x] No `--fixture` flag exists and none is needed (structural auto-discovers all fixtures) ✓
- [x] Inline comments for the structural loop (`# Test each fixture`) match the `for fixture_dir in "$FIXTURES_DIR"/*/` code ✓
- [x] All structural tests still pass after edits ✓

## Step 3 — Phase A (Pass 3)

### run-tests.sh — file-by-file review
- [x] Finding: `FIXTURE_DIR` leaks across the structural→integration boundary. The `for fixture_dir` loop in `run_structural()` reassigns the global `FIXTURE_DIR` on each iteration. After the loop, `FIXTURE_DIR` points to the last fixture alphabetically (rust-counter), not the default (python-greeter). In integration mode (`run_structural` then `run_integration`), this causes `setup_work_dir` to copy the wrong fixture, the display message to show the wrong path, and the "fixture not destroyed" assertions to check `rust-counter/src/greeter.py` (which doesn't exist) → Fixed: save `FIXTURE_DIR` to `saved_fixture_dir` before the loop, restore it after the loop completes
- [x] Loop variable scoping: `fixture_name` and `test_file` are declared `local` inside `run_structural()` — correctly scoped to the function, no leakage between iterations ✓
- [x] `unset -f run_fixture_structural` after each iteration prevents function definition leakage between fixtures ✓
- [x] Pass/fail counting: `PASS` and `FAIL` are globals incremented by `pass()` and `fail()`, accumulating across all fixtures and skill-level tests — correct, single aggregate reported at the end ✓
- [x] Sourcing pattern risk: `source "$test_file"` executes arbitrary code with the test runner's privileges. Acceptable for our own fixtures; noted as a trust-boundary consideration if fixtures were ever contributed by untrusted parties ✓
- [x] `set -euo pipefail` present — good error handling baseline ✓
- [x] Trap registration in `setup_work_dir` correctly limited to integration mode; handles EXIT/INT/TERM ✓
- [x] `find ... -exec rm -rf {} + 2>/dev/null || true` correctly suppresses errors from already-deleted parent dirs ✓
- [x] Python YAML validation: `split('---')[1]` would raise IndexError on missing frontmatter — correct fail behavior ✓

### build.sh — file-by-file review
- [x] System-dir guard covers `/etc`, `/usr`, `/bin`, `/sbin`, `/sys`, `/proc` — reasonable defense-in-depth (not exhaustive, but adequate for its purpose) ✓
- [x] `rm -rf "$SKILLS_DIR"` before copy is protected by prior validation and the system-dir guard — no unguarded destructive path ✓
- [x] No `--force` on `git push` — safe default ✓
- [x] Unpushed commit detection correctly verifies `origin/$BRANCH` exists before `git log` ✓
- [x] `SKILLS_DIR_OVERRIDE` used only for display message — minor extra variable but improves readability vs inline conditionals ✓
- [x] No dead code, unused variables, or bash anti-patterns found ✓
- [x] `set -euo pipefail` present ✓

### references/DEV-LOOP.md — file-by-file review
- [x] All 6 steps plus 3E present and correctly ordered ✓
- [x] Context management rules are sound (per-step file-loading guidance, no "load everything") ✓
- [x] Sub-agent mode instructions clear and consistent with SKILL.md ✓
- [x] Toolchain fallback table covers Rust, Node, Python, Go — reasonable coverage ✓
- [x] No dead sections, stale references, or contradictions with SKILL.md ✓

### SKILL.md — file-by-file review
- [x] YAML frontmatter valid (`name: dev-loop`, `description:` with quoted value) ✓
- [x] Quick Start steps align with DEV-LOOP.md protocol order ✓
- [x] Key Rules accurately summarize full protocol constraints ✓
- [x] Sub-Agent Mode section consistent with DEV-LOOP.md ✓
- [x] References section points to correct file ✓

### Fixture test.sh files — assertion pattern review (read-only, no modifications)

**python-greeter/test.sh:**
- [x] F1 assertion: checks `--reverse` in README + not in code — correct ✓
- [x] F2 assertion: checks `default=3` in code + `default: 1` in help — correct ✓
- [x] F3a assertion: regex correctly tests absence of guard patterns — correct ✓
- [x] F3b assertion: checks `args.name.encode` presence — correct ✓
- [x] F3c assertion: checks `import os` presence — correct ✓
- [x] F3E assertion: checks no empty-name validation + f-string presence — correct ✓
- [x] `assert_build_passes` included — correct ✓

**rust-counter/test.sh:**
- [x] F1 assertion: two-stage grep pipeline (filter comments, then check for case-folding code) — more robust than single regex ✓
- [x] F2 assertion: checks help text vs actual behavior (`matches().count()` vs "counts lines") — correct ✓
- [x] F3a assertion: checks absence of `is_empty`/`len() == 0` guards — correct ✓
- [x] F3b assertion: checks `line.unwrap()` presence — correct ✓
- [x] F3c assertion: checks unused `HashMap` import — correct ✓
- [x] F3E assertion: checks per-line iteration + absence of whole-input reading — correct ✓
- [x] `assert_build_passes` included — correct ✓

**openclaw-skill/test.sh:**
- [x] F1 assertion: checks "csv" in SKILL.md + absence of `csv)` case in script — correct ✓
- [x] F2 assertion: checks "search by date range" in help + absence of date filtering implementation — correct ✓
- [x] F3a assertion: checks absence of URL validation patterns — correct ✓
- [x] F3b assertion: checks `grep -v "$url"` with raw variable — correct (matches the regex metachar vulnerability) ✓
- [x] F3c assertion: checks `BACKUP_DIR` defined but never referenced — correct ✓
- [x] F3E assertion: uses inline `if/then/else` with `grep -Eq` instead of `assert_file_not_contains` — style inconsistency vs other fixtures (functional, not a bug) ✓
- [x] `assert_build_passes` included — correct ✓

## Step 3 — Phase B (Pass 3)

### Cross-file issues
- [x] No cross-file issues logged during Phase A — all findings were self-contained
- [x] The FIXTURE_DIR leakage (fixed in Phase A) was the only cross-boundary issue: it spanned the structural loop → integration test boundary within a single file (run-tests.sh), not across multiple files
- [x] Interface consistency between run-tests.sh and fixture test.sh files: all fixtures correctly define `run_fixture_structural()`, use the `assert_*` helpers from the parent, and rely on `FIXTURE_DIR` being set by the caller — contract is clean ✓
- [x] build.sh → run-tests.sh interface: `build.sh` invokes `bash "$REPO_DIR/tests/run-tests.sh"` with no arguments (structural mode default) — consistent with run-tests.sh defaults ✓
- [x] SKILL.md → DEV-LOOP.md cross-references: SKILL.md's Key Rules and Quick Start accurately reflect DEV-LOOP.md content, no drift ✓

### Test suite validation
- [x] All structural checks pass after FIXTURE_DIR fix (confirmed via `./tests/run-tests.sh -v`)

## Step 3E — Adversarial Evaluation (Pass 3)

This pass focuses on the multi-fixture refactor specifically: edge cases in the fixture loop, cross-fixture consistency, security of the source-based plugin model, integration mode gaps, protocol-level coverage gaps, and the "71 checks" claim.

### Finding 1: Empty fixtures directory causes glob literal iteration (run-tests.sh:148)

**Severity:** Low (defensive edge case)
**File:** `tests/run-tests.sh`, line 148

The glob `"$FIXTURES_DIR"/*/` does not expand when the directory is empty (or doesn't exist). Without `shopt -s nullglob`, bash iterates the literal string `<path>/*/`, causing `basename` to return `*`, `test_file` to be `<path>/*/test.sh`, and the `-f` check to fail with a confusing `*: missing test.sh` error. The test suite doesn't set `nullglob` anywhere.

**Impact:** Confusing error output if someone runs the tests with no fixtures present. Not a correctness bug in normal operation (3 fixtures always exist), but violates defensive programming expectations for a test harness.

### Finding 2: Sourced test.sh can redefine helper functions — no protection or restore (run-tests.sh:163)

**Severity:** Medium (test integrity)
**File:** `tests/run-tests.sh`, line 163 (`source "$test_file"`)

When a fixture's `test.sh` is sourced, it executes in the runner's shell. A malicious or buggy `test.sh` can redefine `pass()`, `fail()`, `assert_file_exists()`, `assert_file_contains()`, `assert_file_not_contains()`, or `assert_build_passes()`. The runner only calls `unset -f run_fixture_structural` after each fixture — it does NOT save/restore the helper functions.

**Concrete attack:** A test.sh that redefines `pass()` to always increment `PASS` without checking anything, or redefines `fail()` as a no-op, would cause all subsequent fixtures' assertions to silently false-pass. The redefinition persists across fixture iterations because `source` runs in the same shell.

**Verified:** Tested with `source <(echo 'pass() { echo "HIJACKED"; }; run_fixture_structural() { pass "ok"; }')` — the hijacked `pass()` persisted for all subsequent calls.

### Finding 3: Sourced test.sh calling `exit` silently kills the entire test runner (run-tests.sh:163)

**Severity:** Medium (test integrity)
**File:** `tests/run-tests.sh`, line 163 (`source "$test_file"`)

Because `source` runs in the current shell (not a subshell), a `test.sh` that calls `exit 0` (e.g., in an early-return guard, error handler, or cleanup path) will terminate the entire test runner process. With `exit 0`, this would appear as a successful test run even if most fixtures were never tested.

**Verified:** `source <(echo "exit 0")` terminates the parent process immediately.

**Note:** The current fixture test.sh files don't call `exit`, so this is not triggered today — but it's a latent trap for anyone adding a new fixture.

### Finding 4: Sourced test.sh can modify global variables beyond FIXTURE_DIR (run-tests.sh:163)

**Severity:** Low-Medium (test integrity)
**File:** `tests/run-tests.sh`, line 163

A sourced test.sh can modify any global variable: `PASS`, `FAIL`, `FIXTURES_DIR`, `TESTS_DIR`, `WORK_DIR`, `MODE`, `VERBOSE`, etc. Only `FIXTURE_DIR` has save/restore logic. The `saved_fixture_dir` fix from Pass 2 protects `FIXTURE_DIR` but not any other global.

For example, a test.sh that sets `VERBOSE=false` would suppress pass output for all subsequent fixtures. A test.sh that sets `FAIL=0` would reset the failure counter.

### Finding 5: "71 checks" in README and DEV-LOOP-CHECKLIST.md is a hardcoded number that will drift (README.md:110, DEV-LOOP-CHECKLIST.md:5)

**Severity:** Low (documentation accuracy)
**Files:** `README.md` line 110, `DEV-LOOP-CHECKLIST.md` line 5

The claim "Currently runs **71 checks** across 3 fixtures" is hardcoded text. Adding a new fixture or adding assertions to an existing fixture's test.sh will change the count without updating these references. There is no mechanism to compute or validate this number automatically.

The "71" appears in 5 places across 2 files. Each is a manual maintenance burden. A comment like "run `./tests/run-tests.sh -v 2>&1 | grep -c PASS` to verify" would help, or the README could say "70+" instead of an exact number.

### Finding 6: Integration mode is hardcoded to python-greeter only — partially documented but assertions are brittle (run-tests.sh:19, 284)

**Severity:** Low-Medium (design limitation + documentation gap)
**File:** `tests/run-tests.sh`, lines 19, 228-292

Integration mode:
- Copies only `python-greeter` (hardcoded at line 19: `FIXTURE_DIR="$FIXTURES_DIR/python-greeter"`)
- All integration assertions are python-greeter-specific (checks for `--reverse`, `--times`, `encode`, `import os`, `greeter.py`)
- The "fixture not destroyed" check at line 284 hardcodes `$FIXTURE_DIR/src/greeter.py` — a python-greeter-specific path

Comments were updated in Pass 2 to say "default fixture (python-greeter)" — this is adequate for `setup_work_dir` and `run_integration` comments. However, the README's integration test section (lines 128-146) doesn't explicitly state that integration mode only tests python-greeter. It says "Create a temp copy of the fixture" without specifying which one.

If someone reads the README and expects integration tests to cover rust-counter or openclaw-skill, they'll be misled.

### Finding 7: DEV-LOOP.md Step 3 checklist doesn't cover regex escaping or comment-vs-code distinction (references/DEV-LOOP.md)

**Severity:** Medium (protocol gap)
**File:** `references/DEV-LOOP.md`, Step 3 "What to check" section

The Step 3 checklist covers Security, Resource Management, Correctness, and Code Quality. However, it does not mention:

1. **Regex/pattern safety:** Using user input or unescaped variables in regex patterns (the `grep -v "$url"` flaw in openclaw-skill's F3b). The "Input validation" bullet under Security is generic ("untrusted data checked before use") but doesn't specifically call out regex metacharacter injection, which is a distinct and common vulnerability class in shell scripts.

2. **Comment-vs-code distinction:** The rust-counter F1 assertion uses a two-stage pipeline (`grep -Ev '^\s*//'` then `grep -Eq`) to filter comments before checking for code patterns. This technique is needed because `grep` on a whole file can't distinguish comments from executable code. The Step 3 checklist doesn't guide reviewers to consider whether a pattern match is in active code vs. a comment.

These are exactly the types of bugs the test fixtures are designed to catch, yet the protocol's review checklist doesn't teach the agent to look for them.

### Finding 8: Step 3E evaluator prompt lacks cross-function/cross-module interaction guidance (references/DEV-LOOP.md)

**Severity:** Medium (protocol gap)
**File:** `references/DEV-LOOP.md`, Step 3E evaluator system prompt

The evaluator prompt asks per-file questions ("For each file, ask: ..."). It does not include any bullet about:

- **Cross-function interactions within the same file** — e.g., function A transforms data one way, function B assumes a different format. The openclaw-skill F3E flaw (tag case mismatch between `save_bookmark` lowercasing tags and `search_bookmarks` not lowercasing the search term) is exactly this pattern.
- **Data format assumptions across function boundaries** — does function B's input contract match function A's output contract?

The prompt says "What assumptions does this code make that aren't validated?" which is close but too generic. A specific bullet like "Do functions that produce and consume the same data agree on its format (case, encoding, delimiters)?" would make the evaluator significantly more likely to catch F3E-class bugs.

The "What the evaluator typically catches" section at the bottom does mention "Assumptions about input that are never checked" but doesn't specifically call out cross-function format mismatches as a pattern to look for.

### Finding 9: openclaw-skill F3E assertion style inconsistency — uses raw if/grep instead of assert_* helpers (tests/fixtures/openclaw-skill/test.sh:72-78)

**Severity:** Low (consistency/maintainability)
**File:** `tests/fixtures/openclaw-skill/test.sh`, lines 72-78

The F3E assertion in openclaw-skill uses inline `if grep -Eq ... then fail ... else pass` instead of the `assert_file_not_contains` helper used by all other negative-pattern assertions across all three fixtures. Previous passes noted this as "style inconsistency vs other fixtures (functional, not a bug)" and moved on.

However, it's worth noting that this pattern bypasses the file-existence check that `assert_file_not_contains` performs (the `if [[ ! -f "$file" ]]` guard). If `scripts/bookmarks.sh` were missing, the `assert_*` calls would report `file missing`, but this raw grep would silently fail the grep (exit code 2 for missing file → enters `else` → calls `pass` — a false pass).

### Finding 10: `assert_build_passes` label parameter is misleading in fixture test.sh files (all 3 fixtures)

**Severity:** Very Low (cosmetic)
**Files:** All three `test.sh` files

Each fixture calls `assert_build_passes "$FIXTURE_DIR" "build.sh --no-commit"`. The second argument is the `label` — used in pass/fail output messages. But `assert_build_passes` hardcodes `--no-commit` in the actual command (`bash "$dir/build.sh" --no-commit`). The label happens to match the command, but if someone changed the function to not pass `--no-commit`, the label would still say it. The label is informational, not functional, so this is cosmetic.

### Finding 11: `set -euo pipefail` + `source` creates a fragile interaction (run-tests.sh:15+163)

**Severity:** Low-Medium (correctness)
**File:** `tests/run-tests.sh`

The runner uses `set -euo pipefail`. When a sourced test.sh is loaded, it inherits these settings. If a test.sh file (or the `run_fixture_structural` function it defines) references an unset variable, the entire runner terminates due to `set -u`. Similarly, any command that returns non-zero without explicit error handling triggers `set -e` and kills the runner.

The current test.sh files are clean, but this means a new fixture test.sh must be written with awareness of `set -euo pipefail` — an undocumented contract. There's no comment in run-tests.sh or the README's "Adding new planted flaws" section warning about this.

### Finding 12: No validation that FIXTURES_DIR exists or contains directories (run-tests.sh:18)

**Severity:** Very Low (defensive edge case)
**File:** `tests/run-tests.sh`, line 18

`FIXTURES_DIR="$TESTS_DIR/fixtures"` is set unconditionally. If the `fixtures/` directory doesn't exist:
- The glob `"$FIXTURES_DIR"/*/` won't match anything (same as empty dir, Finding 1)
- No error message indicates the fixtures directory is missing
- The test suite would report 12 passes (skill-level checks only) and 0 failures — a misleading "all green"

### Summary of Pass 3 Findings

| # | Severity | Area | Description |
|---|----------|------|-------------|
| 1 | Low | run-tests.sh | Empty fixtures dir → confusing glob literal iteration (no `nullglob`) |
| 2 | Medium | run-tests.sh | Sourced test.sh can redefine helper functions (`pass`, `fail`, `assert_*`) — no restore |
| 3 | Medium | run-tests.sh | Sourced test.sh calling `exit` kills entire test runner silently |
| 4 | Low-Med | run-tests.sh | Sourced test.sh can modify any global variable (PASS, FAIL, MODE, etc.) |
| 5 | Low | README + checklist | "71 checks" hardcoded in 5 places; will drift when fixtures change |
| 6 | Low-Med | run-tests.sh + README | Integration mode hardcoded to python-greeter; README doesn't state this clearly |
| 7 | Medium | DEV-LOOP.md | Step 3 checklist missing regex escaping and comment-vs-code matching guidance |
| 8 | Medium | DEV-LOOP.md | Step 3E evaluator prompt missing cross-function interaction bullets |
| 9 | Low | openclaw-skill/test.sh | F3E uses raw if/grep instead of assert_* helpers; bypasses file-existence guard |
| 10 | Very Low | All test.sh | `assert_build_passes` label is informational duplicate of hardcoded command |
| 11 | Low-Med | run-tests.sh | `set -euo pipefail` + `source` contract undocumented for new fixture authors |
| 12 | Very Low | run-tests.sh | No validation that FIXTURES_DIR exists; missing dir → false "all green" with 12 skill-level passes only |

## Step 3E — Fixes (Pass 3)

- [x] **Findings 2, 3, 4 (helper hijacking + exit kills runner + global var exposure):** Replaced `source "$test_file"` + direct execution with **subshell isolation**. Each fixture's `test.sh` now runs in a `$( ... )` subshell with locally re-declared helper functions and private `_SUB_PASS`/`_SUB_FAIL` counters. Results are communicated back via a `__RESULT__:<pass>:<fail>` sentinel line parsed by the parent. This prevents: (a) helper function redefinition persisting across fixtures, (b) `exit` in test.sh killing the runner (subshell exits, parent continues), (c) global variable mutation (PASS, FAIL, VERBOSE, MODE, etc. are isolated). The `|| true` on the subshell catches `set -e` exits so the runner always proceeds to the next fixture. (`tests/run-tests.sh`)
- [x] **Finding 7 (regex escaping guidance):** Added bullet to DEV-LOOP.md Step 3 → "What to check → Correctness" about regex/pattern injection — when user input or variable data is passed to `grep`, `sed`, `[[ =~ ]]`, or other regex engines without escaping metacharacters. (`references/DEV-LOOP.md`)
- [x] **Finding 8 (cross-function interaction in evaluator prompt):** Added bullet to Step 3E evaluator system prompt asking whether functions that produce and consume the same data agree on its format (case, encoding, delimiters, quoting), with a concrete example (lowercased tags vs. original-case search). (`references/DEV-LOOP.md`)
- [x] **Finding 5 ("71 checks" hardcoded):** Removed hardcoded count from README.md (now says "total check count scales with the number of fixtures and assertions") and from DEV-LOOP-CHECKLIST.md header and historical entries (now say "all structural checks/tests" instead of "71"). (`README.md`, `DEV-LOOP-CHECKLIST.md`)
- [x] **Finding 1 (missing nullglob):** Added `shopt -s nullglob` before collecting fixture directories into an array, then `shopt -u nullglob` after. If the array is empty (no fixtures found), a warning is printed and a failure is recorded instead of silently iterating nothing or a literal glob string. (`tests/run-tests.sh`)
- [x] **Finding 11 (undocumented set -euo pipefail contract):** Added a block comment at the top of the fixture loop explaining that test.sh files run under `set -euo pipefail` inherited from the parent shell, and that new fixtures must be written with that constraint in mind. Now that subshell isolation is in place, a `set -e` abort terminates the subshell (not the runner) and produces a "no results returned" failure. (`tests/run-tests.sh`)
- [x] All structural tests pass after fixes (confirmed via `./tests/run-tests.sh -v` — 71 passed, 0 failed)

## Step 6 — Re-sync Docs & Help Text (Pass 3)

### Checks performed

1. **README.md vs code changes:**
   - ✅ Auto-discovery documented (line 20 project tree annotation, line 110 test harness description, line 154 fixture section)
   - ✅ Dynamic test count — no hardcoded counts remain; README says "total check count scales with the number of fixtures and assertions"
   - [x] **Finding: subshell isolation not documented in README.** Pass 3 added subshell isolation for fixture tests in `run-tests.sh`, but README's test harness section didn't mention it. → Fixed: added sentence about subshell isolation and its failure-containment behavior. (`README.md`)

2. **`run-tests.sh --help` accuracy:**
   - ✅ All flags (`--mode`, `--work-dir`, `-v`/`--verbose`, `-h`/`--help`) match actual argument parsing
   - ✅ Mode descriptions (structural, integration) accurate
   - ✅ No hardcoded counts in help text

3. **`build.sh --help` accuracy:**
   - ✅ All flags (`--msg`, `--skills-dir`, `--no-commit`, `-h`/`--help`) match actual argument parsing
   - ✅ Auto-detection order matches code (sibling → `~/.openclaw/skills/dev-loop`)
   - ✅ System path rejection (`/etc`, `/usr`, etc.) and empty-string rejection documented in README and implemented in code

4. **SKILL.md vs DEV-LOOP.md sync:**
   - ✅ SKILL.md correctly points to `references/DEV-LOOP.md` as the full protocol
   - ✅ New DEV-LOOP.md bullets (regex escaping in Step 3, cross-function interaction in Step 3E) are implementation details that belong in DEV-LOOP.md, not SKILL.md — architecture is correct
   - ✅ SKILL.md key rules and step summary remain consistent with DEV-LOOP.md

5. **Hardcoded count audit:**
   - ✅ No hardcoded "71", "31", or "32" in README.md, SKILL.md, DEV-LOOP.md, run-tests.sh, or build.sh
   - ✅ Only references are in DEV-LOOP-CHECKLIST.md historical entries (expected — these are audit trail records)

### Test verification

- All 71 structural tests pass (confirmed before and after README edit)

## Summary (Pass 3)
- **Step 1:** README expanded with all 3 fixtures' planted flaws (18 total), project structure updated, test harness docs rewritten for multi-fixture, flaw IDs standardized
- **Step 2:** 6 stale single-fixture references fixed in run-tests.sh comments and help text
- **Step 3 Phase A:** 1 bug fixed (FIXTURE_DIR leakage between fixture loop iterations)
- **Step 3E Adversarial:** 12 findings, 7 fixed (subshell isolation, nullglob, regex escaping guidance, cross-function evaluator bullet, hardcoded counts removed, fixture contract documented)
- **Step 4:** Build green, all structural checks passed across 3 fixtures
- **Step 6:** 1 re-sync fix (README documents subshell isolation)
- **Total:** 15+ fixes across 4 files
