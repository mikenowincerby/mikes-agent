# Agent: {{display_name}} Review

- **Role:** Sanity checks, formula verification, Definitions tab, final report
- **Trigger:** Plan doc has Analysis Complete section filled
- **Position:** Agent 4 of 4 in the {{display_name}} pipeline

> **Dispatch Note:** This agent is dispatched as a subagent via `.claude/agents/{{pipeline_name}}-review.md`.
> The CoS uses the Orchestration Protocol — it does not execute these steps directly.
> This file remains as the domain knowledge reference for the review phase.

## References

Read before executing:
- `.context/{{pipeline_name}}-plan.md` — the plan doc (read first, update before handoff)
{{references_list}}

> **Note:** Formatting has been applied by `skills/format-output-sheet.md` in Step 7 of Agent 3. During review, verify that visual formatting is correct (headers styled, numbers right-aligned, chromatic signifiers on Prepared Data, gridlines hidden).

## Pipeline

### Step 1: Verify Formulas

> Follow the verification checklist in `codespecs/inspection-protocol.md`.

### Error Classification

> Use the severity taxonomy from `codespecs/error-handling.md`.

Classify all issues found in Steps 1-2 using this taxonomy.

### Step 2: Run Sanity Checks

From `domain-config.md` → Sanity Checks, verify each:

| Check | Rule | Severity | How to Verify |
|-------|------|----------|---------------|
{{sanity_checks_verify_table}}

Refer to `business-logic/{{domain}}/metrics.md` for threshold values.

**If any check fails:** report the discrepancy to the user. Do NOT finalize until acknowledged.

### Step 2b: Analytical Scoping Checks

These checks verify that the planner's analytical choices are sound — not just that formulas are correct.

| Check | Rule | Action if Failed |
|-------|------|-----------------|
| Summary tab structure | Summary must have Section A (headline KPIs), Section B (breakdowns), Section C (notes) | Flag — Summary without headline KPI block fails the "3-second scan" test |
| Dimension coverage | Every dimension in domain-config → Dimensions appears in ≥1 analysis tab | Flag missing dimensions |
{{domain_scoping_check_rows}}

**If any scoping check fails:** report as a **warning** (not a hard-fail). The analysis is technically correct but analytically misleading. Suggest the fix and let the user decide.

### Step 3: Populate Definitions Tab

> Follow the Definitions tab pattern in `codespecs/definitions-pattern.md`.

### Step 4: Deep-Dive Recommendations (Conditional)

If ANY of these triggers are met, add a "Recommended Follow-Ups" section to the Summary tab:

| Trigger | Condition | Example |
|---------|-----------|---------|
| Outsized contribution | Single dimension >40% of total | One segment = 60% of total |
| Trend reversal | Metric contradicts expected direction | Rate declining despite growing volume |
| Anomaly | Value >2σ from expected range | Value 5x the segment average |
| Sparse segment | Dimension with <3 data points | Category with only 1 record |
| Warning-flagged pattern | Any Step 2b check returned a warning | Scoping concern found |

For each trigger met, recommend a specific follow-up analysis with scope and expected insight.
If no triggers are met, skip this step.

### Step 5: Update Plan Doc + Final Report

Add to `.context/{{pipeline_name}}-plan.md`:
- `## Review:` sanity check results, any issues found and user responses

Present final report to user:
- Sheet URL
- Summary of what was built
- Any caveats or acknowledged issues

## Anti-Patterns

- **DON'T** skip sanity checks — run every one
- **DON'T** claim "done" without reading back actual cell values
- **DON'T** finalize if any sanity check failed without user acknowledgment
{{domain_anti_patterns}}

## Verification

- [ ] Every formula cell resolves without errors
- [ ] All sanity checks pass or are explicitly acknowledged by user
- [ ] Definitions tab is populated with all metrics
- [ ] Data source reference is complete
- [ ] Plan doc updated with review results
- [ ] Final report presented with sheet URL
