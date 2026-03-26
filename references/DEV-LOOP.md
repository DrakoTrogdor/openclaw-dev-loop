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

### Sub-Agent Dispatch Table

For large codebases (>20 source files or multi-module projects), use this table to split work:

| Sub-agent | Scope | Gets from orchestrator |
|-----------|-------|----------------------|
| Steps 1–2 | Docs sync | Checklist header (commands), doc files + source files one at a time |
| Step 3A | File-by-file review | Checklist header, one source file at a time |
| Step 3B | Cross-file issues | Checklist header, logged cross-file issues from 3A, 2–3 files per group |
| Step 3E | Adversarial eval | Checklist (all prior sections), all source files, read-only access |
| Steps 4–5 | Build & fix | Checklist header (commands), build/test output, failing source files |
| Step 6 | Re-sync docs | Checklist header, list of files modified in Steps 3–5, doc files |

Each sub-agent appends its findings to `DEV-LOOP-CHECKLIST.md` before reporting done. Pass the recorded commands from the checklist header to each sub-agent so they don't re-derive them.

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

Never load the entire codebase at once. Read files as needed per step; move on when done. Small projects (~10 files) can be more flexible.

| Step | What to hold in context |
|------|------------------------|
| 1–2 | Docs + one source file at a time |
| 3A | One source file at a time |
| 3B | 2–3 related files per cross-file issue |
| 4 | Build/test output only |
| 5 | Build output + failing source files |
| 6 | Docs + files modified in Steps 3–5 |

In sub-agent mode, the orchestrator passes only what each step needs.

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

If README/STATUS didn't fully document build/test/deploy commands, check for wrapper scripts (`build.sh`, `Makefile`, `justfile`, `scripts/`). If one exists, **use it exclusively**. Only fall back to raw toolchain commands if no wrapper exists.

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
| CLI/API surface | Flags, arguments, subcommands, defaults, exported functions — match actual code? |
| Output format | JSON fields, serialization, optional fields — docs match actual output? |
| Constants & limits | Size limits, timeouts, buffer sizes — numbers in docs match code? |
| Feature list | No stale features listed; no implemented features missing from docs |
| Security claims | Stated encryption, permissions, validation — actually true in code? |
| Build/test instructions | Correct commands, required tools, editions/versions? |
| Structured metadata | YAML/TOML/JSON frontmatter parseable? Special characters properly quoted? |

**Rule:** Edit docs to match code. Do not change code to match docs in this step.

**Append findings to `DEV-LOOP-CHECKLIST.md` under `## Step 1`.**

---

## STEP 2 — User-Facing Text ↔ Code Sync

**Read:** All help strings, usage text, error messages, and inline doc comments in source.

**Goal:** Every user-visible string accurately describes what the code actually does.

**What to check:**
- `--help` output for every command — flags, defaults, descriptions match behavior?
- Error messages accurate and actionable?
- Doc comments on public APIs match actual signatures and behavior?

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
- Input validation on untrusted data before use
- No hardcoded secrets; no logging of sensitive values
- Sensitive data cleared after use; file permissions restrictive (no TOCTOU gaps)

#### Resource management
- File handles, connections, temp files closed/cleaned on all paths (success and error)
- Bounded reads from stdin/network — no unbounded allocations from untrusted input

#### Correctness
- Return values actually used — not silently discarded (e.g., `encode()` called but result never assigned)
- Edge cases: empty input, zero/negative args, max-size input, unicode, null bytes
- Off-by-one errors (`<` vs `<=`, 0-based vs 1-based)
- Regex/pattern injection: user input passed to `grep`, `sed`, `[[ =~ ]]` without escaping metacharacters?
- Type coercion that loses precision or changes semantics
- Decode/parse errors surfaced with context, not silently swallowed

#### Error handling
- Errors propagated with enough context (which file? which input? what was expected?)
- No silently caught/ignored errors (empty `except:`, `catch {}`, `|| true`)
- Error paths clean up resources; error types consistent within a module

#### Concurrency & state (if applicable)
- Shared mutable state properly synchronized; no data races
- Lock ordering consistent; global mutable state initialization order guaranteed

#### Code quality
- No dead code, unused imports, or unresolved TODO/FIXME/HACK
- Clean build with no warnings

**Rule:** Fix the code. For each fix, state: *what was wrong → what changed → why.*

**Append findings to `DEV-LOOP-CHECKLIST.md` under `## Step 3 — Phase A` and `## Step 3 — Phase B`.**

---

## STEP 3E — Adversarial Evaluation

After Step 3 Phases A and B, spawn a **separate evaluator agent**. This agent did not write or review the code. Its only job is to find what the generator missed.

### Evaluator system prompt

The evaluator agent should receive a system prompt like:

> You are a skeptical code reviewer. You did not write this code. Your job: find problems the previous reviewer missed.
>
> Read the source files and DEV-LOOP-CHECKLIST.md (what was already found). Focus on what they MISSED.
>
> For each source file, try to break it:
> - **Edge cases:** empty input, zero, negative, null, max values, unicode, single-element collections. What input would a malicious user craft?
> - **Silent failures:** return values discarded? Errors swallowed? Logic paths that produce wrong output without raising errors?
> - **Cross-function contracts:** do producer and consumer agree on format, case, encoding, units? Do they look correct in isolation but fail when composed?
> - **Output quality:** does user-facing output make sense for ALL valid inputs, not just the common case?
>
> Do NOT fix anything. Report only: file, line, what's wrong, why it matters.
> If you find nothing, say so — but look hard first.

### Evaluator procedure

1. **Spawn** a sub-agent with the system prompt above
2. **Give it read access** to: all source files, and the current `DEV-LOOP-CHECKLIST.md`
3. **Do NOT give it** the ability to edit files — it reports findings only
4. **Collect its output** as a list of findings
5. **Append findings** to `DEV-LOOP-CHECKLIST.md` under `## Step 3E — Adversarial Evaluation`
6. **Act on findings**: the generator agent (or a new sub-agent) reads the evaluator's findings and fixes the real issues. Log fixes under `## Step 3E — Fixes`
7. **Proceed to Step 4** only after evaluator findings have been addressed

### When to use

- **Always recommended** unless the codebase is trivially small
- **Required** when README or STATUS requests adversarial evaluation

---

## STEP 4 — Build & Test

Use the build/test commands recorded in `DEV-LOOP-CHECKLIST.md`. If the script auto-commits, use its `--no-commit` flag — the loop controls when to commit.

**Check:** Non-zero exit codes, test failures, meaningful warnings, silently failing deploy steps. Compare against baseline — distinguish pre-existing failures from new ones.

**Goal:** Build exits 0, all tests pass, no meaningful warnings.

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

Code changes in Steps 3–5 may have introduced new flags, changed defaults, or altered behavior. Docs and help text must catch up.

1. Re-run **Step 1** checks against modified code only (not the full codebase)
2. Re-run **Step 2** checks against modified code only

**This step is mandatory even if you think nothing changed. Verify; don't assume.**

**Re-run 3E:** If Steps 3–5 made structural changes (new logic paths, changed validation, altered control flow), re-run the adversarial evaluation. Trivial fixes don't warrant a re-run.

**Pass/fail:** All doc/help mismatches found must be fixed. If any remain, Step 6 is not green.

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
