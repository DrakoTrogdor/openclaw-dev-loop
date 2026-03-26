# dev-loop

An [OpenClaw](https://openclaw.ai) AgentSkill that runs a structured review-and-fix cycle on any codebase — keeping code, docs, and tests in sync.

Works with any language and toolchain: Rust, Node/TypeScript, Python, Go, or anything with a `Makefile` or build script.

---

## Project Structure

```
dev-loop/
├── .gitignore
├── DEV-LOOP-CHECKLIST.md             ← checklist from the last dev-loop pass on THIS repo
├── README.md                         ← you are here (project spec + development guide)
├── SKILL.md                          ← agent-facing skill definition (loaded on trigger)
├── build.sh                          ← test, sync, commit, push
├── references/
│   └── DEV-LOOP.md                   ← full step-by-step protocol (loaded by agent)
└── tests/
    ├── run-tests.sh                  ← structural + integration test runner (auto-discovers fixtures)
    └── fixtures/                     ← test projects with planted flaws
        ├── python-greeter/           ← Python CLI fixture
        │   ├── README.md, STATUS.md, build.sh, test.sh
        │   ├── src/greeter.py
        │   └── tests/test_greeter.py
        ├── rust-counter/             ← Rust CLI fixture
        │   ├── README.md, STATUS.md, build.sh, test.sh
        │   ├── Cargo.toml
        │   └── src/main.rs
        └── openclaw-skill/           ← OpenClaw skill fixture (bookmark manager)
            ├── README.md, STATUS.md, build.sh, test.sh
            ├── SKILL.md
            ├── scripts/bookmarks.sh
            └── references/STORAGE.md, SEARCH.md
```

### What lives where

| File | Who reads it | Purpose |
|------|-------------|---------|
| `README.md` | Humans + agents running dev-loop on *this* repo | Project spec, structure, build/test/commit commands, self-improvement process |
| `SKILL.md` | OpenClaw skill loader | Trigger description, 5 key rules, pointer to protocol |
| `references/DEV-LOOP.md` | Agent after skill triggers | Full 6-step protocol, sub-agent dispatch table, checklist format, evaluator prompt |
| `tests/fixtures/` | Test runner + agents under test | Deliberately broken micro-projects for testing the skill |

---

## What the Skill Does

When triggered (by phrases like "review code", "run the dev loop", "QA this", "fix my code", "check this project for bugs", "do a full pass", etc.), the agent:

1. Reads `references/DEV-LOOP.md` for the full protocol
2. Reads `README.md` and `STATUS.md` in the **target project** to discover build/test/deploy/commit commands
3. Records those commands in `DEV-LOOP-CHECKLIST.md` (target project root)
4. Works through Steps 1–6

| Step | What happens |
|------|-------------|
| **Before You Start** | Read target project's `README.md` + `STATUS.md` → discover commands → baseline build → create `DEV-LOOP-CHECKLIST.md` |
| **Step 1 — Docs ↔ Code** | Every claim in the docs is verified against code; docs are edited to match |
| **Step 2 — User Text ↔ Code** | Help strings, error messages, doc comments verified against actual behavior; source strings are edited to match |
| **Step 3 — Code Review** | Phase A: file-by-file (security, correctness, resources, quality). Phase B: cross-file issues. Core source files first, tooling second. |
| **Step 3E — Adversarial Eval** | A separate skeptical agent reviews code + checklist to find what Step 3 missed |
| **Step 4 — Build & Test** | Run project's build/test scripts; must exit 0 with all tests passing |
| **Step 5 — Fix & Repeat** | Fix failures from Step 4, re-run until green |
| **Step 6 — Re-sync Docs** | Re-check docs and help text against anything changed in Steps 3–5 |

### Key Rules (from SKILL.md)

1. **Target project docs are authoritative.** Use the build/test/deploy scripts named in README/STATUS — never substitute bare toolchain commands.
2. **Verify a clean build first.** Run build + tests before changes. Record pre-existing failures.
3. **Never load the entire codebase at once.** Read files as needed per step.
4. **Prioritize core logic over tooling.** Spend the most time on source files that implement the project's purpose.
5. **Step 3 is file-by-file.** Phase A: one file at a time, core first. Phase B: cross-file issues. Step 3E: spawn a separate adversarial evaluator.

### Sub-Agent Mode

For large codebases (>20 source files), `references/DEV-LOOP.md` contains a Sub-Agent Dispatch Table describing how to split Steps 1–6 across agents.

---

## Build, Test, Commit

`build.sh` is the single entry point for all operations on this repo.

```bash
# Full pipeline: test → sync → commit → push
./build.sh --msg "feat: describe what changed"

# Test + sync only, no commit
./build.sh --no-commit

# Override skills directory
./build.sh --msg "fix: tweak" --skills-dir ~/.openclaw/skills/dev-loop

# Help
./build.sh --help
```

**What `build.sh` does in order:**
1. Runs structural tests (`tests/run-tests.sh`) — exits immediately on failure
2. Syncs `SKILL.md` + `references/DEV-LOOP.md` into the OpenClaw skills directory (removes stale files first, then copies fresh)
3. Commits all changes with a timestamped message
4. Pushes to the current branch

**Skills directory auto-detection:**
1. `--skills-dir` flag (explicit override — rejects empty strings and system paths)
2. Sibling `skills/dev-loop` folder (workspace layout)
3. `~/.openclaw/skills/dev-loop` (standard OpenClaw install)

---

## Test Harness

### Structural tests (no agent required)

```bash
./tests/run-tests.sh              # non-verbose
./tests/run-tests.sh -v           # verbose — shows each passing check
```

The runner auto-discovers fixtures by iterating `tests/fixtures/*/` and sourcing each fixture's `test.sh` (which must define `run_fixture_structural()`). Each fixture runs in a subshell — a crashing fixture won't take down the runner.

**Per-fixture checks:**
- Required files exist (README, STATUS, build.sh, source files, test.sh)
- README references `build.sh` as the build command
- STATUS.md has a Known Issues section
- Each planted flaw (F1, F2, F3a–F3c, F3E) is verifiably present via grep patterns
- Fixture build passes (baseline green)

**Skill-level checks:**
- SKILL.md has `name:` and `description:` frontmatter fields with valid YAML
- DEV-LOOP.md contains all steps (1, 2, 3, 3E, 4, 5, 6) and references README.md + STATUS.md

### Integration tests (requires agent run)

```bash
# Step 1: Create a temp copy of the fixture
./tests/run-tests.sh --mode integration

# Step 2: Run the skill against the temp copy
# Point an agent at the temp dir and trigger: "Run the dev loop on this project"

# Step 3: Assert the agent's output
./tests/run-tests.sh --mode integration --work-dir /tmp/dev-loop-test-XXXXXX
```

Integration mode runs structural tests first, then sets up a temp copy of the default fixture (python-greeter). If structural tests fail, integration assertions are skipped.

Integration assertions check:
- `DEV-LOOP-CHECKLIST.md` was created in the temp dir
- Each planted flaw appears as a finding in the checklist
- Build passed
- Real fixture directory is untouched

**The real fixture is never modified.** The test copies it to a temp dir, the agent works on the copy, assertions run against the copy, then the temp dir is cleaned up.

---

## Test Fixtures

`tests/fixtures/` contains three micro-projects with **deliberately planted flaws** — 6 per fixture, 18 total. These exist to test that the skill catches what it should regardless of ecosystem.

Each fixture defines a `test.sh` that exports a `run_fixture_structural()` function. The test runner auto-discovers fixtures by iterating `tests/fixtures/*/`.

### Planted flaws — python-greeter

A tiny Python CLI (`greeter.py`).

| ID | Step | Flaw | What the agent should find |
|----|------|------|---------------------------|
| F1 | Step 1 | README documents `--reverse` flag | Flag does not exist in code |
| F2 | Step 2 | `--times` help text says `default: 1` | Actual argparse default is `3` |
| F3a | Step 3 | No guard on `--times 0` | `while i < args.times` silently produces no output when times ≤ 0 (loop body never runs; no error raised for invalid input) |
| F3b | Step 3 | `args.name.encode("ascii")` | Result silently discarded — intent was to validate ASCII-only names but for ASCII input the return value is unused, and for non-ASCII input the `UnicodeEncodeError` is unhandled (crashes with a traceback instead of a friendly error) |
| F3c | Step 3 | `import os` | Unused import |
| F3E | Step 3E | `build_greeting` has no validation on empty name | Empty `--name ""` produces `"Hello, !"` (or `"HELLO, !"` with `--shout`) — a grammatically broken greeting with no validation to catch it |

### Planted flaws — rust-counter

A Rust CLI that counts word occurrences from stdin.

| ID | Step | Flaw | What the agent should find |
|----|------|------|---------------------------|
| F1 | Step 1 | README documents `--ignore-case` flag | Flag is not implemented in code |
| F2 | Step 2 | Help text says "Counts lines containing \<word\>" | Code actually counts occurrences (`.matches(word).count()`), not lines |
| F3a | Step 3 | No guard on empty `--word ""` | `"".matches("")` panics or produces nonsensical results |
| F3b | Step 3 | `.unwrap()` on line read | Panics on invalid UTF-8 instead of handling the error |
| F3c | Step 3 | `use std::collections::HashMap` | Unused import |
| F3E | Step 3E | Per-line counting via `reader.lines()` | Words spanning a line boundary (e.g. "hel\nlo" for "hello") are silently missed — the logic looks correct per-line; only adversarial thinking about input shaping catches this |

### Planted flaws — openclaw-skill (bookmark-manager)

An OpenClaw skill with a bash CLI for managing bookmarks.

| ID | Step | Flaw | What the agent should find |
|----|------|------|---------------------------|
| F1 | Step 1 | SKILL.md documents `export --format csv` | Script only supports `html\|json` — csv is not implemented |
| F2 | Step 2 | Help text says "search by date range" | Date range filtering is not implemented |
| F3a | Step 3 | `save_bookmark` accepts any string as URL | No URL validation — empty string, spaces, garbage all accepted |
| F3b | Step 3 | `delete_bookmark` uses `grep -v "$url"` | Regex metacharacters in URL (e.g. `?`, `+`, `.`) silently match and delete unrelated bookmarks |
| F3c | Step 3 | `BACKUP_DIR` defined but never used | Unused variable |
| F3E | Step 3E | Tag case mismatch between save and search | `save_bookmark` lowercases tags via `tr`, but `search_bookmarks` uses the tag as-is — searching for "Docs" never matches stored "docs". Each function looks correct in isolation; only cross-function adversarial review catches the interaction bug |

**Do not fix these flaws in the fixtures.** They are the test cases.

### Adding a new fixture

1. Create `tests/fixtures/<name>/` with README.md, STATUS.md, build.sh, test.sh, and source files
2. Plant 6 flaws: F1 (Step 1 doc/code mismatch), F2 (Step 2 help text mismatch), F3a–F3c (Step 3 bugs), F3E (adversarial-only)
3. Write `test.sh` defining `run_fixture_structural()` with assertions that each flaw exists
4. Ensure `build.sh --no-commit` exits 0 (baseline green)
5. The runner will auto-discover it — no changes to `run-tests.sh` needed

### Adding a flaw to an existing fixture

1. Plant the flaw in the appropriate source file (or README/STATUS/SKILL.md)
2. Add structural assertions in the fixture's `test.sh`
3. Add integration assertions in `run-tests.sh` if applicable
4. Add a row to the fixture's table above
5. Run `./build.sh --msg "test: add flaw FN — <description>"`

---

## Self-Improvement Process

This skill improves itself using its own protocol. The improvement targets are **`SKILL.md`** and **`references/DEV-LOOP.md`** — the skill content, not the meta tooling (build.sh, run-tests.sh, fixtures).

### The loop

```
┌─ run-tests.sh --mode integration          (create temp fixture)     [automated]
│
├─ agent runs dev-loop on temp fixture       (skill under test)        [manual]
│
├─ run-tests.sh --work-dir <tmp>            (assert findings)          [automated]
│
├─ evaluate: what did it miss? what was wrong?                         [manual]
│   │
│   ├─ Missed a planted flaw?     → Improve DEV-LOOP.md instructions for that step
│   ├─ Hallucinated a finding?    → Tighten criteria language in DEV-LOOP.md
│   ├─ Wrong build command?       → Improve README/STATUS discovery section in DEV-LOOP.md
│   ├─ Skipped adversarial eval?  → Make Step 3E instructions more explicit in DEV-LOOP.md
│   └─ Self-approved bad work?    → Strengthen evaluator prompt in DEV-LOOP.md Step 3E
│
├─ edit SKILL.md and/or references/DEV-LOOP.md                        [manual]
│
├─ build.sh --msg "improve: <what and why>"  (test → sync → commit)   [automated]
│
└─ repeat
```

### What to improve and what NOT to improve

| Target | When to edit |
|--------|-------------|
| `references/DEV-LOOP.md` | Step instructions unclear, evaluator prompt too weak/strong, context rules insufficient, checklist format needs work |
| `SKILL.md` | Trigger phrases missing, key rules wrong or missing, description inaccurate |
| `build.sh` | Only if the build/sync/commit pipeline itself is broken |
| `tests/run-tests.sh` | Only if test infrastructure is broken or a new assertion type is needed |
| `tests/fixtures/*` | Only to add new flaws or new fixtures — never to "fix" planted flaws |

The skill's quality is measured by how many planted flaws the agent finds on a clean run against each fixture. When a flaw is consistently missed:

1. Re-read the relevant step in `DEV-LOOP.md`
2. Ask: is the instruction clear enough? Would a cold-start agent follow this step and catch this flaw?
3. Edit the step — add an explicit check, a concrete example, or a stronger directive
4. Re-run the integration test and see if the finding appears

The adversarial evaluation (Step 3E) specifically targets flaws a generator agent reviewing its own work would miss. If the skill catches F1–F3c but misses F3E, the evaluator prompt or protocol needs strengthening.

---

## Design Principles

**Project scripts are authoritative.** If `README.md` or `STATUS.md` names a specific script for building/testing/deploying, the loop uses it — never substituting bare toolchain commands.

**Context discipline.** Files are read one at a time, only when needed. The entire codebase is never loaded at once.

**Adversarial evaluation.** After Step 3, a dedicated skeptical sub-agent reviews the code and checklist. Agents reliably over-approve their own work; the separation is critical.

**Harness evolution.** When a new model makes a step unnecessary, strip it. When a new failure mode emerges, add a step. The skill should get simpler over time, not more complex.

---

## Background

Developed alongside a study of [Anthropic's engineering post on harness design for long-running agents](https://www.anthropic.com/engineering/harness-design-long-running-apps). The step structure, context management, adversarial evaluation, and harness evolution principle are directly informed by that work.
