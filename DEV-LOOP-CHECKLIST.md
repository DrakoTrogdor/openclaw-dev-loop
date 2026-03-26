# DEV-LOOP-CHECKLIST — Pass 5 (Skill Content Only)

Focus: SKILL.md and references/DEV-LOOP.md ONLY. Do not review or modify build.sh, run-tests.sh, fixtures, or README.md.

## Project Commands
- **Build:** `./build.sh --msg "<description>"`
- **Test:** `./tests/run-tests.sh`
- **Commit:** `./build.sh --msg "<description>"`

## Pass 5 — Skill Content Review

### SKILL.md changes (50 → 28 lines)

- [x] **[sev:med]** Description field missing common trigger phrases → Added: "QA this", "fix my code", "go through this repo", "check this project for bugs", "make sure everything is in order". **Why:** These are natural ways users ask for code review; missing them means the skill doesn't trigger when it should.
- [x] **[sev:med]** Key Rules: 8 rules too many to front-load (agents skim past rule 5) → Consolidated to 5 rules. Removed: "Checklist discipline" (procedural, covered in DEV-LOOP.md), "Step 6 is mandatory" (procedural, covered in DEV-LOOP.md), "Update STATUS.md on commit" (already in DEV-LOOP.md commit section), "Trust boundaries" (already in DEV-LOOP.md). **Why:** Every token in SKILL.md is loaded on every trigger. Procedural details belong in the protocol doc, not the trigger file. 5 numbered rules are scannable; 8 bullet points become a wall.
- [x] **[sev:med]** Sub-Agent Mode table (~15 lines) duplicated guidance already in DEV-LOOP.md → Moved table to DEV-LOOP.md, replaced with 1-line pointer. **Why:** The table is only needed when actually running sub-agents, not on every skill trigger. Moving it saves ~14 lines of context on every invocation.

### DEV-LOOP.md changes (~420 → 387 lines, net after adding sub-agent table)

- [x] **[sev:low]** Context Management section was 12 lines of prose → Replaced with a compact table (7 lines). **Why:** A table is faster to scan and more precise than prose paragraphs. Agents can look up what to hold per-step instantly.
- [x] **[sev:med]** Step 3E "Why this is a separate agent" section (5 lines of motivation) → Removed. **Why:** Motivational text explaining *why* a design decision was made doesn't change agent behavior. Agents need instructions, not persuasion. Dead tokens.
- [x] **[sev:med]** Step 3E evaluator prompt was ~25 lines with nested sub-lists → Compressed to ~10 lines with 4 bullet categories. **Why:** Overly detailed prompts cause pattern-matching instead of thinking. A punchier prompt gives the evaluator room to reason adversarially rather than checking boxes mechanically.
- [x] **[sev:low]** Step 3E "What the evaluator typically catches" list (5 items) → Removed. **Why:** This list biases the evaluator toward finding only the listed patterns. It also overlaps with the evaluator prompt itself. Removing it forces genuine adversarial thinking.
- [x] **[sev:low]** Step 3 "What to check" lists had 30+ items across 6 categories → Compressed to ~20 items across 6 categories. Removed items any competent model checks naturally ("Version/format checks before processing", "No dead or duplicate functions" expanded separately from "unused imports"). Merged related items. **Why:** Shorter checklists get more attention per item. Items like "clean build with no warnings" and "no dead code, unused imports, or unresolved TODO/FIXME/HACK" can be single lines.
- [x] **[sev:low]** Step 1 verification table had 10 rows → Compressed to 7 rows by merging CLI/API surface, merging build/test instructions, removing Dependencies row (agents check manifests naturally). **Why:** Fewer rows = each row gets more attention.
- [x] **[sev:low]** Step 2 "What to check" had 4 items including "Generated docs (man pages, docstrings, OpenAPI descriptions)" → Compressed to 3 items. **Why:** "Generated docs" is too vague to be actionable and overlaps with Step 1's API surface check.
- [x] **[sev:low]** Step 4 had separate "Use the commands" sub-header and 5-item check list → Compressed to 3 lines. **Why:** Step 4 is mechanically simple (run commands, check output). It doesn't need its own sub-sections.
- [x] **[sev:low]** Step 6 had verbose preamble and separate pass/fail section → Compressed. **Why:** Tighter language, same information.
- [x] **[sev:low]** "Before You Start" §3 had 4 lines of bullet points → Compressed to 2 sentences. **Why:** Redundant with §1 which already covers wrapper scripts.
- [x] **[sev:low]** Step 3E "When to use" had 3 bullets with caveats → Compressed to 2 bullets. **Why:** "but note that subtle bugs exist even in small code" is hedging that doesn't change behavior.
- [x] **[sev:med]** Sub-Agent Dispatch Table added from SKILL.md → Placed in Overview section with proper heading. **Why:** This is reference material needed only during execution, not during skill triggering. DEV-LOOP.md is the right home.

### Decisions NOT to change

- **Step 1 vs Step 2 separation:** Kept separate. Step 1 edits docs to match code; Step 2 edits code strings to match behavior. Different edit targets = different steps. Merging would create confusion about which direction edits flow.
- **Flow diagram:** Kept. It's compact (~6 lines) and provides instant orientation for the full protocol. Worth its tokens.
- **Checklist format:** Kept as-is. The `[x]/[ ]` + `[sev:X]` format is close enough to what agents naturally produce. Fighting it would waste more tokens than the format itself.
- **No concrete examples added:** Good findings vs bad findings examples would anchor agents to that specific pattern. Better to let them reason from the category lists.
- **Cross-file issues list in Phase B:** Kept the 5-item list. These are genuinely non-obvious (especially data transformation disagreements) and worth the tokens.

### Test Results
- All 71 structural tests pass (0 failures)
- No files outside SKILL.md and DEV-LOOP.md were modified
