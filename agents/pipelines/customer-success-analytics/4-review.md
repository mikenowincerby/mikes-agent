# Agent: Customer Success Analytics Review

- **Role:** Sanity checks, formula verification, Definitions tab, final report
- **Trigger:** Plan doc has Analysis Complete section filled
- **Position:** Agent 4 of 4 in the Customer Success Analytics pipeline

> **Dispatch Note:** This agent is dispatched as a subagent via `.claude/agents/customer-success-analytics-review.md`.
> The CoS uses the Orchestration Protocol — it does not execute these steps directly.
> This file remains as the domain knowledge reference for the review phase.

## References

Read before executing:
- `.context/customer-success-analytics-plan.md` — the plan doc (read first, update before handoff)
- `agents/pipelines/customer-success-analytics/domain-config.md § Reading Order`
- `business-logic/customer-success/metrics.md`
- `business-logic/_shared/analysis-patterns.md`

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
| Row count preserved (Accounts) | Raw Account = Prepared Data - Accounts | hard-fail | Compare COUNTA on raw vs prepared |
| Row count preserved (Order Lines) | Raw Order Line = Prepared Data - Order Lines | hard-fail | Compare COUNTA on raw vs prepared |
| Account ID join coverage (Order Lines) | >= 95% of Order Line Account IDs match Account tab | hard-fail | COUNTIFS on unmatched IDs |
| Account ID join coverage (Opportunity) | >= 90% of Opp Account IDs match Account tab | warning | COUNTIFS on unmatched IDs |
| GDR range | 0% <= GDR <= 100% per period | hard-fail | Read Summary tab GDR values |
| NDR >= GDR | NDR must equal or exceed GDR per period | hard-fail | Compare NDR and GDR cells |
| NDR range | NDR > 150% is unusual | warning | Read Summary tab NDR values |
| Churned ARR <= Total ARR | Cannot churn more than exists | hard-fail | Compare churned vs total ARR cells |
| CSQL count <= EB opp count | CSQLs subset of Existing Business opps (after Stage 2 filter) | hard-fail | Compare CSQL count vs EB opp count |
| LOI excluded | Opportunity Type "LOI" excluded from CSQL counts | hard-fail | Verify CSQL filter criteria exclude LOI |
| Services Swap excluded | Services Swap Opp = TRUE excluded from CSQL counts | hard-fail | Verify CSQL filter criteria exclude Services Swap |
| Account Health coverage | < 20% blank for active customers | warning | COUNTBLANK / COUNTA on Account Health column for active customers |
| Renewal Date coverage | < 30% blank for active customers | warning | COUNTBLANK / COUNTA on Renewal Date column for active customers |
| Renewal match rate | > 50% of expiring lines matched | info | Count matched vs total expiring lines |
| ARR field validation | Confirm Delta ARR = Exit ARR - Entry ARR | warning | Spot-check 10 rows: Delta ARR = Exit ARR - Entry ARR |

Refer to `business-logic/customer-success/metrics.md` for threshold values.

**If any check fails:** report the discrepancy to the user. Do NOT finalize until acknowledged.

### Step 2b: Analytical Scoping Checks

These checks verify that the planner's analytical choices are sound — not just that formulas are correct.

| Check | Rule | Action if Failed |
|-------|------|-----------------|
| Summary tab structure | Summary must have Section A (headline KPIs), Section B (breakdowns), Section C (notes) | Flag — Summary without headline KPI block fails the "3-second scan" test |
| Dimension coverage | Every dimension in domain-config → Dimensions appears in ≥1 analysis tab | Flag missing dimensions |
| Is the analysis scoped to active customers only (Is Active Customer = "Yes")? | If health/churn analysis includes non-customers, results are misleading | warning |
| Are LOI and Services Swap opps excluded from CSQL counts? | These are not real expansion pipeline | hard-fail |
| Is the renewal matching window (90 days) appropriate for this analysis? | Window affects GDR/NDR accuracy | info |

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

Add to `.context/customer-success-analytics-plan.md`:
- `## Review:` sanity check results, any issues found and user responses

Present final report to user:
- Sheet URL
- Summary of what was built
- Any caveats or acknowledged issues

## Anti-Patterns

- **DON'T** skip sanity checks — run every one
- **DON'T** claim "done" without reading back actual cell values
- **DON'T** finalize if any sanity check failed without user acknowledgment
**AP-CS1: Mixing account-level and line-level granularity.** Don't compute GDR/NDR from account-level ARR — use Subskribe Order Line Entry/Exit ARR for contract-level precision. Account ARR is a snapshot, not a cohort-ready metric.

**AP-CS2: Including non-customers in health distribution.** Always filter to Is Active Customer = "Yes" for Account Health Distribution. Prospects and Opportunities skew the distribution.

**AP-CS3: Counting CSQLs without Stage 2 threshold.** A CSQL must have Stage 2. Discovery Start Date populated — without it, the opportunity hasn't entered real pipeline. This matches the sales pipeline threshold rule.

**AP-CS4: Ignoring LOI and Services Swap exclusions.** LOI (Letter of Intent) and Services Swap opportunities must be excluded from CSQL counts. They are not real expansion pipeline.

## Verification

- [ ] Every formula cell resolves without errors
- [ ] All sanity checks pass or are explicitly acknowledged by user
- [ ] Definitions tab is populated with all metrics
- [ ] Data source reference is complete
- [ ] Plan doc updated with review results
- [ ] Final report presented with sheet URL
