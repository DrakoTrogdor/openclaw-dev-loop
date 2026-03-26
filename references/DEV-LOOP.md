# DEV-LOOP

A repeatable review-and-fix cycle for keeping code, docs, and tests in sync.
Works with any language, any toolchain. Report every finding and fix as you go.

---

## Overview

```
DISCOVER (read docs, map project, baseline build)
  → STEP 1 (docs↔code) → STEP 2 (user text↔code)
  → STEP 3 (code review: A file-by-file → B cross-file → E adversarial eval)
  → STEP 4 (build & test) ⟵──── STEP 5 (fix failures) ────┘
  → STEP 6 (re-sync docs) → COMMIT
```

The loop runs in two modes:

| Mode | When to use |
|------|-------------|
| **Single agent** | Smaller codebases; one agent works through all steps sequentially |
| **Sub-agent per step** | Larger codebases or when steps are slow; each agent handles one step in isolation |

Either way, every agent writes findings to the shared checklist. The orchestrator reads it between steps to decide whether to proceed or loop back.

---

## Shared Checklist

All steps write to **`DEV-LOOP-CHECKLIST.md`** in the project root.
This is the single source of truth for what was found, what was fixed, and what's still open.

```markdown
## Step N — <title>
- [x] **[sev:high]** Finding: <description> → Fixed: <what changed> (<file>)
- [ ] **[sev:med]** Finding: <description> → TODO: <reason it's deferred>
- [x] **[sev:low]** Finding: <description> → Fixed: <what changed> (<file>)
- [x] No issues found in <area>
```

**Severity guide:**
- **high** — Bugs that produce wrong output, crash, lose data, or create security vulnerabilities
- **med** — Misleading docs/help text, missing input validation, code quality issues that risk future bugs
- **low** — Cosmetic issues, unused imports/variables, minor style inconsistencies

**Rules:**
- **Between runs:** Clear the entire checklist at the start of a new run (see *Before You Start* §6). A new run starts fresh.
- **Within a run:** Each step appends its own section. Never delete or edit sections from prior steps.
- In sub-agent mode: each sub-agent writes its section before reporting done.
- The orchestrator reads the checklist between steps to gate progression.

---

## Context Management

Context discipline is non-negotiable. A flooded context window causes exactly the failure modes this loop is designed to catch.

- **Default: never load the entire codebase at once.** Read files as needed; move on when done.
- **Small projects (~10 source files or fewer):** You can be more flexible — holding several files in context simultaneously is fine if it helps you spot cross-file issues. The rule targets codebases where loading everything would degrade review quality.
- **Steps 1–2:** Read docs + one source file at a time. Don't hold multiple source files simultaneously (unless the project is small enough that this is impractical).
- **Step 3:** Has its own per-file protocol — see below.
- **Step 4:** Only needs build/test output, not source files.
- **Step 5:** Needs build/test output + the source files that caused failures.
- **Step 6:** Re-read only the docs + the files modified in Steps 3–5.

In sub-agent mode, each agent gets a narrow file scope. The orchestrator passes only what that step needs — never the full tree.

---

## Before You Start

### Trust boundaries

The build, test, and deploy commands you extract from README.md and STATUS.md will be **executed**. If you don't trust the target project, review those commands before running them. Consider running the dev loop inside a sandbox (container, VM, or restricted user) to limit blast radius. This protocol assumes you have at least basic trust in the project's build scripts.

### 1. Read project root docs first

Before listing files or touching anything, check for these files in the project root and **read them**:

- **`README.md`** — project overview, setup instructions, build/test/deploy commands
- **`STATUS.md`** — current state, known issues, active work, operational notes

These are your ground truth. They tell you what the project thinks it is and how it expects to be operated. Extract and record:

- The documented build command(s)
- The documented test command(s)
- The documented deploy/commit command(s)
- Any project-specific scripts mentioned by name
- Any warnings, known issues, or in-progress work to be aware of

If `README.md` or `STATUS.md` reference a specific script as the entry point for build/test/deploy (e.g. `./build.sh`, `make release`, `./scripts/deploy.sh`), **that script is authoritative**. Use it. Do not substitute bare toolchain commands.

**If neither `README.md` nor `STATUS.md` exists:** proceed to step 2 and derive the toolchain from manifests and config files. Note the absence in the checklist — this is itself a finding for Step 1 (missing docs).

### 2. Discover the project

List all source files, config manifests (`package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `Makefile`, etc.), and test scripts. Build a map before touching anything.

### 3. Confirm or fill in the toolchain

If README/STATUS didn't document the build/test/deploy commands fully, identify them now:

- Check for project-specific scripts (`build.sh`, `Makefile`, `justfile`, `scripts/`)
- If a wrapper script exists, **use it exclusively** — it may handle deploy steps, service restarts, asset generation, or sequencing that raw toolchain commands won't
- Only fall back to the toolchain directly if no wrapper exists

### Common toolchain fallback reference

| Language | Build | Lint | Test |
|----------|-------|------|------|
| Rust | `cargo build --release` | `cargo clippy` | `cargo test` |
| Node/TS | `npm run build` | `npm run lint` | `npm test` |
| Python | `pip install -e .` / `hatch build` | `ruff check .` / `flake8` | `pytest` |
| Go | `go build ./...` | `go vet ./...` | `go test ./...` |
| Generic | Check `Makefile` for `build`, `lint`, `test` targets | | |

### 4. Note STATUS.md issues before proceeding

If `STATUS.md` exists, note any known issues or in-progress work. Do not accidentally "fix" something that's intentionally incomplete or mid-refactor. Flag these in the checklist as context, not findings.

### 5. Verify a clean baseline build

Run the build + test commands **before making any changes**. Record the result:

- **If green:** Note "baseline build clean" in the checklist. Proceed.
- **If failing:** Record the pre-existing failures in the checklist under `## Baseline`. These are not your findings — they are context. Do not confuse pre-existing failures with issues you introduce in later steps.

This baseline matters because Steps 4–5 use "all tests green" as the exit gate. You need to know what was already broken.

### 6. Create `DEV-LOOP-CHECKLIST.md`

Create it in the project root (or clear it if it exists from a prior run). Record the confirmed build/test/deploy/commit commands at the top so every subsequent step and sub-agent has them without re-reading docs:

```markdown
# DEV-LOOP-CHECKLIST

## Project Commands
- **Build:** `<command>`
- **Test:** `<command>`
- **Deploy:** `<command or n/a>`
- **Commit:** `<command>`
- **Lint:** `<command>`

## Known issues from STATUS.md
- <any flagged items>

## Baseline
- Build: <pass/fail — if fail, note pre-existing failures>
```

---

## STEP 1 — Docs ↔ Code Sync

**Read:** `README.md`, `STATUS.md`, `USAGE.md`, `docs/`, and source files one at a time. You already read README and STATUS in *Before You Start* — use that knowledge here, don't re-read them from scratch unless you need to verify a specific claim.

**Goal:** Every claim in the docs matches the code. Nothing the code does is undocumented.

| Category | What to verify |
|----------|---------------|
| CLI interface | Flags, arguments, subcommands, defaults — match actual definitions? |
| API surface | Exported functions, types, endpoints — documented accurately? |
| Output format | JSON fields, serialization, optional fields, conditions for presence/absence |
| Constants & limits | Size limits, timeouts, buffer sizes — numbers in docs match code? |
| Dependencies | Listed deps match actual imports and manifest (versions, names, install commands)? |
| Security claims | Anything stated about encryption, permissions, validation — actually true? |
| Feature list | No stale features listed; no implemented features missing from docs |
| Build instructions | Correct toolchain, required system libs, editions/versions |
| Test instructions | Correct commands, required tools, expected output |
| Structured metadata | YAML/TOML/JSON frontmatter, config files — parseable? Values with special characters (colons, quotes) properly quoted? |

**Rule:** Edit docs to match code. Do not change code to match docs in this step.

**Append findings to `DEV-LOOP-CHECKLIST.md` under `## Step 1`.**

---

## STEP 2 — User-Facing Text ↔ Code Sync

**Read:** All help strings, usage text, error messages, and inline doc comments in source.

**Goal:** Every user-visible string accurately describes what the code actually does.

**What to check:**
- `--help` output for every command and subcommand
- Error messages — accurate, actionable, not misleading?
- Inline doc comments on public APIs and exported types
- Generated docs (man pages, docstrings, OpenAPI descriptions)

**Rule:** Edit source strings to match behavior. Do not change logic in this step.

**Append findings to `DEV-LOOP-CHECKLIST.md` under `## Step 2`.**

---

## STEP 3 — Code Review & Fix

**Goal:** Find and fix bugs, security gaps, dead code, and logic errors.

### Priority: core logic over tooling

Spend the most time and attention on the project's **core source files** — the code that implements the project's actual purpose. Build scripts, test runners, CI configs, and dev tooling matter, but they are secondary.

A good rule of thumb: if you're spending more time on `Makefile` and `build.sh` than on the application code, you've lost focus. The tooling exists to support the core — not the other way around.

**Review order:** Core source files first, then supporting scripts, then config/tooling. If time or context is limited, deprioritize tooling — it's better to deeply review 5 core files than to shallowly review 5 core files and 10 scripts.

### Phase A — File-by-file review

Review each source file **individually**, one at a time:

1. Read the file
2. Check against the categories below
3. Fix issues that are self-contained within that file
4. Log issues that span multiple files (don't fix yet)
5. Move to the next file

**Do not hold multiple source files in context simultaneously during Phase A.**

### Phase B — Cross-file issues

After all files are reviewed individually, address the cross-file issues logged in Phase A. These are problems spanning module boundaries:

- Mismatched types or formats across a call chain (caller sends string, callee expects int)
- Inconsistent error handling patterns (one module returns errors, another panics for the same category)
- Shared state handled differently in different files (one normalizes data before storing, another assumes raw data when reading)
- Assumptions one file makes about another's behavior (e.g., "this function always returns non-empty" — does it?)
- Data transformation disagreements: function A transforms data one way on write, function B assumes a different format on read (case normalization, encoding, delimiter choice)

For each cross-file issue: load only the 2–3 relevant files together and fix as a group.

### What to check

#### Security
- Sensitive data (keys, passwords, tokens) cleared from memory after use?
- File permissions restrictive where needed? No TOCTOU race between create and chmod?
- Input validation — untrusted data checked before use?
- No hardcoded secrets; no logging of sensitive values?

#### Resource management
- File handles, connections, and descriptors closed on all paths (success and error)?
- Bounded reads — stdin/network reads have size limits?
- No unbounded allocations from untrusted input?
- Temp files cleaned up on all exit paths (including error/signal)?

#### Correctness
- Lengths, sizes, and indices validated before use? (Off-by-one: `<` vs `<=`, 0-based vs 1-based)
- Version/format checks before processing?
- Decode/parse errors surfaced with context, not silently swallowed?
- Return values actually used — is any function called for a side effect but its result silently discarded? (e.g., `string.encode()` called but return value not assigned or checked)
- Strict parsing where appropriate (reject unknown fields, trailing data)?
- Edge cases covered: empty input, zero/negative numeric args, max-size input, unicode, null bytes?
- Regex/pattern injection: is user input or variable data passed to `grep`, `sed`, `[[ =~ ]]`, or other regex engines without escaping metacharacters (`.`, `*`, `?`, `+`, `|`, `(`, etc.)? Unescaped variables in patterns can silently match or delete unrelated data.
- Integer overflow/underflow for arithmetic on untrusted input?
- Type coercion: implicit conversions that lose precision or change semantics (e.g., float→int truncation, string→number in JS, lossy encoding)?

#### Error handling
- Are errors propagated with enough context to diagnose the problem? (Not just "error occurred" — which file? which input? what was expected?)
- Are any errors silently caught and ignored (empty `except:`, `catch {}`, `|| true`)?
- Do error paths clean up resources (close files, release locks, remove temp files)?
- Are error types consistent within a module? (Don't mix panics, Result, and bare strings for the same category of failure)

#### Concurrency & state (if applicable)
- Shared mutable state protected by appropriate synchronization?
- No data races on concurrent access to files, databases, or shared memory?
- Lock ordering consistent (no deadlock risk from acquiring locks in different orders)?
- Global/module-level mutable state — is initialization order guaranteed?

#### Code quality
- No dead or duplicate functions
- No unused imports or variables
- Clean build with no warnings (per toolchain: `cargo clippy`, `go vet`, `npm run lint`, etc.)
- Error messages are clear and actionable
- No unresolved TODO/FIXME/HACK comments

**Rule:** Fix the code. For each fix, state: *what was wrong → what changed → why.*

**Append findings to `DEV-LOOP-CHECKLIST.md` under `## Step 3 — Phase A` and `## Step 3 — Phase B`.**

---

## STEP 3E — Adversarial Evaluation

After Step 3 Phases A and B, spawn a **separate evaluator agent**. This agent did not write or review the code. Its only job is to find what the generator missed.

### Why this is a separate agent

The same agent that wrote or reviewed code is biased toward approving it. Anthropic found that agents "identified legitimate issues, then talked themselves into deciding they weren't a big deal and approved the work anyway." A dedicated skeptic with no attachment to the work finds different things. Tuning a standalone evaluator to be skeptical is far more tractable than making a generator critical of its own work.

### Evaluator system prompt

The evaluator agent should receive a system prompt like:

> You are a skeptical code reviewer. You did not write this code. You have no attachment to it. Your only job is to find problems the previous reviewer missed.
>
> **Process:** Read the source files and the DEV-LOOP-CHECKLIST.md (which shows what the previous reviewer already found and fixed). Focus on what they MISSED, not on re-reporting what they already caught.
>
> **For each source file, systematically ask:**
>
> *Edge-case inputs:*
> - What happens with empty string input? Zero? Negative numbers? Null/None/nil?
> - What happens at boundary values (max int, empty collections, single-element collections)?
> - What input would a malicious user craft to break this?
>
> *Silent failures:*
> - Is any return value silently discarded? (A function is called, it returns something, and the caller ignores it — this often means the call's purpose is defeated)
> - Is any error silently swallowed (empty catch/except, `|| true`, ignored Result)?
> - Are there logic paths that produce wrong or misleading output without raising an error?
>
> *Cross-function contracts:*
> - Do functions that produce and consume the same data agree on its format (case, encoding, delimiters, quoting)? Example: function A lowercases tags before storing, but function B searches with the original case — they look correct in isolation but fail when composed.
> - Do caller and callee agree on units, ranges, and semantics of shared parameters?
>
> *Compositional bugs:*
> - Does the code work correctly when individual correct-looking components interact? (Each function passes its own unit test but the pipeline produces wrong output)
> - Are there ordering assumptions between operations that aren't enforced?
>
> *Things reviewers habitually overlook:*
> - User-facing output quality: does the output make grammatical/semantic sense for ALL valid inputs, not just the common case?
> - Unused imports, variables, or dead code the reviewer may have noticed but dismissed
> - TODO/FIXME/HACK comments indicating incomplete work
> - Build/lint warnings that were present but not addressed
>
> Do NOT fix anything. Only report findings. Be specific: file, line, what's wrong, why it matters.
> If you find nothing, say so — but look hard before you say that.

### Evaluator procedure

1. **Spawn** a sub-agent with the system prompt above
2. **Give it read access** to: all source files, and the current `DEV-LOOP-CHECKLIST.md`
3. **Do NOT give it** the ability to edit files — it reports findings only
4. **Collect its output** as a list of findings
5. **Append findings** to `DEV-LOOP-CHECKLIST.md` under `## Step 3E — Adversarial Evaluation`
6. **Act on findings**: the generator agent (or a new sub-agent) reads the evaluator's findings and fixes the real issues. Log fixes under `## Step 3E — Fixes`
7. **Proceed to Step 4** only after evaluator findings have been addressed

### When to use

- **Always recommended** for codebases with more than a handful of files
- **Required** when the project's README or STATUS requests adversarial evaluation
- **Skip only** for trivially small codebases where the overhead isn't justified — but note that subtle bugs exist even in small code

### What the evaluator typically catches that the generator misses

- Logic that looks correct but produces wrong output on edge-case input
- Silently discarded return values (the code "works" but isn't doing what it claims)
- Validation that exists but doesn't actually protect against the stated threat
- Grammatically or semantically broken output that only surfaces with specific input combinations
- Assumptions about input that are never checked (empty strings, negative numbers, unicode)

---

## STEP 4 — Build & Test

### Use the commands from the checklist

The build/test commands were recorded in `DEV-LOOP-CHECKLIST.md` during *Before You Start*. Use those — don't re-derive them. If the checklist entry is missing, go back and fill it in before proceeding.

Run the build command. If the script auto-commits, use its `--no-commit` equivalent (or equivalent flag) — the loop controls when to commit.

### What to check

- Non-zero exit codes from any build or test step
- Test failures — note which tests failed and why
- Warnings from the build or lint step that indicate real issues
- Any deploy/asset/service steps that silently fail
- **Compare against baseline:** If the baseline build (from *Before You Start* §5) had pre-existing failures, distinguish those from new failures introduced by your changes

**Goal:** Build exits 0, all tests pass, no meaningful warnings. If the baseline had pre-existing failures, your changes must not make them worse — and ideally should fix them.

**Append results to `DEV-LOOP-CHECKLIST.md` under `## Step 4`.**

---

## STEP 5 — Fix Failures & Repeat

If Step 4 had any failures:

1. Read the error output carefully
2. Identify root cause (don't guess — trace it)
3. Fix the code — not the tests, unless the test itself is provably wrong
4. **Return to Step 4**

Repeat until build and tests are fully green. **Do not declare done until they pass.**

**Append each fix attempt to `DEV-LOOP-CHECKLIST.md` under `## Step 5`.**

---

## STEP 6 — Re-sync Docs & Help Text

Code changes in Steps 3–5 may have introduced new flags, changed defaults, altered behavior, or fixed output formats. The docs and help text must catch up.

1. Re-run **Step 1** — check docs against the modified code only (not the full codebase again)
2. Re-run **Step 2** — check help strings and error messages against modified code

Only re-read files modified in Steps 3–5, plus the docs. Do not reload the entire codebase.

**This step is mandatory even if you think nothing changed. Verify; don't assume.**

**Re-run 3E guidance:** If code changes in Steps 3–5 were substantial (new logic paths, changed validation, altered control flow), consider re-running the Step 3E adversarial evaluation against the updated code. Use judgment — trivial fixes (typos, message rewording) don't warrant a re-run; structural changes do.

**Pass/fail criteria:** Step 6 passes if (a) no doc/help mismatches were found, or (b) all found mismatches were fixed and verified. If mismatches remain unfixed, Step 6 is not green.

**Append findings to `DEV-LOOP-CHECKLIST.md` under `## Step 6`.**

---

## Commit

Once Steps 4–6 are all green:

1. Use the commit command recorded in `DEV-LOOP-CHECKLIST.md` (from the project's README/STATUS or build script)
2. Write a commit message that summarizes what the loop changed, drawn from the checklist
3. Update `CHANGELOG.md` if the project maintains one
4. Update `STATUS.md` if the project maintains one — remove resolved known issues, note anything newly discovered

---

## Reporting

Every finding goes in `DEV-LOOP-CHECKLIST.md` as it happens. At the end, append:

```markdown
## Summary
- **Baseline:** <clean / N pre-existing failures>
- **Step 1:** N docs fixes (H high, M med, L low)
- **Step 2:** N help text fixes
- **Step 3:** N code fixes (M single-file, K cross-file)
- **Step 3E:** N adversarial findings, M fixed
- **Step 4:** Build status, test results
- **Step 5:** N fix iterations
- **Step 6:** N re-sync fixes
- **Total:** N files modified, H high-severity issues resolved
```
