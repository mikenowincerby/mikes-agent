# Metrics Explorer

A complete catalog of all defined metrics across Sales, Marketing, and Customer Success domains. Each metric includes its formula, type, dimensions, and which pipeline uses it.

**Source files:** Metrics are defined in `business-logic/{domain}/metrics.md`. This explorer is a curated index — for the most current definitions, check the source files directly.

---

## Fiscal Calendar (all domains)

All three domains share the same fiscal calendar:

| Rule | Definition |
|------|-----------|
| Fiscal Year | Calendar year + 1. Feb 2025 = FY2026. |
| FY Start | February 1 |
| FY End | January 31 |
| Q1 | February -- April |
| Q2 | May -- July |
| Q3 | August -- October |
| Q4 | November -- January |

**January edge case:** January belongs to the *prior* fiscal year's Q4. Jan 2026 = FY2026 Q4 (not FY2027).

**Deriving fiscal period from a date:**
- If month >= 2: FY = calendar year + 1
- If month == 1: FY = calendar year
- FY Add: January = 0, all other months = 1

**Quarter Label format:** `FY2026 Q1` (always include FY prefix)

Source: `business-logic/sales/metrics.md` (canonical), referenced by marketing and CS.

---

## Sales Analytics

Pipeline: `agents/pipelines/sales-analytics/`
Source: `business-logic/sales/metrics.md` (228 lines)
Data source: Daily Data sheet (Opportunity tab)

### Pipeline Creation Metrics

Measured by **Stage 2 Entry Date** (when opportunity entered pipeline). Always use Stage 2. Discovery Start Date, not Created Date.

| Metric | Formula | Type | Dimensions |
|--------|---------|------|------------|
| PipeCreate Count | `COUNTIFS(Stage 2 Entry Date, [range], Stage, "<>"&"1. Lead Verification")` | Count | Opp Type, Lead Source, Use Case |
| PipeCreate ADS | `AVERAGEIFS(Amount, [date anchor], [range], Amount, ">"&0)` | Currency | Opp Type, Lead Source, Use Case |
| PipeCreate Total$ | `SUMIFS(Amount, [date anchor], [range])` | Currency | Opp Type, Lead Source, Use Case |

### Booking Metrics

Measured by **Close Date**.

| Metric | Formula | Type | Dimensions |
|--------|---------|------|------------|
| New Business Bookings Total$ | `SUMIFS(Amount, Stage, "9. Closed-Won", Opp Type, "New Business", Close Date, [range])` | Currency | Lead Source, Use Case, Segment |
| New Business Bookings Count | `COUNTIFS(Stage, "9. Closed-Won", Opp Type, "New Business", Close Date, [range])` | Count | Lead Source, Use Case, Segment |
| New Business ADS | `AVERAGEIFS(Amount, Stage, "9. Closed-Won", Opp Type, "New Business", Amount, ">"&0, Close Date, [range])` | Currency | Lead Source, Use Case, Segment |
| Existing Business Bookings Total$ | `SUMIFS(Amount, Stage, "9. Closed-Won", Opp Type, "Existing Business", Close Date, [range])` | Currency | Segment |
| Expansion ARR | `SUMIFS(Expansion ARR, Stage, "9. Closed-Won", Opp Type, "Existing Business", Close Date, [range])` | Currency | Segment |
| Net ARR (Existing) | `SUMIFS(Subskribe Order Delta ARR, Stage, "9. Closed-Won", Opp Type, "Existing Business", Close Date, [range])` | Currency | Segment |
| Lost Total$ | `SUMIFS(Amount, Stage, "10. Closed-Lost", Close Date, [range])` | Currency | Opp Type |
| New Logo Count | `COUNTIFS(Stage, "9. Closed-Won", Opp Type, "New Business", New Biz Won Before This Deal, 0, Close Date, [range])` | Count | Lead Source, Use Case |

### Conversion and Velocity Metrics

| Metric | Formula | Type | Dimensions |
|--------|---------|------|------------|
| Win Rate | `IFERROR(Won / (Won + Lost), 0)` | Percentage | Opp Type, Lead Source, Use Case |
| Average Sales Cycle | `AVERAGEIFS(Sales Cycle Days, Stage, "9. Closed-Won", [filters])` | Days | Opp Type, Lead Source, Use Case |
| Stage-to-Stage Conversion | `Count reached Stage N+1 / Count reached Stage N` | Percentage | Per stage pair |

**Key rule:** Stage-to-stage conversion uses "Reached Stage X" entry-date flags, NOT current stage. A deal at Stage 10 (Closed-Lost) may never have reached Stage 4. See anti-pattern AP-1.

### Sales Dimensions

| Dimension | Values | Source |
|-----------|--------|--------|
| Opportunity Type | New Business, Existing Business | Opportunity field |
| Lead Source Attribution | Marketing, Sales, Partner, Other | Opportunity field |
| Use Case | Social Media Access, Access Management, Identity Lifecycle Management, Other | Mapped from Primary Use Case |
| Company Segment | From data | Opportunity field |
| Pipeline Category | PrePipeline, Early/Mid/Late Pipeline, Won, Lost, QualifiedOut | Derived from Stage |

### Sales Sanity Checks

| Check | Rule | Severity |
|-------|------|----------|
| Opp Type coverage | Every opp is New Business or Existing Business | hard-fail |
| No negative NB Amount | New Business Amount >= 0 | hard-fail |
| Row count preserved | Raw Data rows = Prepared Data rows | hard-fail |
| Valid Stage values | Stages 1-6, 9, 10, 11 only | hard-fail |
| New Logos <= NB Won | Logos cannot exceed won deal count | warning |
| ADS x Won Count ~ Bookings | Within 5% | warning |
| Sales cycle range | 30-365 days typical | info |
| Expansion ARR <= Amount (EB) | For Existing Business | warning |
| Funnel monotonicity | Stage hit counts non-increasing: S2 >= S3 >= ... >= S9 | warning |

---

## Marketing Analytics

Pipeline: `agents/pipelines/marketing-analytics/`
Source: `business-logic/marketing/metrics.md` (166 lines)
Data sources: Marketing Campaign Data sheet (Campaign Members, Leads, Contacts tabs)

### Campaign Metrics

**SUMPRODUCT rule:** Always use SUMPRODUCT instead of COUNTIFS for counting. COUNTIFS gives incorrect results on large formula-heavy Google Sheets (known bug). Use `LEN(cell)>0` instead of `<>""` for non-blank checks.

| Metric | Formula | Type | Notes |
|--------|---------|------|-------|
| Total Campaign Members | `SUMPRODUCT` by campaign ID | Count | All members regardless of lifecycle stage |
| Net New Leads | `SUMPRODUCT` where Origin Type = "Lead" | Count | Members who were originally leads |
| MQLs (ever) | `SUMPRODUCT` where `LEN(Unified MQL Start Date) > 0` | Count | Matches Salesforce Campaign frontend |
| MQLs (current) | `SUMPRODUCT` where `Is MQL+ = "Yes"` | Count | Point-in-time snapshot only |
| MQLs (period) | `SUMPRODUCT` where MQL Start <= end AND (MQL End = "" OR >= start) | Count | Preferred for time-bounded analysis |
| SQLs (ever) | `SUMPRODUCT` where `LEN(Unified SQL Start Date) > 0` | Count | Matches frontend counting |
| SQLs (current) | `SUMPRODUCT` where `Is SQL+ = "Yes"` | Count | Point-in-time snapshot |
| SALs (current) | `COUNTIFS` where `Is SAL+ = "Yes"` | Count | Point-in-time snapshot |
| Opportunities | `COUNTIFS` where Has Opportunity = 1 | Count | Members with a Converted Opp ID |
| Opportunity Value | `SUMIFS` on Opp Amount where Has Opportunity = 1 | Currency | Total attributed opp value |
| Won Opportunities | `COUNTIFS` where Is Closed Won Opp = 1 | Count | Attributed opps that closed-won |
| Won Value | `SUMIFS` on Opp Amount where Is Closed Won Opp = 1 | Currency | Total won value |

### Conversion and Cost Metrics

| Metric | Formula | Type | Notes |
|--------|---------|------|-------|
| MQL Conversion Rate | MQLs / Total Members | Percentage | IFERROR wrap |
| SQL Conversion Rate | SQLs / Total Members | Percentage | IFERROR wrap |
| SAL Conversion Rate | SALs / Total Members (or SALs / MQLs) | Percentage | Denominator depends on context |
| Opp Conversion Rate | Opps / Total Members | Percentage | IFERROR wrap |
| MQL to SAL Rate | SALs (ever) / MQLs (ever) | Percentage | SUMPRODUCT-based |
| MQL to SQL Rate | SQLs (ever) / MQLs (ever) | Percentage | SUMPRODUCT-based |
| Cost per Acquisition | Campaign Cost / Total Members | Currency | From Lookups campaign join |
| Cost per MQL | Campaign Cost / MQLs | Currency | IFERROR wrap |
| Cost per SQL | Campaign Cost / SQLs | Currency | IFERROR wrap |
| Cost per SAL | Campaign Cost / SALs in Period | Currency | IFERROR wrap |
| Campaign ROI | (Won Value - Cost) / Cost | Percentage | IFERROR wrap |

**Cost scoping rule:** For time-period analysis, use period-scoped costs (campaigns with members in the period), not total lifetime campaign costs. Document which method was used in Definitions tab.

### Velocity Metrics

| Metric | Formula | Type | Notes |
|--------|---------|------|-------|
| Speed to Lead (Avg) | SUMPRODUCT-based conditional average | Minutes | MQL to first sales outreach |
| Speed to Lead (Median) | Computed (Python) | Minutes | Requires compute-and-push |
| Days Lead to MQL | `AVERAGEIFS` on helper column | Days | Excluding blanks |
| Days MQL to SAL | `AVERAGEIFS` on helper column | Days | Excluding blanks |
| Days SAL to SQL | `AVERAGEIFS` on helper column | Days | Excluding blanks |
| Days SQL to Opp | `AVERAGEIFS` on helper column | Days | Contacts only |
| Days Lead to Opp | `AVERAGEIFS` on helper column | Days | Contacts only (end-to-end) |
| Average Sort Score | `AVERAGEIFS` on Sort Score Numeric | Number | Numeric conversion of Sort Score |

### Lifecycle Stage Counting Methodologies

Three counting approaches apply to MQL, SAL, and SQL alike. Each is appropriate for different questions:

| Method | When to use | MQL logic | SAL/SQL logic |
|--------|------------|-----------|---------------|
| **Ever** | Frontend replication, campaign attribution | `LEN(Unified MQL Start Date) > 0` | `LEN(Unified SAL/SQL Start Date) > 0` |
| **Current** | Point-in-time snapshot | `Is MQL+ = "Yes"` | `Is SAL+ = "Yes"` / `Is SQL+ = "Yes"` |
| **Period** | Time-bounded analysis (preferred) | MQL Start <= end AND (MQL End = "" OR >= start) | SAL/SQL Start <= end AND (SAL/SQL End = "" OR >= start) |

Additional period-scoped metrics:

| Metric | Formula | Type | Notes |
|--------|---------|------|-------|
| SALs in Period | `COUNTIFS` where SAL Start <= end AND (SAL End = "" OR >= start) | Count | Requires SAL date enrichment from Leads/Contacts |
| SQLs in Period | `COUNTIFS` where SQL Start <= end AND (SQL End = "" OR >= start) | Count | Requires SQL date enrichment from Leads/Contacts |

### MQL Counting Methodologies

Three approaches, each appropriate for different questions:

| Method | When to use | Counting logic |
|--------|------------|---------------|
| **Ever** | Frontend replication, campaign attribution | `LEN(Unified MQL Start Date) > 0` |
| **Current** | Point-in-time snapshot | `Is MQL+ = "Yes"` |
| **Period** | Time-bounded analysis (preferred) | MQL Start <= period_end AND (MQL End = "" OR >= period_start) |

### Marketing Dimensions

| Dimension | Source |
|-----------|--------|
| Campaign Name | Lookups (VLOOKUP from Campaign ID) |
| Campaign Type | Lookups (VLOOKUP from Campaign ID) |
| Time (Start Date) | Start Mo, Start Qtr, Start Fiscal |
| Origin Type | Helper column (Lead vs Contact) |
| Lifecycle Stage | Unified Lifecycle Stage (Contact-first precedence) |
| Department | Unified Department (Contact-first precedence) |
| Level | Unified Level (Contact-first precedence) |
| Lead Source | Unified Lead Source (Contact first, Lead fallback) |
| Owner | Unified Owner (Contact Owner first, Lead Owner fallback) |
| MQL Quarter | Fiscal quarter from Unified MQL Start Date |

### Marketing Sanity Checks

| Check | Rule | Severity |
|-------|------|----------|
| Row count preserved | Raw = Prepared Data rows | hard-fail |
| Campaign ID join coverage | 100% match in Lookups | hard-fail |
| Opp join coverage | >= 90% of non-blank Opp IDs resolve | warning |
| Account join coverage | >= 80% of non-blank Account IDs resolve | warning |
| Lead ID join coverage | >= 90% of Lead IDs match Raw Leads | warning |
| Contact ID join coverage | >= 90% of Contact IDs match Raw Contacts | warning |
| MQL count <= Total Members | Per campaign | warning |
| Won Opps <= Total Opps | Per campaign | warning |
| Opp Amount >= 0 | All resolved amounts | warning |
| Unified fields blank rate | < 20% for Status, Lifecycle Stage | warning |
| SAL/SQL date coverage | % of SQL+ members with dates | info |
| Velocity reasonableness | All velocity columns positive and < 365 days | warning |

---

## Customer Success Analytics

Pipeline: `agents/pipelines/customer-success-analytics/`
Source: `business-logic/customer-success/metrics.md` (240 lines)
Data sources: CS Data sheet (Opportunity, Account, Subskribe Order Line tabs)

### Retention Metrics

| Metric | Formula | Type | Notes |
|--------|---------|------|-------|
| GDR (Gross Dollar Retention) | `(Starting ARR - Churned - Contracted) / Starting ARR` | Percentage | Range: 0-100%. Contract-based. |
| NDR (Net Dollar Retention) | `End ARR / Starting ARR` | Percentage | NDR >= GDR always. >150% = investigate. |
| Contraction Rate ($) | `ABS(SUMIFS(Order Delta ARR, [contraction filters], Close Date FQ, [period]))` | Currency | Distinct from churn (account still active) |
| Contraction Rate (%) | Contraction $ / Total Active ARR at period start | Percentage | |
| Churn Rate ($) | Sum of churned account ARR | Currency | See churn identification rules below |
| Churn Rate (%) | Churned ARR / Total Active ARR at period start | Percentage | |

**GDR/NDR relationship:** NDR = GDR + (Expansion ARR / Starting ARR). NDR must always be >= GDR. If not, there's a data error.

**Churn identification (all must be true):**
1. Account has order lines (was a customer)
2. No active contracts (no order line where Start <= today AND End >= today)
3. No future contracts (no order line where Start > today)
4. No open Existing Business opps

### Expansion Metrics

| Metric | Formula | Type | Notes |
|--------|---------|------|-------|
| CSQL Count | `COUNTIFS([CSQL filters], Close Date FQ, [period])` | Count | CS-sourced expansion opps |
| CSQL Value ($) | `SUMIFS(Order Delta ARR, [CSQL filters], Close Date FQ, [period])` | Currency | |
| CSQL Conversion Rate | Won CSQLs / Total CSQLs | Percentage | Denominator includes all stages |
| CSQL Won Value | `SUMIFS(Order Delta ARR, [CSQL filters], Stage, "9. Closed-Won", Close Date FQ, [period])` | Currency | |

**CSQL filter (all conditions):**
- `CSM Sourced = TRUE` OR `CSM Created = TRUE` OR `Lead Source Attribution = "Customer Success"`
- `Opportunity Type = "Existing Business"`
- `Stage 2. Discovery Start Date` is populated
- `Services Swap Opp != TRUE`
- `Order Delta ARR > 0` (expansion only)

### Leading Indicators

| Metric | Formula | Type | Notes |
|--------|---------|------|-------|
| Account Health Distribution | `COUNTIFS(Account Health, [value], Is Active Customer, "Yes")` | Count | Values: Positive, Slightly Positive, Neutral, Slightly Negative, Negative |
| TTV (Time to Value) | — | Days | Future state (requires deployment data) |
| Customer Engagement Score | — | Score | Future state (requires touchpoint data) |

### CS Dimensions

| Dimension | Values | Source |
|-----------|--------|--------|
| Company Segment | Commercial, Enterprise, Mid-Market, SMB, Strategic | Account |
| CSM | Resolved via User Lookup | Account |
| Use Case | Social Media Access, Access Management, Identity Lifecycle Management, Other | Account/Opp |
| CS Package | Legacy, Premium, Standard | Account |
| Expansion Potential | Cross Sell, None Today, Upsell | Account |
| Account Health | Positive to Negative (5 values) | Account |
| Customer Lifecycle Stage | Active, Engaged, Expansion Opportunity, At-Risk, Opportunity, Prospect | Account |

### CS Sanity Checks

| Check | Rule | Severity |
|-------|------|----------|
| GDR range | 0% <= GDR <= 100% | hard-fail |
| NDR >= GDR | Per period | hard-fail |
| Churned ARR <= Total ARR | Cannot churn more than exists | hard-fail |
| Churned count <= Active accounts | Cannot churn more than are active | hard-fail |
| CSQL count <= EB opp count | CSQLs are a subset | hard-fail |
| Row count preserved (Accounts) | Raw = Prepared | hard-fail |
| Row count preserved (Order Lines) | Raw = Prepared | hard-fail |
| Account ID join (Order Lines) | >= 95% match | hard-fail |
| LOI excluded | Opp Type "LOI" excluded from CSQL | hard-fail |
| Services Swap excluded | Services Swap = TRUE excluded from CSQL | hard-fail |
| NDR range | > 150% is unusual | warning |
| Account ID join (Opportunity) | >= 90% match | warning |
| Account Health coverage | < 20% blank for active customers | warning |
| Renewal Date coverage | < 30% blank for active customers | warning |
| ARR coverage | < 10% blank/zero for active customers | warning |
| Order Line Account coverage | >= 80% non-blank ADMIN Acct ID | warning |
| Health values valid | All values in allowed set | warning |
| Segment values valid | All values in allowed set | warning |
| ARR field validation | Delta ARR = Exit ARR - Entry ARR | warning |

---

## Cross-Domain Anti-Patterns

These rules apply across all pipelines. Source: `business-logic/_shared/anti-patterns.md`

| ID | Anti-Pattern | What goes wrong | Fix |
|----|-------------|----------------|-----|
| AP-1 | Inferring stage progression from current stage | A deal at Stage 10 may never have reached Stage 4. Current stage doesn't tell you the path. | Use "Reached Stage X" entry-date flags from data-dictionary helper columns. |
| AP-2 | Including LOI / Service Swap deals | LOIs are not real pipeline. Service Swaps are not expansion/contraction. | Exclude Opportunity Type = "LOI" and Services Swap Opp = TRUE. |
| AP-3 | Using Close Date for timing on lost deals | Close Date for lost deals is when it was marked lost, not when the decision happened. | Use Stage 2 Entry Date for pipeline timing. Close Date only for bookings. |
| AP-4 | Inconsistent date parsing | Dates from API may come as serial numbers, ISO strings, or locale-formatted. | Always parse with explicit format. Use `DATEVALUE` or `TEXT(date, "YYYY-MM-DD")`. |

---

## Metric Counts by Domain

| Domain | Total metrics | Categories | Sanity checks | Dimensions |
|--------|-------------|------------|---------------|------------|
| Sales | 14 | Pipeline Creation, Bookings, Conversion & Velocity | 9 | 6 |
| Marketing | 30 | Campaign, Conversion & Cost, Velocity, Lifecycle Period | 12 | 10 |
| Customer Success | 10 (+ 2 future) | Retention, Expansion, Leading Indicators | 19 | 7 |
| **Total** | **54** (+ 2 future) | | **40** | |
