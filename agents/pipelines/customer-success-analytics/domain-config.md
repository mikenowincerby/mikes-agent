# Customer Success Analytics — Domain Config

Pipeline-specific constants for the Customer Success Analytics pipeline. Referenced by stage files alongside `_shared/` patterns.

## Data Sources

| Source | Sheet ID | Tab | Notes |
|--------|----------|-----|-------|
| CS Data (Opportunity) | `$CS_DATA` | Opportunity | READ-ONLY. Daily Salesforce refresh. Opp-level CSM sourcing, stages, ARR delta. |
| CS Data (Account) | `$CS_DATA` | Account | READ-ONLY. Daily Salesforce refresh. Account health, lifecycle, CSM, renewal dates. |
| CS Data (Subskribe Order Line) | `$CS_DATA` | Subskribe Order Line | READ-ONLY. Daily Salesforce refresh. Contract-level ARR, renewal cohorts. |
| CS Data (User) | `$CS_DATA` | User | READ-ONLY. Daily Salesforce refresh. User ID → Name mapping for CSM resolution. |
| Plan doc path | `.context/customer-success-analytics-plan.md` | | |

## Metric Catalog

| Category | Metrics |
|----------|---------|
| Retention | GDR (Gross Dollar Retention), NDR (Net Dollar Retention), Contraction Rate, Churn Rate |
| Expansion | CSQLs ($), CSQL Count, CSQL Conversion Rate, CSQL Won Value |
| Leading Indicators | Account Health Distribution, TTV (future), Engagement Score (future) |

Full definitions: `business-logic/customer-success/metrics.md`

## Dimensions

- **Time:** Month (YYYYMM), Fiscal Quarter (FY20XX QN), Fiscal Year (FY20XX)
- **Date anchors:** Line End Date (GDR/NDR cohort), Renewal Date (churn cohort), Close Date (CSQLs)
- **Company Segment:** Commercial, Enterprise, Mid-Market, SMB, Strategic
- **Customer Success Manager:** From Account tab
- **Use Case:** Mapped from Primary Use Case / Account Use Case (Social Media Access, Access Management, Identity Lifecycle Management, Other)
- **CS Package:** Legacy, Premium, Standard
- **Expansion Potential:** Cross Sell, None Today, Upsell
- **Account Health:** Positive, Slightly Positive, Neutral, Slightly Negative, Negative

## Lookups Sections

| # | Section | Key Column | Value Columns | Source |
|---|---------|-----------|---------------|--------|
| 1 | Account Lookup | ADMIN Acct ID 18 Digit | Account Name, Customer Lifecycle Stage, CS Package, CSM, ARR, Renewal Date, Account Health, Use Case, Company Segment, Expansion Potential | Raw Account |
| 2 | Opportunity Lookup | ADMIN Opp ID 18 Digit | ADMIN Acct ID, Stage, Amount, Close Date, Opp Type, CSM Sourced, CSM Created, Lead Source Attribution, Company Segment, Stage 2 Start Date, Order Delta ARR, Renewal vs Expansion | Raw Opportunity |
| 3 | Use Case Mapping | Use Case (raw) | Use Case (mapped) | Static (same as sales) |
| 4 | Fiscal Period Mapping | Month Number | Fiscal Quarter, Month in Quarter, FY Add | Static (same as sales) |
| 5 | Customer Lifecycle Mapping | Customer Lifecycle Stage | Is Active Customer, Lifecycle Rank | Static |
| 6 | Account Health Mapping | Account Health | Health Rank, Health Category | Static |
| 7 | Renewal Window Config | Parameter | Value | Static |
| 8 | User Lookup | User ID_18 | First Name, Last Name, CSM Name, Title | Raw User |

## Sanity Checks

| Check | Rule | Severity |
|-------|------|----------|
| Row count preserved (Accounts) | Raw Account = Prepared Data - Accounts | hard-fail |
| Row count preserved (Order Lines) | Raw Order Line = Prepared Data - Order Lines | hard-fail |
| Account ID join coverage (Order Lines) | >= 95% of Order Line Account IDs match Account tab | hard-fail |
| Account ID join coverage (Opportunity) | >= 90% of Opp Account IDs match Account tab | warning |
| GDR range | 0% <= GDR <= 100% per period | hard-fail |
| NDR >= GDR | NDR must equal or exceed GDR per period | hard-fail |
| NDR range | NDR > 150% is unusual | warning |
| Churned ARR <= Total ARR | Cannot churn more than exists | hard-fail |
| CSQL count <= EB opp count | CSQLs subset of Existing Business opps (after Stage 2 filter) | hard-fail |
| LOI excluded | Opportunity Type "LOI" excluded from CSQL counts | hard-fail |
| Services Swap excluded | Services Swap Opp = TRUE excluded from CSQL counts | hard-fail |
| Account Health coverage | < 20% blank for active customers | warning |
| Renewal Date coverage | < 30% blank for active customers | warning |
| Renewal match rate | > 50% of expiring lines matched | info |
| ARR field validation | Confirm Delta ARR = Exit ARR - Entry ARR | warning |

Full rules: `business-logic/customer-success/metrics.md` sanity checks section

## Intentional Deviations

| Deviation | Reason |
|-----------|--------|
| Multi-source ingest (3 tabs from 1 sheet) | CS requires Account + Opportunity + Order Line data joined together. Follows marketing multi-source pattern. |
| Two Prepared Data tabs | Account-level and order-line-level have different row granularities — cannot flatten without losing granularity or exploding rows. |
| Compute-and-push for renewal matching (Tier 3) | Cross-row matching (expiring line → renewal line by Account ID + date proximity) exceeds sheet formula capability. |
| Configurable renewal window in Lookups | 90-day assumption should be user-editable via Lookups tab. |
| Placeholder metrics (TTV, Engagement Score) | Defined in domain-config but flagged as future state — no data source yet. |

## Inspection Overrides

| Stage | Check | Severity |
|-------|-------|----------|
| data-prep | Account Lookup join rate >= 95% for Order Lines | hard-fail |
| data-prep | Compute-and-push renewal matching completed with > 50% match rate | warning |
| analysis | GDR <= 100% and NDR >= GDR for each period | hard-fail |
| analysis | Churned ARR < Total ARR | hard-fail |

## Stages

| Order | Stage | Instruction File | Dispatch File | Skip Conditions |
|-------|-------|-----------------|---------------|-----------------|
| 1 | planner | 1-planner.md | inline | never |
| 2 | data-prep | 2-data-prep.md | customer-success-analytics-data-prep | never |
| 3 | analysis | 3-analysis.md | customer-success-analytics-analysis | never |
| 4 | review | 4-review.md | customer-success-analytics-review | Express |

## Context Inlining

| File | Scope |
|------|-------|
| `business-logic/_shared/formula-rules.md` | all stages |
| `business-logic/_shared/anti-patterns.md` | planner, data-prep, analysis |
| `agents/pipelines/customer-success-analytics/domain-config.md` | all stages |
| `codespecs/scoping-steps.md` | planner |
| `codespecs/plan-doc-format.md` | planner |
| `business-logic/_shared/analysis-patterns.md` | planner |
| `business-logic/customer-success/data-prep-rules.md` | data-prep |
| `business-logic/customer-success/data-dictionary.md` | data-prep |
| `business-logic/customer-success/metrics.md` | analysis, review |

## Ingest Config

| Source Name | Adapter | Params |
|-------------|---------|--------|
| CS Data (Opportunity) | sheets | source: $CS_DATA, tab: Opportunity, readOnly: true, numeric_columns: [Amount, Subskribe Order Delta ARR] |
| CS Data (Account) | sheets | source: $CS_DATA, tab: Account, readOnly: true, numeric_columns: [ARR] |
| CS Data (Subskribe Order Line) | sheets | source: $CS_DATA, tab: Subskribe Order Line, readOnly: true, numeric_columns: [Quantity, TCV, Entry ARR, Exit ARR, Delta ARR] |
| CS Data (User) | sheets | source: $CS_DATA, tab: User, readOnly: true, numeric_columns: [] |

---

## Reading Order

Read `business-logic/_shared/formula-rules.md` first (universal).

### All Stages
- `business-logic/_shared/formula-rules.md` — Formula-first principles, approach validation checklist
- `business-logic/_shared/anti-patterns.md` — Known analytical gotchas

### Planner (Stage 1)
- `business-logic/customer-success/metrics.md` — Metric definitions, fiscal calendar, retention/expansion formulas, dimensions
- `business-logic/_shared/analysis-patterns.md` — Analytical lenses for proactive follow-ups

### Data Prep (Stage 2)
- `business-logic/customer-success/data-dictionary.md` § Helper Fields
- `business-logic/customer-success/data-prep-rules.md` § Multi-Source Ingest, § Two Prepared Data Tabs, § Calculated Columns, § Compute-and-Push Spec, § Data Quality Checks

### Analysis (Stage 3)
- `business-logic/customer-success/metrics.md` § Retention Metrics, § Expansion Metrics, § Leading Indicators, § Sanity Check Rules

### Review (Stage 4)
- `business-logic/customer-success/metrics.md` § Sanity Check Rules — Verify against expected ranges
- `business-logic/customer-success/metrics.md` § Retention Metrics — Validate GDR/NDR methodology

### Conditional
- `skills/compute-and-push.md` — Only when analysis includes GDR/NDR
- `business-logic/_shared/agent-overload-rubric.md` — Only when proposing pipeline extensions
