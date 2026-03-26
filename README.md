# dev-loop

An [OpenClaw](https://openclaw.ai) AgentSkill that runs a structured review-and-fix cycle on any codebase — keeping code, docs, and tests in sync.

Works with any language and toolchain: Rust, Node/TypeScript, Python, Go, or anything with a `Makefile` or build script.

---

## What It Does

When triggered, the agent works through six ordered steps:

| Step | What happens |
|------|-------------|
| **Before You Start** | Reads `README.md` and `STATUS.md` to discover build/test/deploy/commit commands; records them in a shared checklist |
| **Step 1 — Docs ↔ Code** | Every claim in the docs is verified against the code; mismatches are fixed |
| **Step 2 — User Text ↔ Code** | Help strings, error messages, and doc comments are verified against actual behavior |
| **Step 3 — Code Review** | File-by-file security, correctness, resource management, and code quality review; bugs are fixed |
| **Step 4 — Build & Test** | Runs the project's own build/test scripts; must exit 0 with all tests passing |
| **Step 5 — Fix & Repeat** | Any failures from Step 4 are fixed and the build is re-run until green |
| **Step 6 — Re-sync Docs** | Docs and help text are re-checked against anything changed in Steps 3–5 |

Every finding is written to `DEV-LOOP-CHECKLIST.md` in the project root as it happens — a running log of what was found, what was fixed, and what was deferred.

---

## Key Design Principles

**Project scripts are authoritative.** If `README.md` or `STATUS.md` names a specific script for building, testing, deploying, or committing — that script is used. The loop never substitutes bare toolchain commands when a wrapper exists.

**Context discipline.** Files are read one at a time, only when needed. The entire codebase is never loaded into context at once. This mirrors [Anthropic's findings](https://www.anthropic.com/engineering/harness-design-long-running-apps) on context management for long-running agents.

**Adversarial evaluation (optional).** For complex codebases, a dedicated skeptical sub-agent can be spawned after Step 3 — its only job is to find what the reviewer missed, with no attachment to the code it's judging.

**Harness evolution.** The loop is designed to be stripped down or extended as needed. Every step encodes an assumption about what the model needs help with — if your project or model makes a step unnecessary, skip it.

---

## Triggers

The skill activates when you ask things like:

- *"Run the dev loop on this project"*
- *"Do a full code review and fix pass"*
- *"Audit the codebase"*
- *"Clean up and sync the docs"*
- *"Review, fix, and make sure the build is green"*

---

## Sub-Agent Mode

For larger codebases, each step can be handed off to a dedicated sub-agent with a narrow file scope. The orchestrator reads `DEV-LOOP-CHECKLIST.md` between steps to gate progression. Recorded build commands are passed to each sub-agent from the checklist header — they don't re-derive them.

---

## Files

```
dev-loop/
├── SKILL.md                  ← loaded by the agent when triggered
└── references/
    └── DEV-LOOP.md           ← full step-by-step protocol
```

`README.md` (this file) is not loaded by the agent — it's for humans.

---

## Installation

Install via [ClaWHub](https://clawhub.ai) or place the `dev-loop/` folder in your OpenClaw skills directory.

---

## Background

This skill was developed alongside a study of [Anthropic's engineering post on harness design for long-running agents](https://www.anthropic.com/engineering/harness-design-long-running-apps). The step structure, context management rules, and adversarial evaluation pattern are directly informed by that work.
