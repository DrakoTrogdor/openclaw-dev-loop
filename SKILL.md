---
name: dev-loop
description: "Run a structured review-and-fix cycle on a codebase: sync docs to code, review and fix bugs/security/quality issues, build and test, then re-sync. Works with any language and toolchain (Rust, Node, Python, Go, etc.). Use when asked to: review code, audit a project, clean up a codebase, do a quality pass, run a code health check, QA this, fix my code, go through this repo, check this project for bugs, make sure everything is in order, do a full pass, bug sweep, lint and fix cycle, or run the dev loop."
---

# Dev Loop

A repeatable review-and-fix cycle for any codebase. Read `references/DEV-LOOP.md` for the full step-by-step protocol before starting.

## Quick Start

1. Read `references/DEV-LOOP.md` — the full workflow you will follow
2. Read `README.md` and `STATUS.md` **in the target project** (the project you're reviewing, not this skill's repo) — they tell you the build/test/deploy/commit commands and known issues
3. Record those commands at the top of `DEV-LOOP-CHECKLIST.md` in the target project root — every subsequent step uses them
4. Work through the protocol's Steps 1–6 in order, writing every finding to `DEV-LOOP-CHECKLIST.md` as you go
5. Do not declare done until build + tests are green and Step 6 is complete

## Key Rules

1. **Target project docs are authoritative.** If `README.md` or `STATUS.md` names a specific script for build/test/deploy, use it — never substitute bare toolchain commands.
2. **Verify a clean build first.** Run build + tests before making any changes. Record pre-existing failures so you don't confuse them with issues you introduce.
3. **Never load the entire codebase at once.** Read files as needed per step. Small projects (~10 files) can be more flexible.
4. **Prioritize core logic over tooling.** Spend the most time on source files that implement the project's purpose. Build scripts and configs are secondary.
5. **Step 3 is file-by-file.** Phase A: one file at a time, core first. Phase B: cross-file issues, 2–3 files at a time. Step 3E: spawn a separate adversarial evaluator.

## Sub-Agent Mode

For large codebases (>20 source files), see the Sub-Agent Dispatch Table in `references/DEV-LOOP.md` for how to split work across agents.
