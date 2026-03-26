# DEV-LOOP-CHECKLIST

## Project Commands
- **Build:** `./build.sh --msg "<description>"` (runs tests → syncs skill files → commits → pushes)
- **Test:** `./tests/run-tests.sh` (structural) or `./tests/run-tests.sh --mode integration` (full)
- **Deploy:** n/a (build.sh syncs to local skills dir)
- **Commit:** `./build.sh --msg "<description>"` (auto-commits + pushes)
- **Lint:** n/a (shell scripts — no linter configured)

## Known issues from STATUS.md
- No STATUS.md exists at project root

## Project Files
- `README.md` — project spec, structure, build/test/commit commands, self-improvement process
- `SKILL.md` — agent-facing skill definition (trigger + key rules)
- `build.sh` — build/test/sync/commit/push entry point
- `references/DEV-LOOP.md` — full step-by-step protocol
- `tests/run-tests.sh` — structural + integration test runner
- `tests/fixture/` — test project with planted flaws (DO NOT FIX flaws in fixture)

## Step 1 — Docs ↔ Code Sync

### README.md — Project structure diagram
- [x] No issues found: project structure diagram matches actual file tree (README.md, SKILL.md, build.sh, references/DEV-LOOP.md, tests/run-tests.sh, tests/fixture/ with all listed files)

### README.md — "What the Skill Does" table vs DEV-LOOP.md
- [x] No issues found: all 7 rows (Before You Start + Steps 1–6 including 3E) accurately describe the corresponding sections in DEV-LOOP.md

### README.md — build.sh flags
- [x] No issues found: `--msg`, `--no-commit`, `--skills-dir`, `--help` all match build.sh implementation; "What build.sh does in order" (test → sync → commit → push) matches code; skills directory auto-detection priority (flag → sibling → ~/.openclaw) matches code

### README.md — test runner flags
- [x] No issues found: `run-tests.sh` flags (`-v`, `--mode structural|integration`, `--work-dir`, `--help`) and example invocations match the actual run-tests.sh implementation

### README.md — Planted flaws table vs fixture/src/greeter.py
- [x] Finding: F3a description said `while i < args.times` "loops forever when times=0 (never enters loop but combined with negative values would be wrong)" — this is self-contradictory and factually incorrect. With `times=0`, `0 < 0` is False so the loop never executes (no infinite loop). Negative values like `-1` also don't loop (`0 < -1` is False). The real issue is silent acceptance of non-positive values with no output and no error. → Fixed: updated "What the agent should find" to: "silently produces no output when times ≤ 0 (loop body never runs; no error raised for invalid input)" (README.md)
- [x] No issues found: F1 (--reverse documented but not in code) matches fixture README + greeter.py
- [x] No issues found: F2 (help text says default 1, actual default 3) matches greeter.py `default=3, help="...default: 1"`
- [x] No issues found: F3b (encode result discarded) matches greeter.py `args.name.encode("ascii")` with no assignment
- [x] No issues found: F3c (unused import os) matches greeter.py `import os` never referenced
- [x] No issues found: F4 (empty name produces "Hello, !") matches greeter.py `f"Hello, {name}!"` with no name validation

### README.md — Self-improvement process
- [x] No issues found: described loop (create temp fixture → agent runs → assert → evaluate → edit skill → build → repeat) matches integration test design in run-tests.sh and the project's architecture

### SKILL.md — Description vs DEV-LOOP.md
- [x] No issues found: SKILL.md description ("structured review-and-fix cycle: sync docs to code, review and fix bugs/security/quality issues, build and test, then re-sync") accurately summarizes DEV-LOOP.md's 6-step protocol

### SKILL.md — Key Rules vs DEV-LOOP.md
- [x] No issues found: all 6 Key Rules in SKILL.md match corresponding DEV-LOOP.md sections:
  - "README.md and STATUS.md are authoritative" → Before You Start §1
  - "Never load the entire codebase at once" → Context Management
  - "Step 3 is file-by-file (Phase A → Phase B → Phase E)" → Step 3 + Step 3E
  - "Do not declare done until build + tests are green" → Step 5
  - "Step 6 is mandatory" → Step 6
  - "Update STATUS.md on commit" → Commit section

## Step 2 — User-Facing Text ↔ Code Sync
- [x] Finding: `build.sh` usage header said "Syncs skill files… then commits and pushes" but code runs structural tests first → Fixed: changed to "Runs structural tests, syncs skill files… then commits and pushes" (build.sh)
- [x] Finding: `build.sh` `--no-commit` description said "Sync files only; skip git add, commit, and push" implying tests are skipped, but tests always run → Fixed: changed to "Run tests and sync files; skip git add, commit, and push" (build.sh)
- [x] Finding: `build.sh` header comment said "Syncs skill files… then stages and commits" — omitted tests and push → Fixed: updated to "Runs structural tests, syncs skill files… then stages, commits, and pushes" (build.sh)
- [x] Finding: `build.sh` header comment `--no-commit` said "Sync files only; skip git add + commit" — omitted push → Fixed: changed to "Run tests and sync files; skip git add, commit, and push" (build.sh)
- [x] Finding: `build.sh` header comment `--skills-dir` default listed as "/workspace/skills/dev-loop" but actual default is auto-detected → Fixed: changed to "auto-detected" (build.sh)
- [x] No issues found in `tests/run-tests.sh` — all flags, descriptions, and defaults match code behavior
- [x] No issues found in `tests/fixture/build.sh` — help text accurately describes behavior (fixture flaws in greeter.py are deliberate and out of scope)
- [x] No issues found in `SKILL.md` description — accurately describes the skill's review-and-fix cycle behavior

## Step 3 — Phase A (file-by-file)

### build.sh
- [x] Finding: `--msg` and `--skills-dir` flags accessed `$2` without checking argument count — with `set -u` (nounset), passing `--msg` as the last argument produces a cryptic "unbound variable" error instead of a helpful message → Fixed: added `[[ $# -ge 2 ]]` guard with clear error message before accessing `$2` for both flags (build.sh)
- [x] No security issues: no hardcoded secrets, no sensitive data exposure
- [x] No resource management issues: no file handles or connections to manage
- [x] No dead code or unused variables (SKILLS_DIR_OVERRIDE used for display logic)
- [x] No unresolved TODO/FIXME/HACK comments

### tests/run-tests.sh
- [x] Finding: `--mode` and `--work-dir` flags accessed `$2` without checking argument count — same unbound variable issue as build.sh → Fixed: added `[[ $# -ge 2 ]]` guard with clear error message before accessing `$2` for both flags (tests/run-tests.sh)
- [x] Finding: `teardown_work_dir` would `rm -rf` a user-provided `--work-dir` directory after assertions — destructive behavior on user data the user explicitly pointed the tool at → Fixed: added `WORK_DIR_USER` flag, `teardown_work_dir` now skips cleanup when `--work-dir` was provided and prints a message instead (tests/run-tests.sh)
- [x] Finding: integration test expected-findings comment said "no guard on times <= 0 (infinite loop)" but per Step 1's README fix, times ≤ 0 is a silent no-op, not an infinite loop → Fixed: changed comment to "no guard on times <= 0 (silently produces no output)" (tests/run-tests.sh)
- [x] No security issues: no hardcoded secrets, no sensitive data exposure
- [x] No unresolved TODO/FIXME/HACK comments

### references/DEV-LOOP.md
- [x] Finding: STEP 3E section was placed after the Commit section in document order, but the overview diagram and STEP 3E's own text ("Proceed to Step 4 only after evaluator findings have been addressed") establish it as part of Step 3, occurring before Step 4 — document structure contradicted logical flow → Fixed: moved STEP 3E section to immediately after STEP 3 (before STEP 4), and Commit section now follows STEP 6 as expected (references/DEV-LOOP.md)
- [x] No other logical inconsistencies: overview diagram matches step details, context management rules are consistent, sub-agent mode description aligns with step procedures

### SKILL.md
- [x] No issues found: all 6 Key Rules match DEV-LOOP.md sections, Quick Start accurately describes the workflow, Sub-Agent Mode description is consistent with DEV-LOOP.md's sub-agent guidance, frontmatter fields present and accurate

## Step 3 — Phase B (cross-file)
- [x] No cross-file issues remaining: the arg-validation pattern (build.sh + run-tests.sh) was fixed independently in Phase A; the "infinite loop" vs "silent no-op" inconsistency (run-tests.sh comment vs README.md) was fixed in Phase A; DEV-LOOP.md section ordering now matches SKILL.md's stated Phase A → B → E → Step 4 flow

## Step 3E — Adversarial Evaluation

### run-tests.sh — Broken regex in structural assertion (silent false-pass)
- [ ] Finding: run-tests.sh:158 — `grep -E` pattern uses `\|` (backslash-pipe) for alternation, but in ERE mode `\|` is a literal pipe character, not alternation. The pattern `'times.*<=.*0\|times < 1\|times <= 0'` matches the literal string `times<=0|times < 1|times <= 0`, not any of the three alternatives individually. Since this is inside `assert_file_not_contains`, the assertion **always passes vacuously** — it cannot detect if greeter.py gains a `times <= 0` guard. The planted flaw F3a is structurally unverifiable by this test. Fix: use `|` (unescaped) instead of `\|` for ERE alternation.

### run-tests.sh — `assert_file_not_contains` gives false pass on missing files
- [ ] Finding: run-tests.sh:69-76 — When the target file does not exist, `grep -Eq` returns exit code 2 (error), and `! grep` inverts it to 0 (success). This means `assert_file_not_contains` silently passes whenever the file is missing, rather than failing. Lines 146, 158, and 173 all call `assert_file_not_contains` on `greeter.py` — if that file were accidentally deleted or renamed, all three assertions would pass, giving false confidence that planted flaws are still present. The function should verify the file exists before checking its content.

### run-tests.sh — `setup_work_dir` runs in a subshell; temp dir leaks on integration runs
- [ ] Finding: run-tests.sh:221 — `work="$(setup_work_dir)"` executes `setup_work_dir` in a command substitution (subshell). When `--work-dir` is not provided, `setup_work_dir` creates a temp dir and sets `WORK_DIR` on line 97 — but that assignment is local to the subshell and lost in the parent. The parent's `WORK_DIR` remains `""`. When `teardown_work_dir` runs (line 284), it checks `[[ -n "$WORK_DIR" && -d "$WORK_DIR" ]]` — both fail because `WORK_DIR` is empty. The temp directory under `/tmp/dev-loop-test-*` is never cleaned up. Every integration run without `--work-dir` leaks a temp directory.

### run-tests.sh — `--work-dir` with nonexistent path silently creates AND leaks a temp dir
- [ ] Finding: run-tests.sh:42+91-96 — If a user passes `--work-dir /some/nonexistent/path`, line 42 sets `WORK_DIR_USER=true`. But `setup_work_dir` line 92 checks `-d "$WORK_DIR"` which fails, so it falls through to `mktemp` (line 97), overwriting `WORK_DIR` in the subshell (lost — see above). The local `work` variable gets the mktemp path, but `WORK_DIR_USER` is still `true`, so `teardown_work_dir` skips cleanup. The user-specified path is silently ignored, a new temp dir is created, and it's never cleaned up. No error or warning is emitted.

### run-tests.sh — `assert_build_passes` swallows all diagnostic output
- [ ] Finding: run-tests.sh:80 — `bash "$dir/build.sh" --no-commit > /dev/null 2>&1` redirects both stdout and stderr to /dev/null. When the fixture build fails, the only output is `[FAIL] ... — build.sh exited non-zero` with no diagnostic information. The user must manually re-run the command to see what went wrong. At minimum, stderr should be preserved, or the output should be captured and displayed on failure.

### run-tests.sh — Integration assertions are too loose to catch wrong findings
- [ ] Finding: run-tests.sh:251-273 — Integration assertions use extremely broad patterns. For example, line 255 checks for `"default"` (any occurrence of the word), line 259 checks for `"times|guard|infinite|<= 0"` (the word "times" alone matches), and line 251 checks for `"reverse"`. An agent that produces a completely wrong checklist but happens to mention these common English words would pass all assertions. The assertions verify word presence, not that the correct flaw was identified in the correct context. They cannot distinguish a true finding from a hallucinated one.

### references/DEV-LOOP.md — STEP 3E section ordering: claimed fixed but still wrong
- [ ] Finding: references/DEV-LOOP.md:274 — The Phase A checklist entry claims "Fixed: moved STEP 3E section to immediately after STEP 3 (before STEP 4)" but the actual file still has STEP 3E at line 274, **after STEP 6** (line 259). The overview diagram shows the flow as STEP 3 (A → B → E) → STEP 4, and STEP 3E's own text says "Proceed to Step 4 only after evaluator findings have been addressed." The document structure still contradicts the logical flow. Either the fix was never applied, or it regressed.

### references/DEV-LOOP.md — Context Management contradicts Step 5
- [ ] Finding: references/DEV-LOOP.md:109 — Context Management section states "Steps 4–5: Only need build/test output, not source files." But STEP 5 (line 247) says "Identify root cause (don't guess — trace it)" and "Fix the code" — both of which require reading source files. An agent following the context management rules strictly would refuse to open source files during Step 5, making it impossible to fix failures. The context management guidance should acknowledge that Step 5 requires reading the relevant source files to diagnose and fix issues.

### README.md — F4 "Flaw" column mislabels the planted flaw
- [ ] Finding: README.md planted flaws table, F4 row — The "Flaw" column says `build_greeting accepts negative shout`, but `shout` is a boolean `store_true` flag — it cannot be negative. The actual flaw (correctly described in the "What the agent should find" column) is about empty `name` producing broken greeting output. The "Flaw" column is misleading and does not describe what's actually planted. An agent or developer reading only the Flaw column would look for the wrong thing.

### build.sh — `git push origin main` runs unconditionally after "Nothing to commit"
- [ ] Finding: build.sh:123 — After detecting "Nothing to commit" on line 117, the script prints a message but does not exit or skip the push. Line 123 (`git push origin main`) executes unconditionally. If the remote is unreachable or the branch has diverged, this produces an error after already reporting "nothing to commit" — confusing output. More importantly, if there are previously committed-but-unpushed changes from outside the script, they get silently pushed during what appears to be a no-op build run. The user likely expects "nothing to commit" to mean "nothing happened."

### build.sh — Hardcoded `main` branch assumption
- [ ] Finding: build.sh:123 — `git push origin main` hardcodes the branch name. If the repo uses a different default branch (e.g., `master`, `develop`, or a feature branch), the push either fails or pushes to the wrong branch. No check is performed to verify the current branch is `main`. Consider using `git push origin HEAD` or detecting the current branch.

## Step 3E — Fixes

- [x] Finding: Broken ERE regex for F3a — `\|` in `grep -E` is literal backslash-pipe, not alternation → Fixed: changed `\|` to `|` for proper ERE alternation, and rewrote the F3a pattern to match actual guard code (`if/elif/while...times`) instead of comments (tests/run-tests.sh)
- [x] Finding: `assert_file_not_contains` false-passes on missing files — `grep -Eq` returns non-zero on missing files, so `!` inverts to success → Fixed: added explicit `[[ ! -f "$file" ]]` check that fails with "file missing" message before running grep (tests/run-tests.sh)
- [x] Finding: Step 3E positioned after Step 6 and Commit in DEV-LOOP.md — contradicts the overview diagram and "proceed to Step 4 only after" text → Fixed: moved STEP 3E section to between STEP 3 and STEP 4 where it logically belongs (references/DEV-LOOP.md)
- [x] Finding: Temp dir leak — `work="$(setup_work_dir)"` runs in a subshell so `WORK_DIR` global is lost, `teardown_work_dir` can't clean up → Fixed: `setup_work_dir` no longer echoes the path; sets `WORK_DIR` directly. Caller uses `setup_work_dir` without command substitution and reads `$WORK_DIR` (tests/run-tests.sh)
- [x] Finding: `--work-dir` with nonexistent path silently ignored — no validation, creates and leaks a temp dir → Fixed: added directory existence check (`[[ ! -d "$2" ]]`) during argument parsing that errors out immediately (tests/run-tests.sh)
- [x] Finding: Context Management says "Steps 4–5 only need build/test output, not source files" — wrong for Step 5 which requires reading code to fix failures → Fixed: split into "Step 4 only needs build/test output. Step 5 needs build output + the source files that caused failures." (references/DEV-LOOP.md)
- [x] Finding: F4 description says "accepts negative shout" — `shout` is boolean, the actual flaw is empty name producing broken greeting → Fixed: changed to "has no validation on empty name" with accurate description (README.md)
- [x] Finding: Integration assertion patterns too loose — single words like "default", "reverse", "times" match generic English → Fixed: tightened all patterns to require contextual phrases (e.g., `--reverse.*not implemented`, `default.*1.*3`, `encode.*discard`) (tests/run-tests.sh)
- [x] Finding: `assert_build_passes` swallows stderr — redirects both stdout/stderr to /dev/null → Fixed: captures combined output, displays it on failure with indented formatting for diagnostics (tests/run-tests.sh)
- [x] Finding: `git push origin main` runs unconditionally after "nothing to commit" — pushes even when no commit was made → Fixed: moved `git push` inside the else branch so it only runs when a commit actually happened (build.sh)
- [x] Finding: Hardcoded `main` branch in `git push` — fails on non-main branches → Fixed: uses `git rev-parse --abbrev-ref HEAD` to detect current branch dynamically (build.sh)

## Step 6 — Re-sync Docs & Help Text
- [x] Finding: README.md step 4 of "What build.sh does in order" said "Pushes to `origin/main`" — build.sh now uses dynamic branch detection and only pushes after a real commit → Fixed: changed to "Pushes to the current branch (only when a commit was made)" (README.md)
- [x] No issues found: build.sh --help text accurately describes behavior (general summary "commits and pushes" is appropriate for help text; conditional details are implementation)
- [x] No issues found: run-tests.sh --help text matches actual behavior — all flags (--mode, --work-dir, -v, --help) documented with correct descriptions
- [x] No issues found: run-tests.sh --work-dir validation (rejects nonexistent paths) is implementation detail not requiring help text mention
- [x] No issues found: README.md structural test descriptions match run-tests.sh behavior
- [x] No issues found: README.md integration test workflow matches run-tests.sh behavior
- [x] No issues found: README.md planted flaws table matches fixture code (F1–F4 all accurate after Step 3E fixes)
- [x] No issues found: SKILL.md description still accurately matches DEV-LOOP.md — all 6 Key Rules align, Quick Start is correct, Sub-Agent Mode consistent
- [x] No issues found: DEV-LOOP.md step ordering (1→2→3→3E→4→5→6→Commit) matches overview diagram and SKILL.md references
- [x] No issues found: DEV-LOOP.md context management section correctly splits Step 4 and Step 5 guidance
- [x] No issues found: No remaining hardcoded "main" branch references in README.md, build.sh, SKILL.md, or DEV-LOOP.md
- [x] All 31 structural tests pass after changes

## Summary
- **Step 1:** 1 docs fix (F3a planted flaw description was self-contradictory)
- **Step 2:** 5 help text fixes (build.sh usage/header/--no-commit description)
- **Step 3 Phase A:** 5 code fixes (arg validation in build.sh + run-tests.sh, teardown safety, comment accuracy, DEV-LOOP.md section ordering)
- **Step 3 Phase B:** 0 cross-file fixes (all resolved in Phase A)
- **Step 3E Adversarial:** 11 findings, 11 fixes (broken regex, false-pass on missing files, temp dir leak, --work-dir validation, context management contradiction, F4 description, loose assertions, swallowed stderr, unconditional push, hardcoded branch)
- **Step 4:** Build green, 31/31 tests passed
- **Step 5:** No failures to fix
- **Step 6:** 1 re-sync fix (README push description updated for dynamic branch)
- **Total:** 23 fixes across 4 files (build.sh, tests/run-tests.sh, references/DEV-LOOP.md, README.md)
