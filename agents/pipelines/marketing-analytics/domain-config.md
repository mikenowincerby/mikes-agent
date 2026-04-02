# Marketing Analytics — Domain Config

Pipeline-specific constants for the Marketing Analytics pipeline. Referenced by stage files alongside `_shared/` patterns.

## Data Sources

| Source | Sheet ID | Tab | Notes |
|--------|----------|-----|-------|
| Marketing Campaign Data | `$MARKETING_DATA` | Campaign Members | Skip row 1 metadata, headers at row 2. Primary entity (9,381 rows). |
| Marketing Campaign Data | same | Campaign | Campaign master data: ID, name, type, dates, cost (91 rows). Preferred source for Campaign Mapping. |
| Marketing Campaign Data | same | Leads | Lead lifecycle dates incl. SAL/SQL, lead source, create date, touch stage 1 date (12,705 rows). Always ingested. |
| Marketing Campaign Data | same | Contacts | Contact lifecycle dates incl. SAL/SQL, lead source, touch stage 1 date, C Lead Start, C Opportunity Start, converted from lead (30,431 rows). Always ingested. |
| Marketing Campaign Data | same | Master Campaign Frontend Data | Aggregate campaign metrics + costs. Fallback if Campaign tab unavailable. |
| Daily Data | `$DAILY_DATA` | Opportunity | Deal data for joins. READ-ONLY. |
| Plan doc path | `.context/marketing-analytics-plan.md` | | |

> **IMPORTRANGE alternative:** For persistent workbench sheets that need live data, IMPORTRANGE can be used instead of copying raw data. This keeps the workbench connected to the source and avoids stale snapshots. When using IMPORTRANGE, skip the RAW/USER_ENTERED rewrite step.

## Metric Catalog

| Category | Metrics |
|----------|---------|
| Volume | Total Members, Net New Leads, MQLs, SQLs, SALs |
| Opportunities | Opps from Campaign, Opp Value, Won Opps, Won Value |
| Conversion | MQL Conv Rate, SQL Conv Rate, SAL Conv Rate, Opp Conv Rate |
| Cost | CPA, Cost per MQL, Cost per SQL, Cost per SAL, Campaign ROI |
| Velocity | Days Lead→MQL, Days MQL→SAL, Days SAL→SQL, Days SQL→Opp, Days Lead→Opp |
| Quality | Average Sort Score |

Full definitions: `business-logic/marketing/metrics.md`

## Dimensions

Campaign Name/Type, Time (fiscal), Origin Type, Lifecycle Stage, Department, Level, Account, Lead Source, New vs Previously Engaged

## Lookups Sections

| # | Section | Columns | Type | Source |
|---|---------|---------|------|--------|
| 1 | Campaign Lookup | A-G | Data table from Raw Campaign Data | Campaign 18 Digit ID, Campaign ID, Name, Type, Start Date, End Date, Actual Cost |
| 2 | Opportunity Lookup | I-O | Data table from Raw Opportunities | Opp ID, Account, Stage, Amount, Close Date, Type, Segment |
| 3 | Account Lookup | Q-S | Deduplicated from Raw Opportunities | Account ID, Name, Segment |
| 4 | Lifecycle Stage Mapping | U-Z | Hardcoded | Stage, Category, Rank, Is MQL+, Is SQL+, Is SAL+ |
| 5 | Fiscal Period Mapping | AB-AD | Hardcoded | Month Number, Fiscal Quarter, FY Add |
| 6 | Campaign Type Mapping | AF-AG | Placeholder | User-defined grouping |
| 7 | Lead Lifecycle Mapping | AI-AQ | Data table from Raw Leads | ADMIN Lead ID 18 Digit, SAL Start, SAL End, SQL Start, SQL End, Lifecycle Stage, Lead Source, Create Date, Touch Stage 1 Date |
| 8 | Contact Lifecycle Mapping | AS-BC | Data table from Raw Contacts | ADMIN Contact ID 18 Digit, C SAL Start, C SAL End, C SQL Start, C SQL End, Lifecycle Stage, Lead Source, Touch Stage 1 Date, C Lead Start, C Opportunity Start, Converted from Lead |

## Sanity Checks

| Check | Rule | Severity |
|-------|------|----------|
| Row count preserved | Raw Campaign Members = Prepared Data | hard-fail |
| Campaign ID join coverage | 100% | hard-fail |
| Opp join coverage | >= 90% | warning |
| Account join coverage | >= 80% | warning |
| MQL count <= Total Members | Per campaign | hard-fail |
| Won Opps <= Total Opps | Per campaign | hard-fail |
| Opp Amount >= 0 | No negative amounts | hard-fail |
| Unified fields blank rate | < 20% for Title, Department, Level | warning |
| Lead ID join coverage | >= 90% of non-blank Lead IDs match Raw Leads | warning |
| Contact ID join coverage | >= 90% of non-blank Contact IDs match Raw Contacts | warning |
| Velocity reasonableness | All velocity columns positive and < 365 days | warning |
| Lead Source coverage | % of members with non-blank Unified Lead Source | info |

Full rules: `business-logic/marketing/metrics.md` sanity checks section

## Intentional Deviations

| Deviation | Reason |
|-----------|--------|
| Multi-source ingest (5+ tabs) | Marketing requires campaign + members + opportunity + leads + contacts data joined together, unlike Sales' single-source model. Leads, Contacts, and Campaign tabs are always ingested. |
| IMPORTRANGE alternative for workbench models | Persistent workbench sheets (referenced in `business-logic/models/marketing-workbench/`) can use IMPORTRANGE instead of copying data, keeping the sheet connected to live source data. When using IMPORTRANGE, skip RAW/USER_ENTERED rewrite. |
| Model registry reference | Marketing workbench models are registered at `business-logic/models/marketing-workbench/`. Model specs define ingestion mode, tab structure, and calculated columns for each workbench model. |
| MQL counting method choice | Three approaches: "ever MQL'd" (LEN(MQL Start Date)>0, matches frontend), Is MQL+ snapshot, and MQLs in Period date-based. Agent must check MQL date coverage and select method per `3-analysis.md`. Not applicable to other pipelines. |
| SUMPRODUCT over COUNTIFS | All analysis tabs must use SUMPRODUCT instead of COUNTIFS. COUNTIFS gives incorrect results on large formula-heavy Google Sheets (known bug). Use `LEN(cell)>0` instead of `<>""` for non-blank checks. |
| Pre-computed lifecycle enrichment | Unified MQL/SAL/SQL Start Dates are pre-computed in Python (4-source cascade: CM Contact → CM Lead → Raw Contacts → Raw Leads) and pasted as static values. INDEX/MATCH formulas exceed resource limits on large sheets. |
| Conditional deep-dive with examples | Review agent uses the same trigger conditions as other pipelines but includes domain-specific recommendation examples (e.g., Sort Score distribution, account-level attribution). |
| Cost Scoping Rule | Period-specific analyses must use period-scoped costs per `marketing-metrics.md`, not lifetime costs. Unique to Marketing. |

## Stages

| Order | Stage | Instruction File | Dispatch File | Skip Conditions |
|-------|-------|-----------------|---------------|-----------------|
| 1 | planner | 1-planner.md | inline | never |
| 2 | data-prep | 2-data-prep.md | marketing-data-prep | never |
| 3 | analysis | 3-analysis.md | marketing-analysis | never |
| 4 | review | 4-review.md | marketing-review | Express |

## Context Inlining

| File | Scope |
|------|-------|
| `business-logic/_shared/formula-rules.md` | all stages |
| `business-logic/_shared/anti-patterns.md` | planner, data-prep, analysis |
| `agents/pipelines/marketing-analytics/domain-config.md` | all stages |
| `codespecs/scoping-steps.md` | planner |
| `codespecs/plan-doc-format.md` | planner |
| `business-logic/_shared/analysis-patterns.md` | planner |
| `business-logic/marketing/data-prep-rules.md` | data-prep |
| `business-logic/marketing/data-dictionary.md` | data-prep |
| `business-logic/marketing/metrics.md` | analysis, review |

## Ingest Config

| Source Name | Adapter | Params |
|-------------|---------|--------|
| Campaign Members | sheets | source: $MARKETING_DATA, tab: Campaign Members, readOnly: true |
| Campaign | sheets | source: $MARKETING_DATA, tab: Campaign, readOnly: true |
| Leads | sheets | source: $MARKETING_DATA, tab: Leads, readOnly: true |
| Contacts | sheets | source: $MARKETING_DATA, tab: Contacts, readOnly: true |
| Master Campaign Frontend Data | sheets | source: $MARKETING_DATA, tab: Master Campaign Frontend Data, readOnly: true |
| Daily Data (Opportunity) | sheets | source: $DAILY_DATA, tab: Opportunity, readOnly: true |

---

## Reading Order

Read `business-logic/_shared/formula-rules.md` first (universal).

### All Stages
- `business-logic/_shared/formula-rules.md` — Formula-first principles, approach validation checklist
- `business-logic/_shared/anti-patterns.md` — Known analytical gotchas

### Planner (Stage 1)
- `business-logic/marketing/metrics.md` — Lifecycle hierarchy, metric definitions, dimensions, fiscal calendar
- `business-logic/_shared/analysis-patterns.md` — Analytical lenses (§ Marketing Lenses)

### Data Prep (Stage 2)
- `business-logic/marketing/data-dictionary.md` — Multi-source field mappings
- `business-logic/marketing/data-prep-rules.md` — Lead/contact disambiguation, tiered calculations

### Analysis (Stage 3)
- `business-logic/marketing/metrics.md` § Sanity Checks — Expected ranges and coverage thresholds

### Review (Stage 4)
- `business-logic/marketing/metrics.md` § Sanity Checks — Verify against expected ranges
- `business-logic/marketing/metrics.md` § Metrics — Validate formula references use helper columns

### Conditional
- `business-logic/_shared/agent-overload-rubric.md` — Only when proposing pipeline extensions

### Model Specs (when building workbench models)
- `models/marketing-workbench/spec.md` — Marketing workbench model specification
