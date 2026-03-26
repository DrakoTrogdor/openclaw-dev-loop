---
name: dev-loop
description: "Run a structured review-and-fix cycle on a codebase: sync docs to code, review and fix bugs/security/quality issues, build and test, then re-sync. Works with any language and toolchain (Rust, Node, Python, Go, etc.). Use when asked to review, audit, clean up, do a quality pass, run a code health check, or do a full pass on a codebase. Also triggers on: code audit, bug sweep, codebase review, lint and fix cycle, or when asked to run the dev loop on a project."
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

- **Target project docs are authoritative.** If `README.md` or `STATUS.md` names a specific script for build/test/deploy/commit, use that script — do not substitute bare toolchain commands. If neither file exists, discover the toolchain from manifests and config files (see the protocol's fallback table).
- **Verify a clean build first.** Run build + tests before making any changes. If they fail, record pre-existing failures in the checklist so you don't confuse them with issues you introduce.
- **Never load the entire codebase at once.** Read files as needed per step. For small projects (~10 files), you can be more flexible, but the principle is: only hold what the current step requires.
- **Prioritize core logic over tooling.** Spend the most time on source files that implement the project's actual purpose. Build scripts, test runners, and configs are secondary — don't let them dominate the review.
- **Step 3 is file-by-file.** Phase A: one file at a time, core source first. Phase B: cross-file issues only, 2–3 files at a time. Step 3E: spawn a separate adversarial evaluator agent to find what you missed.
- **Checklist discipline.** Each step appends its own section to `DEV-LOOP-CHECKLIST.md`. Never delete or edit sections from prior steps within the same run.
- **Step 6 is mandatory** — re-sync docs after every code change, even if you think nothing changed.
- **Update STATUS.md on commit** (if the project maintains one) — remove resolved issues, note anything newly discovered.
- **Trust boundaries:** Build/test commands from docs will be executed. Review them first on untrusted projects; consider running in a sandbox.

## Sub-Agent Mode

For large codebases (>20 source files or multi-module projects), spawn sub-agents to parallelize work:

| Sub-agent | Scope | Gets from orchestrator |
|-----------|-------|----------------------|
| Steps 1–2 | Docs sync | Checklist header (commands), doc files + source files one at a time |
| Step 3A | File-by-file review | Checklist header, one source file at a time |
| Step 3B | Cross-file issues | Checklist header, logged cross-file issues from 3A, 2–3 files per group |
| Step 3E | Adversarial eval | Checklist (all prior sections), all source files, read-only access |
| Steps 4–5 | Build & fix | Checklist header (commands), build/test output, failing source files |
| Step 6 | Re-sync docs | Checklist header, list of files modified in Steps 3–5, doc files |

Each sub-agent appends its findings to `DEV-LOOP-CHECKLIST.md` before reporting done. The orchestrator reads the checklist between steps to gate progression. Pass the recorded commands from the checklist header to each sub-agent so they don't re-derive them.
