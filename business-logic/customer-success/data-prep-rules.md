# Data Preparation Rules

Rules for transforming raw customer success data into analysis-ready format. For field definitions, see `data-dictionary.md`.

**Principle:** Raw Data tabs are never modified. All transformations produce new Prepared Data tabs. The source sheet (`$CS_DATA — see sources.md`) is NEVER written to — always create a new analysis sheet.

---

## Multi-Source Ingest

| Source Tab | Target Tab | Rows | Notes |
|-----------|-----------|------|-------|
| Opportunity | Raw Opportunity | ~800 | Skip row 1 (metadata), row 2 = headers, data from row 3 |
| Account | Raw Account | ~16,720 | Skip row 1 (metadata), row 2 = headers, data from row 3 |
| Subskribe Order Line | Raw Order Lines | ~1,155 | Skip row 1 (metadata), row 2 = headers, data from row 3 |
| User | Raw User | ~1,000 | Skip row 1 (metadata), row 2 = headers, data from row 3 |

All tabs from same sheet (`$CS_DATA — see sources.md`). All READ-ONLY.

### Ingest Rules

- Write with `valueInputOption: RAW` to prevent Sheets from reformatting
- Rewrite numeric columns with `USER_ENTERED` after RAW ingest: Amount, Subskribe Order Delta ARR, ARR, Entry ARR, Exit ARR, Delta ARR, TCV, Quantity
- Batch writes of 500 rows for large datasets (Account tab has ~16K rows)
- Freeze header row on each Raw tab after writing
- Confirm row count matches source for each tab

---

## Two Prepared Data Tabs

Unlike sales (single entity) or marketing (single primary entity), CS requires two Prepared Data tabs due to different row granularities:

### Prepared Data - Accounts

- **Entity:** One row per account (~16,720 rows)
- **Serves:** Account Health Distribution, Churn identification, CSM portfolio analysis
- **Source:** Raw Account, enriched with Lookups and Opportunity data

### Prepared Data - Order Lines

- **Entity:** One row per order line (~1,155 rows)
- **Serves:** GDR, NDR, Contraction Rate, renewal cohort analysis
- **Source:** Raw Order Lines, enriched with Account fields via Lookups

---

## Field Standardization

Same rules as sales (see `../sales/data-prep-rules.md`).

| Rule | Details |
|------|---------|
| Trim whitespace | Remove leading/trailing spaces from all text fields |
| Normalize blanks | Empty strings, "N/A", "None", "null", "-" all become blank |
| Standardize dates | Convert all date fields to YYYY-MM-DD. Raw Salesforce dates are text with timestamps — in Sheet formulas use `DATEVALUE(LEFT(cell,10))`, in Python use `datetime.strptime(s[:10], '%Y-%m-%d')`. |
| Strip currency formatting | Remove `$`, `,` from ARR, Amount, TCV, Delta ARR, Entry ARR, Exit ARR; convert to number |
| Flag duplicates | Check for duplicate Account IDs in Account tab; flag but do not remove |

---

## Calculated Columns

Add to the right of original data. See `data-dictionary.md` for the full helper field list. Organize by dependency tier.

### Tier 1 — Raw + Lookups (Prepared Data - Accounts)

11 columns. Full derivation formulas: `data-dictionary.md` § Helper Fields — Prepared Data - Accounts.

| Column | Formula Pattern |
|--------|----------------|
| CSM Name | VLOOKUP(Customer Success Manager, User Lookup, 4, FALSE) — resolves User ID to name |
| Use Case (Mapped) | VLOOKUP on Use Case Mapping |
| Is Active Customer | VLOOKUP on Customer Lifecycle Mapping → col 2 |
| Lifecycle Rank | VLOOKUP on Customer Lifecycle Mapping → col 3 |
| Health Category | VLOOKUP on Account Health Mapping → col 3 |
| Health Rank | VLOOKUP on Account Health Mapping → col 2 |
| Renewal Mo | TEXT(DATEVALUE(LEFT(Renewal Date,10)),"YYYYMM") |
| Renewal Qtr | VLOOKUP(MONTH(...), Fiscal Period Mapping, 2, FALSE) |
| Renewal FY Add | VLOOKUP(MONTH(...), Fiscal Period Mapping, 4, FALSE) |
| Renewal Fiscal | YEAR(...) + Renewal FY Add |
| Renewal Quarter Label | "FY"&Renewal Fiscal&" "&Renewal Qtr |

Dependencies: only raw Account columns + Lookups tab.

### Tier 1 — Raw + Lookups (Prepared Data - Order Lines)

11 columns. Full derivation formulas: `data-dictionary.md` § Helper Fields — Prepared Data - Order Lines.

| Column | Formula Pattern |
|--------|----------------|
| Account Name | VLOOKUP on Account Lookup → Account Name col |
| CSM Name | Nested VLOOKUP: Account Lookup → CSM User ID → User Lookup → CSM Name |
| Company Segment | VLOOKUP on Account Lookup → Company Segment col |
| Account Use Case | VLOOKUP on Account Lookup → Use Case col |
| Account ARR | VLOOKUP on Account Lookup → ARR col |
| Account Health | VLOOKUP on Account Lookup → Account Health col |
| Line End Mo | TEXT(DATEVALUE(LEFT(Line End Date,10)),"YYYYMM") |
| Line End Qtr | VLOOKUP(MONTH(...), Fiscal Period Mapping, 2, FALSE) |
| Line End FY Add | VLOOKUP(MONTH(...), Fiscal Period Mapping, 4, FALSE) |
| Line End Quarter Label | "FY"&(YEAR+FY Add)&" "&Qtr |
| Line Start Mo | TEXT(DATEVALUE(LEFT(Line Start Date,10)),"YYYYMM") |

Dependencies: only raw Order Line columns + Lookups tab.

### Tier 2 — References Tier 1 (Prepared Data - Accounts)

4 columns. Full derivation formulas: `data-dictionary.md` § Helper Fields — Prepared Data - Accounts.

| Column | Formula Pattern |
|--------|----------------|
| Has Open EB Opp | COUNTIFS(Opp Lookup Acct ID = this Acct ID, Opp Type = "Existing Business", Stage <> "9. Closed-Won", Stage <> "10. Closed-Lost") |
| Has Expansion Potential | IF(Expansion Potential <> "None Today", 1, 0) |
| Won Delta ARR | SUMPRODUCT over Opp Lookup: Closed-Won, non-LOI, matching Acct ID → sum of Delta ARR |
| Has Open Renewal Opp | COUNTIFS(Opp Lookup Acct ID = this Acct ID, Opp Type = "Existing Business", Stage <> "9. Closed-Won", Stage <> "10. Closed-Lost", Renewal vs Expansion = "Renewal") + COUNTIFS(..., Renewal vs Expansion = "Renewal & Expansion") — scoped to renewal-type opps only |

**Note:** Is Churned is not a Prepared Data column. Churn requires cross-tab logic (Order Lines + Opps) and is computed at analysis time. See `metrics.md` § Churn Rate.

Dependencies: Tier 1 Account helper columns + Lookups Opportunity columns.

### Tier 2 — References Tier 1 (Prepared Data - Order Lines)

4 columns. Full derivation formulas: `data-dictionary.md` § Helper Fields — Prepared Data - Order Lines.

| Column | Formula Pattern |
|--------|----------------|
| Is Expansion | IF(Delta ARR > 0, 1, 0) |
| Is Contraction | IF(Delta ARR < 0, 1, 0) |
| Is Flat Renewal | IF(Delta ARR = 0, 1, 0) |
| Line Duration Days | DATEVALUE(LEFT(Line End Date,10)) - DATEVALUE(LEFT(Line Start Date,10)) |

Dependencies: Tier 1 Order Line columns.

### Tier 3 — References Tier 2 (Prepared Data - Accounts)

1 column. Full derivation formula: `data-dictionary.md` § Helper Fields — Prepared Data - Accounts.

| Column | Formula Pattern |
|--------|----------------|
| Churn Risk Flag | IF(Health Category="Red" AND Renewal Date within next 90 days AND Has Open Renewal Opp=0, "At Risk", "") |

Dependencies: Tier 2 Account helper columns.

**Note:** GDR/NDR no longer require compute-and-push or renewal line matching. They are calculated at analysis time by comparing active Order Line ARR at period start vs period end per account. See `metrics.md` § GDR and § NDR.

**Build in tier order.** Write all Tier 1 formulas before starting Tier 2. Write all Tier 2 before Tier 3.

---

## Data Quality Checks

Run after prep, before analysis. User must acknowledge before proceeding.

| Check | How | Threshold |
|-------|-----|-----------|
| Duplicate Account IDs | Count appearing more than once in Account tab | Flag count |
| Missing Renewal Date (active) | % of Is Active Customer = "Yes" with blank Renewal Date | Flag > 30% |
| Missing Account Health (active) | % of Is Active Customer = "Yes" with blank Account Health | Flag > 20% |
| Zero/blank ARR (active) | Is Active Customer = "Yes" with ARR = 0 or blank | Flag count |
| Account ID join coverage (Order Lines) | % of Order Line Account IDs matching Account tab | Must be >= 95% |
| Account ID join coverage (Opportunity) | % of Opp Account IDs matching Account tab | Flag < 90% |
| ARR field validation | Check if Delta ARR = Exit ARR - Entry ARR for order lines | Report discrepancies |
| Row count match (Accounts) | Raw Account rows = Prepared Data - Accounts rows | Must be equal |
| Row count match (Order Lines) | Raw Order Lines rows = Prepared Data - Order Lines rows | Must be equal |
| Order Line Account coverage | % of order lines with non-blank ADMIN Acct ID | Must be >= 80%. Flag blank AcctIDs — they are invisible to GDR/NDR. |
| LOI presence check | Any Opportunity Type = "LOI" in data | Report count, confirm excluded from CSQL formulas |
| Services Swap presence check | Any Services Swap Opp = TRUE in data | Report count, confirm excluded from CSQL formulas |
| Blank rate by column | % blank per column | Flag > 20% |

### Report Format

```
Data Quality Report
-------------------
Total Account rows: [n]
Total Order Line rows: [n]
Total Opportunity rows: [n]
Duplicate Account IDs: [n]
Missing Renewal Date (active accounts): [x]%
Missing Account Health (active accounts): [x]%
Zero/blank ARR (active accounts): [n]
Account ID join coverage (Order Lines): [x]% ([n] unmatched)
Account ID join coverage (Opportunity): [x]% ([n] unmatched)
ARR field validation: [Delta = Exit - Entry: YES/NO, discrepancies: [n]]
Row count match (Accounts): [pass/fail]
Row count match (Order Lines): [pass/fail]
Order Line Account coverage: [x]% ([n] with AcctID of [m] total)
LOI records: [n] (excluded from CSQL counts)
Services Swap records: [n] (excluded from CSQL counts)

High blank-rate columns (>20%):
  - [Column Name]: [x]% blank

Recommendation: [proceed / investigate before proceeding]
```
