# DEV-LOOP-CHECKLIST — Pass 4 (Skill Content Focus)

Focus: Improve SKILL.md and references/DEV-LOOP.md as agent-facing instructional documents.
Do NOT focus on build.sh, run-tests.sh, or other meta tooling unless a skill content change requires it.

## Project Commands
- **Build:** `./build.sh --msg "<description>"`
- **Test:** `./tests/run-tests.sh`
- **Commit:** `./build.sh --msg "<description>"`

## Skill Content Review

### SKILL.md — 8 changes made

1. **[sev:med] Expanded trigger description** — Added "quality pass", "code health check", "code audit", "bug sweep", "codebase review", "lint and fix cycle" to the description. *Why:* A cold-start agent only loads this skill if the description matches the user's request. Missing trigger phrases = missed invocations. The original was too narrow for the variety of ways users ask for code review.

2. **[sev:high] Disambiguated "project root" in Quick Start** — Changed "read README.md and STATUS.md in the project root" to "in the target project (the project you're reviewing, not this skill's repo)". *Why:* An agent encountering this skill cold could confuse the dev-loop skill's own README with the target project's README. This was the single most likely cold-start confusion point.

3. **[sev:med] Clarified Quick Start step numbering** — Rephrased "Work through Steps 1–6" to "Work through the protocol's Steps 1–6" and merged the "write every finding" step into step 4. *Why:* Quick Start had 5 numbered steps that collided with the protocol's 6 numbered steps. An agent could confuse which "Step 3" is being referenced.

4. **[sev:med] Added "verify clean build first" key rule** — New rule telling agents to build before making changes. *Why:* Without a baseline, agents can't distinguish pre-existing failures from failures they introduced. This was completely missing from SKILL.md's key rules.

5. **[sev:med] Added missing-docs fallback guidance** — Added: "If neither file exists, discover the toolchain from manifests and config files." *Why:* Many real projects don't have README.md or STATUS.md. The original gave agents zero guidance for this common case.

6. **[sev:med] Surfaced checklist discipline rule** — Added: "Each step appends its own section. Never delete or edit sections from prior steps." *Why:* This critical rule was buried in DEV-LOOP.md but not surfaced in SKILL.md. An agent that only skims SKILL.md's key rules might violate this.

7. **[sev:med] Replaced vague Sub-Agent Mode with concrete table** — Replaced 4 bullet points with a table mapping each sub-agent to its scope and what the orchestrator passes it. Added size threshold (>20 source files). *Why:* The original was too vague — "spawn one sub-agent per step" without specifying what context each needs. An agent would wing it and either pass too much (flooding context) or too little (sub-agent can't do its job).

8. **[sev:low] Removed "References" section** — Deleted the single-line "References" section pointing to DEV-LOOP.md. *Why:* The agent just read this file because it was triggered. The first line of the Quick Start already says "Read references/DEV-LOOP.md". The References section was dead tokens.

### DEV-LOOP.md — 10 changes made

1. **[sev:high] Added baseline build step (Before You Start §5)** — New step: run build+tests before making changes, record result. *Why:* Without this, the Step 4-5 exit gate ("all tests green") is meaningless if tests were already failing. Agents were also unable to distinguish pre-existing failures from regressions they introduced.

2. **[sev:med] Updated overview ASCII diagram** — Added "(read docs, map project, baseline build)" to DISCOVER phase. *Why:* The diagram is the first thing an agent sees — it should accurately reflect the workflow including the new baseline step.

3. **[sev:med] Added severity to checklist format** — Added `[sev:high|med|low]` tags and a severity guide. *Why:* Without severity, the orchestrator has no way to prioritize findings or make gating decisions. "3 findings" is meaningless without knowing if they're crashes or cosmetic.

4. **[sev:med] Added missing-docs fallback to Before You Start §1** — Added explicit guidance for when README/STATUS don't exist. *Why:* Silent confusion point. An agent finding no README would either stall or skip the step entirely. Now it knows to proceed with toolchain discovery and flag the absence.

5. **[sev:high] Added 5 missing check categories to Step 3** — Added: "Return values actually used" (catches silently discarded results like encode()), "zero/negative numeric args" (catches --times 0), integer overflow/underflow, type coercion, full Error Handling section (4 items), Concurrency & State section (4 items), off-by-one clarification, temp file cleanup. *Why:* The original Step 3 checklist had blind spots for exactly the categories of bugs planted in the fixtures. Specifically: "Return values actually used" directly targets F3b (encode() discarded). "zero/negative numeric args" directly targets F3a (times ≤ 0). The error handling section addresses real-world error swallowing. Concurrency is a major real-world bug category that was completely absent.

6. **[sev:high] Restructured 3E evaluator prompt** — Reorganized from flat list to categorized sections (edge-case inputs, silent failures, cross-function contracts, compositional bugs, habitual oversights). Added "focus on what they MISSED, not re-reporting." Added output quality check. *Why:* The flat list was 13 questions that all sounded similar. Categorization helps the evaluator think systematically. The "process" instruction prevents the evaluator from wasting tokens re-reporting Step 3's existing findings. The "output quality" check specifically targets F3E-type flaws (grammatically broken output).

7. **[sev:med] Expanded Phase B cross-file issue examples** — Added 5 concrete example categories of cross-file issues. *Why:* The original was one vague sentence. An agent doing Phase B needs to know what patterns to look for. The "data transformation disagreements" example directly describes the openclaw-skill F3E flaw (tag case mismatch).

8. **[sev:low] Made context management flexible for small projects** — Added: "For projects under ~10 source files, you can be more flexible." *Why:* The strict "one file at a time" rule is counterproductive for tiny projects where seeing 3 files together would help spot cross-file issues. The rule should scale with project size.

9. **[sev:med] Added baseline comparison to Step 4** — Added "Compare against baseline" to the what-to-check list and updated the goal statement. *Why:* Connects the new baseline step to the build verification step, closing the loop.

10. **[sev:low] Updated reporting template** — Added baseline line and severity counts. *Why:* Aligns the summary format with the new severity tags and baseline tracking.

### Test Results

All 71 structural tests pass after edits. No fixture modifications were made.

### Analysis: Would these changes catch the planted flaws better?

| Flaw | Previous coverage | Improvement |
|------|------------------|-------------|
| F3b (discarded encode) | Implicit in "Decode/parse errors surfaced" — indirect | Now explicit: "Return values actually used — is any function called for a side effect but its result silently discarded?" |
| F3a (times ≤ 0) | Implicit in "Edge cases covered" — vague | Now explicit: "zero/negative numeric args" |
| F3E (empty name output) | Evaluator prompt asked about empty input but buried in flat list | Now categorized under "Edge-case inputs" with explicit "empty string" check, plus "output quality" check under habitual oversights |
| F3E-openclaw (tag case) | Evaluator prompt had the example but Phase B lacked it | Phase B now explicitly lists "data transformation disagreements" as a cross-file pattern |
| F3E-rust (line boundaries) | Evaluator prompt asked about edge cases generally | Evaluator "compositional bugs" category now asks about correct-looking components that interact incorrectly |

### What was NOT changed (and why)

- **Step ordering (1→2→3→3E→4→5→6):** The current order is correct. Docs sync before code review lets the agent understand intent before reading code. Building after review (not before review) is fine because the new baseline step catches pre-existing failures.
- **Step 1/2 content:** Already thorough. The verification categories in Step 1 are comprehensive.
- **Test fixtures:** Not touched — they are test cases, not the skill itself.
- **build.sh / run-tests.sh:** Out of scope for this skill content review pass.
