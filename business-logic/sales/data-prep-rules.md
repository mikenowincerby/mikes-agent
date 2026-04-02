# Data Preparation Rules

Rules for transforming raw sales data into analysis-ready format. Referenced by `skills/prep-sales-data.md`. For field definitions, see `data-dictionary.md`.

**Principle:** Raw Data is never modified. All transformations produce a new Prepared Data set.

---

## Field Standardization

| Rule | Details |
|------|---------|
| Trim whitespace | Remove leading/trailing spaces from all text fields |
| Normalize blanks | Empty strings, "N/A", "None", "null", "-" all become blank |
| Standardize dates | Convert Created Date, Close Date, Stage 2. Discovery Start Date, Stage 2 Entry Date, Stage 3-6 Start Dates to YYYY-MM-DD. Raw Salesforce dates are text with timestamps (e.g., "2025-02-08 15:18:35") — in Sheet formulas use `DATEVALUE(LEFT(cell,10))`, in Python use `datetime.strptime(s[:10], '%Y-%m-%d')`. |
| Strip currency formatting | Remove `$`, `,` from Amount, Amount (Weighted), Subskribe Order Delta ARR; convert to number |
| Flag duplicates | Check for duplicate ADMIN Opp ID 18 Digit; flag but do not remove |

---

## Calculated Columns

Add to the right of original data. See `data-dictionary.md` for the full helper field list. The most critical calculated columns:

### Sales Cycle Days (= Pipeline Velocity Days)
- **Formula:** Close Date - Stage 2. Discovery Start Date
- **Type:** Integer (days)
- **When:** Only for Stage = "9. Closed-Won" where Stage 2. Discovery Start Date exists (blank otherwise). Lost deals are excluded — they don't represent completed sales cycles.
- **Note:** Sales Cycle Days and Pipeline Velocity Days are the same metric

### Fiscal Quarter (by date anchor)
- Feb-Apr → Q1, May-Jul → Q2, Aug-Oct → Q3, Nov-Jan → Q4
- Create separate columns for each date anchor used: CreateQtr, CloseQtr

### Fiscal Year (by date anchor)
- If month >= 2: FY = calendar year + 1. If month == 1: FY = calendar year.
- Create: Create Fiscal, Close Fiscal

### Quarter Label
- Fiscal Year + " " + Fiscal Quarter (e.g., "FY2026 Q1")

### Month Code
- YYYYMM format (e.g., "202502"). Create: CreateMo, CloseMo

### Use Case
- Map Primary Use Case to categories via Use Case Mapping in Lookups tab:
  - "Social Media Access" → "Social Media Access"
  - "Access Management (EPM, SSO, MFA)" → "Access Management (EPM, SSO, MFA)"
  - "Identity Lifecycle Management (JML)" → "Identity Lifecycle Management (JML)"
  - Everything else → "Other"

### Pipeline Category & Detail Pipeline Category
- Derived from Stage (see `metrics.md` stage table):
  - Stage 1 → PrePipeline / PrePipeline
  - Stages 2-3 → Pipeline / Early Pipeline
  - Stages 4-5 → Pipeline / Mid Pipeline
  - Stage 6 → Pipeline / Late Pipeline
  - Stage 9 → Won / Won
  - Stage 10 → Lost / Lost
  - Stage 11 → QualifiedOut / QualifiedOut

### Expansion ARR
- If Opportunity Type = "Existing Business" AND Subskribe Order Delta ARR > 0: use Subskribe Order Delta ARR
- Else: 0

### New Biz Won Before This Deal
- For each opportunity: count of prior Closed-Won New Business opps for the same ADMIN Acct ID 18 Digit (by Close Date, chronologically before this deal)

### Logo Count
- 1 if Opportunity Type = "New Business" AND Stage = "9. Closed-Won" AND New Biz Won Before This Deal = 0
- Else: 0

### Boolean Helpers
- **Is Closed Won:** 1 if Stage = "9. Closed-Won", else 0
- **Is Closed Lost:** 1 if Stage = "10. Closed-Lost", else 0
- **Closed?:** 1 if Stage starts with "9." or "10.", else 0
- **Stage 1?:** 1 if Stage = "1. Lead Verification", else 0

### ARR Bucket
- Categorize Amount into ranges. Default: <$10K, $10K-$25K, $25K-$50K, $50K-$100K, $100K+
- Configurable per analysis

---

## Data Quality Checks

Run after prep, before analysis. User must acknowledge before proceeding.

| Check | How | Threshold |
|-------|-----|-----------|
| Missing Close Date on closed deals | Stage is "9. Closed-Won" or "10. Closed-Lost" AND Close Date is blank | Any > 0 |
| $0 Amount on Closed-Won | Stage = "9. Closed-Won" AND Amount = 0 or blank | Any > 0 |
| Negative Sales Cycle Days | Sales Cycle Days < 0 | Any > 0 |
| Blank rate by column | % blank per column | Flag > 20% |
| Duplicate ADMIN Opp ID 18 Digit | Count appearing more than once | Any > 0 |
| Unknown Opportunity Types | Not "New Business" or "Existing Business" | Any unknown |
| Unknown Stages | Not in stage list (1-6, 9, 10, 11) | Any unknown |
| LOI / Service Swap deals | Opportunity Type contains "LOI" or "Service Swap" — exclude from pipeline analysis | Flag and exclude |
| Stage entry date coverage | Open pipeline deals (Stage 2-6) should have Stage 2 Start Date populated | Flag deals missing Stage 2 entry date |
| Row count match | Raw Data rows = Prepared Data rows | Must be equal |

### Report Format

```
Data Quality Report
-------------------
Total rows: [n]
Duplicate Opp IDs: [n]
Missing Close Date on closed deals: [n]
$0 Amount on Closed-Won: [n]
Negative Sales Cycle Days: [n]
Unknown Opportunity Types: [list]
Unknown Stages: [list]

High blank-rate columns (>20%):
  - [Column Name]: [x]% blank

Recommendation: [proceed / investigate before proceeding]
```
