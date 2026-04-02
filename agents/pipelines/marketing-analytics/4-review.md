# Agent: Marketing Analytics Review

- **Role:** Sanity checks, formula verification, Definitions tab, suggested deep-dives, final report
- **Trigger:** Plan doc has Analysis Complete section filled
- **Position:** Agent 4 of 4 in the Marketing Analytics pipeline

## References

Read before executing:
- `.context/marketing-analytics-plan.md` — the plan doc (read first, update before handoff)
- `business-logic/marketing/metrics.md` — sanity check rules, metric definitions
- `business-logic/_shared/formula-rules.md` — formula-first principles

> **Note:** Formatting has been applied by `skills/format-output-sheet.md` in Step 7 of Agent 3. During review, verify that visual formatting is correct (headers styled, numbers right-aligned, chromatic signifiers on Prepared Data, gridlines hidden).

## Pipeline

> Follow the verification checklist in `codespecs/inspection-protocol.md`.

> Use the severity taxonomy from `codespecs/error-handling.md`.
### Step 2: Run Marketing Sanity Checks

From `marketing-metrics.md`, run every check:

| Check | Action |
|-------|--------|
| Row count preserved (Raw Campaign Members = Prepared Data) | Investigate if mismatched |
| Campaign ID join coverage (100%) | Flag unmatched campaign members |
| Opp join coverage (>= 90%) | Flag unresolved opportunity joins |
| Account join coverage (>= 80%) | Flag unresolved account joins |
| MQL count <= Total Members per campaign | Investigate — cannot have more MQLs than members |
| Won Opps <= Total Opps per campaign | Investigate — cannot have more won than total |
| Opp Amount >= 0 | Flag negative amounts |
| Unified fields blank rate < 20% | Flag high blank rates for Title, Department, Level |

**If any check fails:** report the discrepancy to the user. Do NOT finalize until acknowledged.

### Step 2b: Analytical Scoping Checks

These checks verify that the planner's analytical choices are sound — not just that formulas are correct.

| Check | Rule | Action if Failed |
|-------|------|-----------------|
| Cost scoping | For period-specific analyses: cost metrics must use period-scoped campaign costs, not total lifetime costs. See `marketing-metrics.md` cost scoping rule. | Flag — cost-per-X is inflated by including spend from campaigns with zero activity in the period. Report the inflated total vs period-scoped total. |
| Summary tab structure | Summary must have Section A (headline KPIs), Section B (breakdowns), Section C (notes) per `3-analysis.md` Step 4 | Flag — Summary without headline KPI block fails the "3-second scan" test |
| Unmatched member transparency | If unmatched campaign members exist, Summary totals should either include them (with a note) or exclude them (with a note). Silent exclusion is not acceptable. | Flag — readers won't know why Summary total differs from Analysis breakdown totals |
| MQL counting method documented | Summary notes must state whether MQL counting uses `Is MQL+` (snapshot) or `MQLs in Period` (date-based), and why | Flag — without this, readers can't assess MQL accuracy |

**If any scoping check fails:** report as a **warning** (not a hard-fail). The analysis is technically correct but analytically misleading. Suggest the fix and let the user decide.

> Follow the Definitions tab pattern in `codespecs/definitions-pattern.md`.

**Marketing data source reference:**
<!-- DEVIATION: Marketing lists 3 source sheets (vs Sales' 1) in data source reference -->

Use Sheet IDs from plan doc `## Data Sources`:
- Marketing Campaign Data: {Sheet ID from plan doc}
  - Tab: Master Campaign Frontend Data (campaign attributes, costs)
  - Tab: Campaign Members (member-level data)
- Daily Data: {Sheet ID from plan doc} (READ-ONLY)
  - Tab: Opportunity (deal data for joins)
  - Tab: Account (account data for joins)

> Apply deep-dive triggers from `codespecs/deep-dive-triggers.md`.

**Marketing deep-dive additions:**

Additional marketing-specific triggers:
| Trigger | Condition | Example |
|---------|-----------|---------|
| Sparse segment | Dimension with <3 data points | Campaign Type with only 1 campaign |
| Warning-flagged pattern | Any Step 2b check returned a warning | Lifetime costs used for period analysis |

Recommendations must use metrics from `marketing-metrics.md`.

**Examples of good marketing recommendations:**
- "Campaign X has high MQL count but zero SQLs — investigate lead quality via Sort Score distribution"
- "Account Y appears across 4 campaigns — worth a dedicated account-level attribution view"
- "Campaign Type 'Webinar Sponsored' has highest CPA — compare against other types for ROI benchmarking"
- "Department 'Engineering' has lowest MQL conversion — analyze whether targeting or content is the issue"

If no triggers are met, skip this step.

### Step 5: Update Plan Doc + Final Report

Add to `.context/marketing-analytics-plan.md`:
- `## Review:` sanity check results, any issues found and user responses

Present final report to user:
- Sheet URL
- Summary of what was built (tabs, metrics, dimensions)
- Any caveats or acknowledged issues
- Suggested deep-dives (from Step 4)

## Anti-Patterns

- **DON'T** skip sanity checks — run every one
- **DON'T** claim "done" without reading back actual cell values
- **DON'T** finalize if any sanity check failed without user acknowledgment
- **DON'T** skip the deep-dive trigger check — evaluate all 4 triggers before deciding to skip

## Verification

- [ ] Every formula cell resolves without errors
- [ ] All sanity checks pass or are explicitly acknowledged by user
- [ ] Definitions tab is populated with all metrics
- [ ] Data source reference is complete (all 3 source sheets documented)
- [ ] Deep-dive triggers evaluated; recommendations included if any trigger met
- [ ] Plan doc updated with review results
- [ ] Final report presented with sheet URL
