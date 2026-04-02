# Sales Analytics — Domain Config

Pipeline-specific constants for the Sales Analytics pipeline. Referenced by stage files alongside `_shared/` patterns.

## Data Sources

| Source | Sheet ID | Tab | Notes |
|--------|----------|-----|-------|
| Daily Data (default) | `$DAILY_DATA` | Opportunity | READ-ONLY. Daily Salesforce refresh. |
| Daily Data (forecast) | same | Forecast Accuracy | Snapshot columns for forecast-vs-actuals |
| Plan doc path | `.context/sales-analytics-plan.md` | | |

## Metric Catalog

| Category | Metrics |
|----------|---------|
| Pipeline | Pipeline Created (NB/EB), Weighted Pipeline, Pipeline Velocity |
| Bookings | NB Bookings, Existing Bookings, Total Bookings, Expansion ARR |
| Win/Loss | Win Rate, New Logos, Lost $, Avg Deal Size, Sales Cycle Days |
| Counts | NB Won Count, NB Lost Count, Open Pipeline Count |
| Forecast Accuracy | Dollar Accuracy, Count Accuracy, Deal Accuracy (per forecast level) |

Full definitions: `business-logic/sales/metrics.md`

## Dimensions

Time (week/month/FQ/FY), date anchor (Stage 2 Entry Date for pipeline, Close Date for bookings), Lead Source, Use Case, Segment, Opp Type, Rep

## Lookups Sections

| # | Section | Key Column | Value Columns | Source |
|---|---------|-----------|---------------|--------|
| 1 | Stage Mapping | Stage | Pipeline Category, Detail Category | `data-dictionary.md` |
| 2 | Use Case Mapping | Primary Use Case | Use Case | `data-dictionary.md` |
| 3 | Fiscal Period Mapping | Month Number | Fiscal Quarter, FY Add | `metrics.md` fiscal calendar |

## Sanity Checks

| Check | Rule | Severity |
|-------|------|----------|
| Opp Type coverage | All opps are "New Business" or "Existing Business" | hard-fail |
| No negative NB Amount | Amount >= 0 for New Business | hard-fail |
| New Logos <= NB Won Count | Logos cannot exceed won deal count | warning |
| ADS x Won Count ~ Bookings | Within 5% | warning |
| Sales cycle 30-365 days | Flag values outside range | info |
| Row count preserved | Raw Data = Prepared Data | hard-fail |
| Valid Stage values | Stages 1-6, 9, 10, 11 only | hard-fail |
| Expansion ARR <= Amount (EB) | For Existing Business deals | warning |

Full rules: `business-logic/sales/metrics.md` sanity checks section

## Intentional Deviations

Sales is the baseline pipeline from which shared patterns were extracted. Current notes:

- **deep-dive-triggers:** Sales 4-review.md does not yet have the conditional deep-dive step. The `<!-- SHARED: deep-dive-triggers -->` marker will be added when W4a (consistency fixes) merges.
- **summary-tab-structure:** Uses the standard KPI/Breakdown/Notes structure (shared with Marketing). Modeling is spec-driven and does not use this block.

## Stages

| Order | Stage | Instruction File | Dispatch File | Skip Conditions |
|-------|-------|-----------------|---------------|-----------------|
| 1 | planner | 1-planner.md | inline | never |
| 2 | data-prep | 2-data-prep.md | sales-data-prep | never |
| 3 | analysis | 3-analysis.md | sales-analysis | never |
| 4 | review | 4-review.md | sales-review | Express |

## Context Inlining

| File | Scope |
|------|-------|
| `business-logic/_shared/formula-rules.md` | all stages |
| `business-logic/_shared/anti-patterns.md` | planner, data-prep, analysis |
| `agents/pipelines/sales-analytics/domain-config.md` | all stages |
| `codespecs/scoping-steps.md` | planner |
| `codespecs/plan-doc-format.md` | planner |
| `business-logic/_shared/analysis-patterns.md` | planner |
| `business-logic/sales/data-prep-rules.md` | data-prep |
| `business-logic/sales/data-dictionary.md` | data-prep |
| `business-logic/sales/metrics.md` | analysis, review |

## Ingest Config

| Source Name | Adapter | Params |
|-------------|---------|--------|
| Daily Data | sheets | source: $DAILY_DATA, tab: Opportunity, readOnly: true, numeric_columns: [Amount, Amount Weighted, Order Delta ARR, Days in Stage] |
| Daily Data (forecast) | sheets | source: $DAILY_DATA, tab: Forecast Accuracy, readOnly: true |

---

## Reading Order

Read `business-logic/_shared/formula-rules.md` first (universal).

### All Stages
- `business-logic/_shared/formula-rules.md` — Formula-first principles, approach validation checklist
- `business-logic/_shared/anti-patterns.md` — Known analytical gotchas

### Planner (Stage 1)
- `business-logic/sales/metrics.md` — Metric definitions, fiscal calendar, stage progression, cohort scoping defaults
- `business-logic/_shared/analysis-patterns.md` — Analytical lenses for proactive follow-ups

### Data Prep (Stage 2)
- `business-logic/sales/data-dictionary.md` — Salesforce field mappings, helper column derivations
- `business-logic/sales/data-prep-rules.md` — Standardization rules, calculated columns, quality checks

### Analysis (Stage 3)
- `business-logic/sales/metrics.md` § Sanity Check Rules — Expected ranges and cross-checks

### Review (Stage 4)
- `business-logic/sales/metrics.md` § Sanity Check Rules — Verify against expected ranges
- `business-logic/sales/metrics.md` § Cohort Scoping Defaults — Validate analytical scoping

### Conditional
- `business-logic/sales/forecast-accuracy-metrics.md` — Only when request involves forecast accuracy
- `business-logic/sales/forecast-data-prep-rules.md` — Only when request involves forecast data
- `business-logic/_shared/agent-overload-rubric.md` — Only when proposing pipeline extensions
