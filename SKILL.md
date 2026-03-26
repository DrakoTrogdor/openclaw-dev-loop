---
name: dev-loop
description: Run a structured review-and-fix cycle on a codebase: sync docs to code, review and fix bugs/security/quality issues, build and test, then re-sync. Works with any language and toolchain (Rust, Node, Python, Go, etc.). Use when asked to review, audit, clean up, or do a full pass on a codebase — or when asked to "run the dev loop" on a project.
---

# Dev Loop

A repeatable review-and-fix cycle for any codebase. Read `references/DEV-LOOP.md` for the full step-by-step protocol before starting.

## Quick Start

1. Read `references/DEV-LOOP.md` — this is your full workflow
2. **Before anything else: read `README.md` and `STATUS.md` in the project root** (if they exist) — they tell you the build/test/deploy/commit commands and any known issues
3. Record the confirmed commands at the top of `DEV-LOOP-CHECKLIST.md` so every step has them
4. Work through Steps 1–6 in order
5. Write every finding to `DEV-LOOP-CHECKLIST.md` as you go

## Key Rules

- **README.md and STATUS.md are authoritative.** If they name a specific script for build/test/deploy/commit, use that script — do not substitute bare toolchain commands.
- **Never load the entire codebase at once.** Read files as needed per step.
- **Step 3 is file-by-file.** Phase A: one file at a time. Phase B: cross-file issues only, 2–3 files at a time. Phase E: spawn a separate adversarial evaluator agent to find what you missed.
- **Do not declare done until build + tests are green.**
- **Step 6 is mandatory** — re-sync docs after every code change, even if you think nothing changed.
- **Update STATUS.md on commit** — remove resolved issues, note anything newly discovered.

## Sub-Agent Mode

For large codebases, spawn one sub-agent per step. Each sub-agent:
1. Reads only the files it needs for its step
2. Does its work
3. Appends findings to `DEV-LOOP-CHECKLIST.md`
4. Reports a summary

The orchestrator reads the checklist between steps to gate progression. Pass the recorded commands from the checklist header to each sub-agent so they don't re-derive them.

## References

- Full workflow and step details: `references/DEV-LOOP.md`
