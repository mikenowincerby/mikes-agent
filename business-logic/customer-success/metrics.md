# Customer Success Metrics — Definitions, Formulas & Dimensions

Single source of truth for how Cerby defines and calculates customer success metrics. Referenced by `agents/pipelines/customer-success-analytics/` pipeline agents.

## Table of Contents
- [Fiscal Calendar](#fiscal-calendar)
- [Opportunity Rules (Inherited from Sales)](#opportunity-rules-inherited-from-sales)
- [Retention Metrics](#retention-metrics)
- [Expansion Metrics](#expansion-metrics)
- [Leading Indicators](#leading-indicators)
- [Dimensions](#dimensions)
- [Sanity Check Rules](#sanity-check-rules)

---

## Fiscal Calendar

Same fiscal calendar as sales metrics (see `../sales/metrics.md`).

| Rule | Definition |
|------|-----------|
| Fiscal Year | Calendar year + 1. Feb 2025 = FY2026. |
| FY Start | February 1 |
| FY End | January 31 |
| Q1 | February – April |
| Q2 | May – July |
| Q3 | August – October |
| Q4 | November – January |

**January edge case:** January belongs to the *prior* fiscal year's Q4. Jan 2026 = FY2026 Q4 (not FY2027).

**Deriving fiscal period from a date:**
- If month >= 2: FY = calendar year + 1
- If month == 1: FY = calendar year (Jan 2026 → FY2026)
- Quarter mapping: Feb-Apr → Q1, May-Jul → Q2, Aug-Oct → Q3, Nov-Jan → Q4
- FY Add: January = 0, all other months = 1 (i.e., FY = calendar year + FY Add)

**Quarter Label format:** `FY2026 Q1` (always include FY prefix)

---

## Opportunity Rules (Inherited from Sales)

These rules are shared with the sales pipeline. See `../sales/metrics.md` for full context.

### Pipeline Threshold

**Stage 2 Entry Date** is when an opportunity becomes pipeline. Before Stage 2, it is a Lead (PrePipeline). A CSQL is not considered valid pipeline unless it has a `Stage 2. Discovery Start Date`.

### Stage Progression

| Stage | Category |
|-------|----------|
| 2. Discovery | Pipeline |
| 3. Scoping | Pipeline |
| 4. Solution Validation \| Trial | Pipeline |
| 5. Solutions Proposal | Pipeline |
| 6. Negotiate and Close | Pipeline |
| 9. Closed-Won | Won |
| 10. Closed-Lost | Lost |

### Opportunity Types & Value Fields

| Opportunity Type | Description | CS Relevance |
|-----------------|-------------|-------------|
| Existing Business | Renewals, expansions, contractions | Primary CS metric source |
| New Business | New customer deals | Not CS-sourced (excluded from CSQL) |
| LOI | Letter of Intent | **Excluded from all CS counts** |

**Value fields for Existing Business:**
- `Amount` — total deal value (contract amount)
- `Subskribe Order Delta ARR` — net ARR change: $0 = flat renewal, positive = expansion, negative = contraction

### Exclusion Rules

| Rule | Filter | Rationale |
|------|--------|-----------|
| LOI exclusion | Opportunity Type ≠ "LOI" | LOIs are not real pipeline |
| Services Swap exclusion | Services Swap Opp ≠ TRUE | Service swaps are not expansion/contraction |

---

## Retention Metrics

Time granularity: Monthly, Quarterly, Fiscal Year.

### GDR (Gross Dollar Retention)

- **Definition:** Percentage of starting ARR retained, excluding expansion. Measures how much of the existing base was kept.
- **Formula:** `(Starting ARR - Churned ARR - Contracted ARR) / Starting ARR`
  - Starting ARR = SUM(Entry ARR) for order lines active at period start (Line Start ≤ period start AND Line End ≥ period start)
  - Churned ARR = Starting ARR of accounts with no active contracts at period end and no future contracts
  - Contracted ARR = reduction in ARR for accounts that renewed at lower value (End ARR < Start ARR, but End ARR > 0)
- **Cohort anchor:** Fiscal period start/end dates (FY starts Feb 1, FY = CY+1 for Feb-Dec, FY = CY for Jan)
- **Method:** Contract-based — compare active Order Line ARR at period start vs period end per account. No compute-and-push needed.
- **Range:** 0% – 100%. Values outside indicate a data error.
- **Audit:** Account-level waterfall table showing Start ARR → End ARR → Change → Status (Expanded/Flat/Contracted/Churned) per account.

### NDR (Net Dollar Retention)

- **Definition:** Total recurring revenue retained including expansion, minus churn and contractions. Measures net ARR movement.
- **Formula:** `End ARR / Starting ARR`
  - End ARR = SUM(Entry ARR) for order lines active at period end per account in starting cohort
  - Starting ARR = same as GDR
- **Cohort anchor:** Fiscal period start/end dates (same as GDR)
- **Method:** Contract-based (same as GDR)
- **Range:** NDR >= GDR always. NDR > 100% indicates net expansion. NDR > 150% is unusual — investigate.
- **Relationship:** NDR = GDR + (Expansion ARR / Starting ARR)
- **Audit:** Same account-level waterfall as GDR.

### Contraction Rate

- **Definition:** Percentage and dollar value of revenue lost to downselling or license reductions, distinct from full churn.
- **Identification:** Closed-Won Existing Business opp with Order Delta ARR < 0, excl LOI/Services Swap
- **Formula ($):** `ABS(SUMIFS(Order Delta ARR, [contraction filters], Close Date fiscal quarter, [period]))`
- **Formula (%):** Contraction $ / Total Active ARR at period start
- **Formula (count):** Count of contraction opps in period
- **Cohort anchor:** Close Date → derive fiscal period (FY starts Feb 1, FY = CY+1 for Feb-Dec, FY = CY for Jan)
- **Method:** Sheet formula — SUMIFS on Opportunity data via Lookups, with fiscal period derived from Close Date
- **No overlap with churn:** Contractions are on accounts that remain active. Churned accounts have no Closed-Won renewal.

### Churn Rate

- **Definition:** Percentage and dollar value of fully churned customers.
- **Churn identification (all must be true):**
  1. Account has order lines (was a customer)
  2. No active contracts (no order line where Line Start Date ≤ today AND Line End Date ≥ today)
  3. No future contracts (no order line where Line Start Date > today)
  4. No open renewal-type EB opps (no open EB opps where Renewal vs Expansion = "Renewal" or "Renewal & Expansion")
- **Churned ARR ($):** Sum of Order Delta ARR from Closed-Won non-LOI opps for the account. Fallback: Sum of Entry ARR from last-ending order lines if no qualifying opps exist.
- **Formula (%):** Churned ARR / Total Active ARR at period start
- **Formula (count):** Count of accounts meeting churn criteria with last Line End Date in period
- **Cohort anchor:** Latest `Line End Date` from Subskribe Order Line → derive fiscal period (when last contract expired)
- **Method:** Analysis-time — cross-tab COUNTIFS/SUMIFS across Prepared Data - Accounts and Prepared Data - Order Lines. Not a single-tab helper column. All time slicing uses fiscal periods.
- **Exclusions:** LOI opps always excluded from churned ARR calculation
- **Current data:** 13 churned accounts, ~$509k churned ARR

---

## Expansion Metrics

### CSQLs (CS-Qualified Leads)

- **Definition:** Expansion opportunities identified by the CSM team and passed to Sales.
- **Filter:** (`CSM Sourced = TRUE` OR `CSM Created = TRUE` OR `Lead Source Attribution = "Customer Success"`) AND `Opportunity Type = "Existing Business"` AND `Stage 2. Discovery Start Date` is populated (pipeline threshold) AND `Services Swap Opp ≠ TRUE` AND `Order Delta ARR > 0` (expansion only — contractions are not CS-qualified leads)
- **CSQL Value ($):** `SUMIFS(Order Delta ARR, [CSQL filters], Close Date fiscal quarter, [period])`
- **CSQL Count:** `COUNTIFS([CSQL filters], Close Date fiscal quarter, [period])`
- **Date anchor:** Close Date → derive fiscal period (for won CSQLs). Stage 2. Discovery Start Date → derive fiscal period (for pipeline creation view).
- **Method:** Sheet formula

### CSQL Conversion Rate

- **Definition:** Percentage of CSQLs that reach Closed-Won.
- **Formula:** `COUNTIFS([CSQL filters], Stage, "9. Closed-Won", Close Date fiscal quarter, [period]) / COUNTIFS([CSQL filters], Close Date fiscal quarter, [period])`
- **Method:** Sheet formula
- **Note:** Denominator includes all CSQLs regardless of stage (open + closed)

### CSQL Won Value

- **Definition:** Total incremental ARR from won CSQLs.
- **Formula:** `SUMIFS(Order Delta ARR, [CSQL filters], Stage, "9. Closed-Won", Close Date fiscal quarter, [period])`

---

## Leading Indicators

### Account Health Distribution

- **Definition:** Distribution of Account Health values across the active customer base.
- **Values:** Positive, Slightly Positive, Neutral, Slightly Negative, Negative
- **Formula:** `COUNTIFS(Account Health, [value], Is Active Customer, "Yes", [dimension filters])`
- **Dimensions:** Slice by Company Segment, CSM, Use Case, CS Package
- **Method:** Sheet formula
- **Note:** Health values map to categories: Positive/Slightly Positive → Green, Neutral → Yellow, Slightly Negative/Negative → Red
- **Data caveat:** Only ~120 of ~12,290 accounts have health populated. This is expected — health is only set on active customers. Is Active Customer filter narrows the denominator.

### TTV (Time to Value) — Future State

- **Definition:** Days from Contract Start to "First Value" milestone, defined as 50% deployment within the first 90 days.
- **Status:** Placeholder — requires deployment/onboarding data not in current source.
- **Target:** Track once deployment milestone data is available.

### Customer Engagement Score — Future State

- **Definition:** Frequency of high-value touchpoints like QBRs and executive check-ins.
- **Status:** Placeholder — requires activity/touchpoint data not in current source.
- **Target:** Track once QBR/meeting data is integrated.

---

## Dimensions

### Time Dimensions

| Dimension | Description |
|-----------|------------|
| Date anchor (Retention) | Line End Date (GDR/NDR cohort), Renewal Date (churn cohort) |
| Date anchor (Expansion) | Close Date (won CSQLs), Stage 2. Discovery Start Date (pipeline creation) |
| Month | Calendar month (YYYYMM code) |
| Fiscal Quarter | Q1-Q4 per fiscal calendar |
| Fiscal Year | FY per fiscal calendar (e.g., FY2026) |

### Segment Dimensions

| Dimension | Values | Source |
|-----------|--------|--------|
| Company Segment | Commercial, Enterprise, Mid-Market, SMB, Strategic | Account.Company Segment |
| Customer Success Manager | From data (resolved via User Lookup) | Account.Customer Success Manager → User Lookup → CSM Name |
| Use Case | Social Media Access, Access Management (EPM, SSO, MFA), Identity Lifecycle Management (JML), Other | Mapped from Account.Use Case / Opp.Primary Use Case |
| CS Package | Legacy, Premium, Standard | Account.Customer Success Package |
| Expansion Potential | Cross Sell, None Today, Upsell | Account.Expansion Potential |
| Account Health | Positive, Slightly Positive, Neutral, Slightly Negative, Negative | Account.Account Health |
| Customer Lifecycle Stage | Active, Engaged, Expansion Opportunity, At-Risk, Opportunity, Prospect | Account.Customer Lifecycle Stage |

---

## Sanity Check Rules

| Check | Rule | Severity |
|-------|------|----------|
| GDR range | 0% <= GDR <= 100% per period | hard-fail |
| NDR >= GDR | NDR must equal or exceed GDR per period | hard-fail |
| NDR range | NDR > 150% is unusual | warning |
| Churned ARR <= Total ARR | Cannot churn more than exists | hard-fail |
| Churned count <= Active accounts | Cannot churn more accounts than are active | hard-fail |
| CSQL count <= EB opp count | CSQLs are a subset of Existing Business opps (after Stage 2 filter) | hard-fail |
| Row count preserved (Accounts) | Raw Account = Prepared Data - Accounts | hard-fail |
| Row count preserved (Order Lines) | Raw Order Line = Prepared Data - Order Lines | hard-fail |
| Account ID join coverage (Order Lines) | >= 95% of Order Line Account IDs match Account tab | hard-fail |
| Account ID join coverage (Opportunity) | >= 90% of Opp Account IDs match Account tab | warning |
| LOI excluded | Opportunity Type "LOI" excluded from CSQL counts | hard-fail |
| Services Swap excluded | Services Swap Opp = TRUE excluded from CSQL counts | hard-fail |
| Account Health coverage | < 20% blank for active customers (Is Active Customer = "Yes") | warning |
| Renewal Date coverage | < 30% blank for active customers | warning |
| ARR coverage | < 10% blank/zero for active customers | warning |
| Order Line Account coverage | >= 80% of order lines have non-blank ADMIN Acct ID | warning |
| Health values valid | All Account Health in {Positive, Slightly Positive, Neutral, Slightly Negative, Negative, blank} | warning |
| Segment values valid | All Company Segment in {Commercial, Enterprise, Mid-Market, SMB, Strategic, blank} | warning |
| ARR field validation | Confirm Delta ARR = Exit ARR - Entry ARR for order lines | warning |
