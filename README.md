# dev-loop

An [OpenClaw](https://openclaw.ai) AgentSkill that runs a structured review-and-fix cycle on any codebase — keeping code, docs, and tests in sync.

Works with any language and toolchain: Rust, Node/TypeScript, Python, Go, or anything with a `Makefile` or build script.

---

## Project Structure

```
dev-loop/
├── .gitignore                        ← ignores __pycache__/, *.pyc, .pytest_cache/
├── README.md                         ← you are here (project spec + development guide)
├── SKILL.md                          ← agent-facing skill definition (loaded on trigger)
├── build.sh                          ← build, test, sync, commit, push
├── references/
│   └── DEV-LOOP.md                   ← full step-by-step protocol (loaded by agent)
└── tests/
    ├── run-tests.sh                  ← structural + integration test runner (auto-discovers fixtures via test.sh)
    └── fixtures/                     ← test projects with planted flaws
        ├── python-greeter/           ← Python CLI fixture
        │   ├── README.md, STATUS.md, build.sh
        │   ├── test.sh              ← structural assertions (sourced by run-tests.sh)
        │   ├── src/greeter.py        ← source with planted bugs
        │   └── tests/test_greeter.py
        ├── rust-counter/             ← Rust CLI fixture
        │   ├── README.md, STATUS.md, build.sh
        │   ├── test.sh              ← structural assertions (sourced by run-tests.sh)
        │   ├── Cargo.toml
        │   └── src/main.rs           ← source with planted bugs
        └── openclaw-skill/           ← OpenClaw skill fixture
            ├── README.md, STATUS.md, build.sh
            ├── test.sh              ← structural assertions (sourced by run-tests.sh)
            ├── SKILL.md              ← skill definition with planted flaws
            ├── scripts/bookmarks.sh  ← CLI with planted bugs
            └── references/           ← STORAGE.md, SEARCH.md
```

### What lives where

| File | Who reads it | Purpose |
|------|-------------|---------|
| `README.md` | Humans + agents running dev-loop on *this* repo | Project spec, structure, build/test/commit commands, self-improvement process |
| `SKILL.md` | OpenClaw skill loader | Trigger description, key rules, pointer to protocol |
| `references/DEV-LOOP.md` | Agent after skill triggers | The full 6-step protocol an agent follows when running the dev loop on *any* project |
| `tests/fixtures/` | Test runner + agents under test | Deliberately broken micro-projects for testing the skill (one per language/project type) |

---

## What the Skill Does

When triggered on a target project, the agent works through six ordered steps:

| Step | What happens |
|------|-------------|
| **Before You Start** | Reads target project's `README.md` and `STATUS.md` → discovers build/test/deploy/commit commands → records them in `DEV-LOOP-CHECKLIST.md` |
| **Step 1 — Docs ↔ Code** | Every claim in the docs is verified against the code; mismatches are fixed |
| **Step 2 — User Text ↔ Code** | Help strings, error messages, and doc comments are verified against actual behavior |
| **Step 3 — Code Review** | File-by-file security, correctness, resource management, and code quality review; bugs are fixed |
| **Step 3E — Adversarial Eval** | A separate skeptical agent reviews the code + checklist to find what Step 3 missed |
| **Step 4 — Build & Test** | Runs the project's own build/test scripts; must exit 0 with all tests passing |
| **Step 5 — Fix & Repeat** | Any failures from Step 4 are fixed and the build is re-run until green |
| **Step 6 — Re-sync Docs** | Docs and help text are re-checked against anything changed in Steps 3–5 |

Every finding is written to `DEV-LOOP-CHECKLIST.md` in the target project root.

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
1. Runs structural tests (`tests/run-tests.sh`) — **exits immediately on failure** (`set -euo pipefail`)
2. Syncs `SKILL.md` + `references/DEV-LOOP.md` into the OpenClaw skills directory (removes any stale files from a previous sync first, then copies fresh)
3. Commits all changes with a timestamped message
4. Pushes to the current branch (only when a commit was made; if there are no staged changes, prints "Nothing to commit" and warns about any unpushed local commits, then exits 0)

**Skills directory auto-detection:**
1. `--skills-dir` flag (explicit override, always wins — rejects empty strings and system paths like `/etc`, `/usr`)
2. Sibling `skills/dev-loop` folder (workspace layout)
3. `~/.openclaw/skills/dev-loop` (standard OpenClaw install; requires `$HOME` to be set)

---

## Test Harness

### Structural tests (no agent required)

```bash
./tests/run-tests.sh              # non-verbose
./tests/run-tests.sh -v           # verbose — shows each passing check
```

The runner auto-discovers fixtures by iterating `tests/fixtures/*/` and sourcing each fixture's `test.sh` (which must define `run_fixture_structural()`). Each fixture runs in a subshell with full isolation — a broken or crashing fixture won't take down the test runner. The total check count scales with the number of fixtures and assertions.

Per-fixture checks:
- Required files exist (README, STATUS, build.sh, source files, test.sh)
- README references `build.sh` as the build command
- STATUS.md has a Known Issues section documenting key bugs
- Each planted flaw (F1, F2, F3a–F3c, F3E) is verifiably present via grep patterns
- Fixture build passes (baseline green before any agent touches it)

Skill-level checks (not fixture-specific):
- SKILL.md has `name:` and `description:` frontmatter fields
- SKILL.md YAML frontmatter is valid (parseable by `yaml.safe_load`)
- DEV-LOOP.md contains all steps (1, 2, 3, 3E, 4, 5, 6) and references README.md + STATUS.md

### Integration tests (requires agent run)

```bash
# Step 1: Create a temp copy of the fixture
./tests/run-tests.sh --mode integration
# Output: "Temp fixture: /tmp/dev-loop-test-XXXXXX"

# Step 2: Run the skill against the temp copy
# Point an agent at the temp dir and trigger: "Run the dev loop on this project"

# Step 3: Assert the agent's output
./tests/run-tests.sh --mode integration --work-dir /tmp/dev-loop-test-XXXXXX
```

**Note:** Integration mode always runs structural tests first, then the integration-specific assertions. If structural tests fail, integration assertions are skipped.

Integration assertions check:
- `DEV-LOOP-CHECKLIST.md` was created in the temp dir
- Each planted flaw appears as a finding in the checklist
- Build passed
- Real fixture directory is untouched

**The real fixture is never modified.** The integration test copies it to a temp dir, the agent works on the copy, assertions run against the copy, then the temp dir is cleaned up.

---

## Test Fixtures

`tests/fixtures/` contains three micro-projects with **deliberately planted flaws** — one per skill step category, across different languages and project types. These exist to test that the skill catches what it should regardless of ecosystem.

Each fixture defines a `test.sh` that exports a `run_fixture_structural()` function. The test runner auto-discovers fixtures by iterating `tests/fixtures/*/` and sourcing each `test.sh`.

### Planted flaws — python-greeter

A tiny Python CLI (`greeter.py`).

| ID | Step | Flaw | What the agent should find |
|----|------|------|---------------------------|
| F1 | Step 1 | README documents `--reverse` flag | Flag does not exist in code |
| F2 | Step 2 | `--times` help text says `default: 1` | Actual argparse default is `3` |
| F3a | Step 3 | No guard on `--times 0` | `while i < args.times` silently produces no output when times ≤ 0 (loop body never runs; no error raised for invalid input) |
| F3b | Step 3 | `args.name.encode("ascii")` | Result silently discarded — intent was to validate ASCII-only names but for ASCII input the return value is unused, and for non-ASCII input the `UnicodeEncodeError` is unhandled (crashes with a traceback instead of a friendly error) |
| F3c | Step 3 | `import os` | Unused import |
| F3E | Step 3E | `build_greeting` has no validation on empty name | Empty `--name ""` produces `"Hello, !"` (or `"HELLO, !"` with `--shout`) — a grammatically broken greeting with no validation to catch it (designed to test adversarial evaluation) |

### Planted flaws — rust-counter

A Rust CLI that counts word occurrences from stdin.

| ID | Step | Flaw | What the agent should find |
|----|------|------|---------------------------|
| F1 | Step 1 | README documents `--ignore-case` flag | Flag is not implemented in code |
| F2 | Step 2 | Help text says "Counts lines containing \<word\>" | Code actually counts occurrences (`.matches(word).count()`), not lines |
| F3a | Step 3 | No guard on empty `--word ""` | `"".matches("")` panics or produces nonsensical results |
| F3b | Step 3 | `.unwrap()` on line read | Panics on invalid UTF-8 instead of handling the error |
| F3c | Step 3 | `use std::collections::HashMap` | Unused import |
| F3E | Step 3E | Per-line counting via `reader.lines()` | Words spanning a line boundary (e.g. "hel\nlo" for "hello") are silently missed — the logic looks correct because `.matches()` works fine on each individual line; only adversarial thinking about input shaping catches this |

### Planted flaws — openclaw-skill (bookmark-manager)

An OpenClaw skill with a bash CLI for managing bookmarks.

| ID | Step | Flaw | What the agent should find |
|----|------|------|---------------------------|
| F1 | Step 1 | SKILL.md documents `export --format csv` | Script only supports `html\|json` — csv case is not implemented |
| F2 | Step 2 | Help text says "search by date range" | Date range filtering is not implemented |
| F3a | Step 3 | `save_bookmark` accepts any string as URL | No URL validation — empty string, spaces, garbage all accepted |
| F3b | Step 3 | `delete_bookmark` uses `grep -v "$url"` | Regex metacharacters in URL (e.g. `?`, `+`, `.`) silently match and delete unrelated bookmarks |
| F3c | Step 3 | `BACKUP_DIR` defined but never used | Unused variable |
| F3E | Step 3E | Tag case mismatch between save and search | `save_bookmark` lowercases tags via `tr`, but `search_bookmarks` uses the tag variable as-is — searching for "Docs" never matches the stored "docs" tag. Each function looks correct in isolation; only cross-function adversarial review catches the interaction bug |

**Do not fix these flaws in the fixtures.** They are the test cases. If the agent fixes them during an integration run, the structural tests will detect the fixture is corrupted.

### Adding new planted flaws

When adding a flaw:
1. Plant it in the appropriate fixture's source file (or README/STATUS/SKILL.md as appropriate)
2. Add a structural assertion in the fixture's `test.sh` to verify the flaw exists
3. Add an integration assertion in `run-tests.sh` to verify the agent found it (if applicable)
4. Add a row to the appropriate table above
5. Run `./build.sh --msg "test: add flaw FN — <description>"`

---

## Self-Improvement Process

This skill is designed to improve itself using its own protocol.

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
│   ├─ Hallucinated a finding?    → Tighten criteria language
│   ├─ Wrong build command?       → Improve README/STATUS discovery section
│   ├─ Skipped adversarial eval?  → Make Step 3E instructions more explicit
│   └─ Self-approved bad work?    → Strengthen evaluator prompt in Step 3E
│
├─ edit SKILL.md and/or references/DEV-LOOP.md                        [manual]
│
├─ build.sh --msg "improve: <what and why>"  (test → sync → commit → push) [automated]
│
└─ repeat
```

### What "improving the skill" means concretely

The skill's quality is measured by how many of the planted flaws the agent finds on a clean run against each fixture. When a flaw is consistently missed:

1. Re-read the relevant step in `DEV-LOOP.md`
2. Ask: is the instruction clear enough? Is it specific enough? Would a cold-start agent with no prior context follow this step and catch this flaw?
3. Edit the step — add an explicit check, a concrete example, or a stronger directive
4. Re-run the integration test and see if the finding appears

The adversarial evaluation step (Step 3E) specifically targets flaws that a generator agent reviewing its own work would miss. If the skill is catching F1–F3c but missing F3E across fixtures, the evaluator prompt or protocol needs strengthening.

---

## Key Design Principles

**Project scripts are authoritative.** If `README.md` or `STATUS.md` names a specific script for building, testing, deploying, or committing — that script is used. The loop never substitutes bare toolchain commands when a wrapper exists.

**Context discipline.** Files are read one at a time, only when needed. The entire codebase is never loaded into context at once. This mirrors [Anthropic's findings](https://www.anthropic.com/engineering/harness-design-long-running-apps) on context management for long-running agents.

**Adversarial evaluation.** After Step 3, a dedicated skeptical sub-agent reviews the code and checklist. Its only job is to find what the generator missed. This separation is critical — agents reliably over-approve their own work.

**Harness evolution.** Every step encodes an assumption about what the model needs help with. When a new model makes a step unnecessary, strip it. When a new failure mode emerges, add a step. The skill should get simpler over time, not more complex.

---

## Background

This skill was developed alongside a study of [Anthropic's engineering post on harness design for long-running agents](https://www.anthropic.com/engineering/harness-design-long-running-apps). The step structure, context management rules, adversarial evaluation pattern, and harness evolution principle are directly informed by that work. Research notes: `/workspace/research/harness-design-long-running-agents.md`.
