# DEV-LOOP-CHECKLIST — Pass 6 (README Rewrite)

Focus: README.md only. Rewritten to be accurate against SKILL.md and DEV-LOOP.md after Passes 4-5.

## Project Commands
- **Build:** `./build.sh --msg "<description>"`
- **Test:** `./tests/run-tests.sh`
- **Commit:** `./build.sh --msg "<description>"`

## Pass 6 — README.md Rewrite

### What changed

1. **Project structure tree updated.** Added `DEV-LOOP-CHECKLIST.md` (was missing from tree). Consolidated fixture file listings to be more compact (e.g. `README.md, STATUS.md, build.sh, test.sh` on one line). Removed redundant description arrows where file names are self-explanatory.

2. **"What lives where" table updated.** SKILL.md description now says "5 key rules" (was unspecified). DEV-LOOP.md description now mentions "sub-agent dispatch table, checklist format, evaluator prompt" — reflecting that the dispatch table moved from SKILL.md to DEV-LOOP.md in Pass 5.

3. **Step table updated.** Added details to each step that were missing: "Before You Start" now mentions baseline build and creating the checklist. Step 3 now explicitly lists "Phase A" and "Phase B" and the priority rule (core source files first, tooling second). Steps 1 and 2 now clarify which direction edits flow (docs→match code vs source strings→match behavior).

4. **Key Rules section added.** The 5 numbered rules from SKILL.md are now explicitly listed in the README. The old README had a "Key Design Principles" section at the bottom that covered some of these but not all, and didn't match the consolidated rule set from Pass 5.

5. **Trigger phrases documented.** The "What the Skill Does" section now lists example trigger phrases from SKILL.md's description field ("QA this", "fix my code", "check this project for bugs", etc.) — these were added in Pass 5 but the README didn't reflect them.

6. **Sub-Agent Mode section compressed.** Now a 2-line section pointing to DEV-LOOP.md instead of duplicating guidance. Matches SKILL.md's 1-line pointer approach from Pass 5.

7. **Self-improvement section restructured.** Added a "What to improve and what NOT to improve" table making it explicit that SKILL.md and DEV-LOOP.md are the primary improvement targets, not build.sh/run-tests.sh/fixtures. Separated "Adding a new fixture" from "Adding a flaw to an existing fixture" for clarity.

8. **Design Principles section trimmed.** Removed the Anthropic citation link from the context discipline bullet (redundant with the Background section). Removed "Harness design" explanation — it's self-evident from the bullet text. Tighter language throughout.

9. **Planted flaws tables verified.** All 3 fixtures × 6 flaws = 18 total flaws verified against actual source code, test.sh assertions, and run-tests.sh integration assertions. All table entries are accurate. No changes needed.

10. **Build/test/commit section verified.** All commands, auto-detection logic, and pipeline steps verified against actual build.sh code. No changes needed to the substance; minor wording tightened.

### What did NOT change

- **SKILL.md** — not modified (authoritative source)
- **references/DEV-LOOP.md** — not modified (authoritative source)
- **build.sh** — not modified
- **tests/run-tests.sh** — not modified
- **tests/fixtures/** — not modified (any of them)
- **Planted flaws tables** — content unchanged, verified accurate

### Test Results
- All 71 structural tests pass (0 failures)
- No files outside README.md and DEV-LOOP-CHECKLIST.md were modified
