# Agent: Sales Analytics Review

- **Role:** Sanity checks, formula verification, Definitions tab, final report
- **Trigger:** Plan doc has Analysis Complete section filled
- **Position:** Agent 4 of 4 in the Sales Analytics pipeline

> **Dispatch Note:** This agent is dispatched as a subagent via `.claude/agents/sales-review.md`.
> The CoS uses the Orchestration Protocol — it does not execute these steps directly.
> This file remains as the domain knowledge reference for the review phase.

## References

Read before executing:
- `.context/sales-analytics-plan.md` — the plan doc (read first, update before handoff)
- `business-logic/sales/metrics.md` — sanity check rules
- `business-logic/_shared/formula-rules.md` — formula-first principles
- `business-logic/sales/forecast-accuracy-metrics.md` — forecast accuracy sanity checks and metric definitions (forecast accuracy only)

> **Note:** Formatting has been applied by `skills/format-output-sheet.md` in Step 7 of Agent 3. During review, verify that visual formatting is correct (headers styled, numbers right-aligned, chromatic signifiers on Prepared Data, gridlines hidden).

## Pipeline

### Step 1: Verify Formulas

> Follow the verification checklist in `codespecs/inspection-protocol.md`.

> Use the severity taxonomy from `codespecs/error-handling.md`.

### Step 2: Run Sanity Checks

From `metrics.md`, run every check:

| Check | Action |
|-------|--------|
| Opp Type coverage — all opps are "New Business" or "Existing Business" | Flag unknown types |
| No negative Amount on New Business | Flag specific deals |
| New Logos <= NB Closed-Won count | Investigate if exceeded |
| NB ADS x NB Won Count ~ NB Bookings (within 5%) | Flag — outlier deals may skew average |
| Sales cycle 30-365 days typical | Flag values outside range |
| Row count preserved (Raw = Prepared) | Investigate if mismatched |
| All Stage values valid (1-6, 9, 10, 11) | Flag unknown stages |
| Expansion ARR <= Amount for Existing Business | Investigate data mismatch |

**If any check fails:** report the discrepancy to the user. Do NOT finalize until acknowledged.

Classify all issues found in Steps 1-2 using the severity taxonomy above.

### Step 2b: Analytical Scoping Checks

These checks verify that the planner's analytical choices are sound — not just that formulas are correct.

| Check | Rule | Action if Failed |
|-------|------|-----------------|
| Pipeline cohort scoping | For "pipeline analysis": cohort should exclude QualifiedOut (Stage 11). See `metrics.md` Cohort Scoping Defaults. | Flag — pipeline is inflated by dead deals. Report the QO count and dollar amount. |
| Deal list scoping | Top N deal lists should exclude terminal states (QO, Closed-Lost) unless analysis explicitly covers those states | Flag — dead deals in deal list are misleading for pipeline management |
| ADS denominator | Average Deal Size should exclude QualifiedOut deals | Flag — QO deals distort ADS (their Amount is an estimate, not a validated price) |
| Summary tab structure | Summary must have Section A (headline KPIs), Section B (breakdowns), Section C (notes) per `3-analysis.md` Step 4 | Flag — Summary without headline KPI block fails the "3-second scan" test |
| Cohort vs analysis type alignment | If cohort includes QO, analysis type should be labeled "full funnel" or "stage distribution", not "pipeline analysis" | Flag — mislabeled analysis type sets wrong expectations |

**If any scoping check fails:** report as a **warning** (not a hard-fail). The analysis is technically correct but analytically misleading. Suggest the fix and let the user decide.

> Follow the Definitions tab pattern in `codespecs/definitions-pattern.md`.

### Step 4: Deep-Dive Recommendations (Conditional)

If ANY of these triggers are met, add a "Recommended Follow-Ups" section to the Summary tab:

| Trigger | Condition | Example |
|---------|-----------|---------|
| Outsized contribution | Single dimension >40% of total | One segment = 60% of pipeline |
| Trend reversal | Metric contradicts expected direction | Win rate declining despite growing pipeline |
| Anomaly | Value >2σ from expected range | Deal size 5x the segment average |
| Sparse segment | Dimension with <3 data points | Use Case with only 1 deal |
| Warning-flagged pattern | Any Step 2b check returned a warning | QO deals found in pipeline cohort |

For each trigger met, recommend a specific follow-up analysis with scope and expected insight.
If no triggers are met, skip this step.

### Step 5: Update Plan Doc + Final Report

Add to `.context/sales-analytics-plan.md`:
- `## Review:` sanity check results, any issues found and user responses

Present final report to user:
- Sheet URL
- Summary of what was built
- Any caveats or acknowledged issues

## Anti-Patterns

- **DON'T** skip sanity checks — run every one
- **DON'T** claim "done" without reading back actual cell values
- **DON'T** finalize if any sanity check failed without user acknowledgment

## Verification

- [ ] Every formula cell resolves without errors
- [ ] All sanity checks pass or are explicitly acknowledged by user
- [ ] Definitions tab is populated with all metrics
- [ ] Data source reference is complete
- [ ] Plan doc updated with review results
- [ ] Final report presented with sheet URL

---

## Forecast Accuracy

When the analysis type is forecast accuracy, follow the standard pipeline steps above with these additions.

### Additional References

- `business-logic/sales/forecast-accuracy-metrics.md` — sanity checks and metric definitions for forecast accuracy

### Modified Pipeline

**Step 2 (Run Sanity Checks) — Forecast Accuracy Checks:**

In addition to standard sanity checks (where applicable), run forecast-specific checks from `forecast-accuracy-metrics.md`:

| Check | Threshold | Action if Failed |
|-------|-----------|-----------------|
| Dollar Accuracy | 0% – 200% | Flag anything outside range — may indicate data issues or extreme forecast miss |
| Deal Accuracy | Must be <= 100% | Cannot close more forecasted deals than were forecasted — investigate |
| Count Accuracy | Can exceed 100% | Flag > 300% — extreme unforecasted deal volume |
| Forecasted $ per level | Must be > 0 | If 0, the forecast level had no deals in forecast — report, do not compute accuracy |
| Snapshot availability | Both snapshots must exist | If missing, analysis should not have proceeded — flag as pipeline error |

**Step 3 (Populate Definitions Tab) — Forecast Accuracy Entries:**

For every forecast accuracy metric in the analysis, add to the Definitions tab:

| Column | Content |
|--------|---------|
| Metric Name | e.g., "Dollar Accuracy (Commit)" |
| Plain-Language Formula | e.g., "Total closed-won dollars in period / Total forecasted dollars in Commit level" |
| Cell References | e.g., "Analysis!B3 (numerator: Prepared Data SUMIFS on cols X,Y,Z; denominator: SUMIFS on cols A,B)" |
| Forecast Level | Commit, Commit + Most Likely, or Commit + Most Likely + Best Case |
| Forecast Snapshot Date | e.g., "2027-02-01" |
| Actuals Snapshot Date | e.g., "2027-05-01" |
| Computation Method | "Sheet Formula" or "Sheet Formula + IFERROR" |
