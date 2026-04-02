# Marketing Data Preparation Rules

Rules for transforming raw marketing campaign data into analysis-ready format. Referenced by `skills/prep-marketing-data.md`. For field definitions, see `data-dictionary.md`.

**Principle:** Raw Data tabs are never modified. All transformations produce a new Prepared Data set. The source marketing data sheet (`$MARKETING_DATA — see sources.md`) is NEVER written to — always create a new analysis sheet.

## Table of Contents
- [Multi-Source Ingest](#multi-source-ingest)
- [Duplicate Column Disambiguation](#duplicate-column-disambiguation)
- [Lead/Contact Unification Rules](#leadcontact-unification-rules)
- [Cross-Sheet Join Rules](#cross-sheet-join-rules)
- [Calculated Columns](#calculated-columns)
- [Data Quality Checks](#data-quality-checks)

---

## Multi-Source Ingest

| Source | Target Tab | Row Offset | Notes |
|--------|-----------|------------|-------|
| Campaign Members (source sheet) | Raw Campaign Members | Skip row 1 (metadata), row 2 = headers, data from row 3 | Primary entity (9,381 rows) |
| Campaign (source sheet) | Raw Campaign Data | Skip row 1 (metadata), row 2 = headers, data from row 3 | Campaign master data with cost/dates (91 rows). Preferred source for Campaign Mapping. |
| Master Campaign Frontend Data (source sheet) | Raw Campaign Data (alt) | Row 1 = headers | Aggregate campaign metrics. Fallback if Campaign tab is unavailable. |
| Opportunity (Daily Data) | Raw Opportunities | Row 1 = headers | For opp amount/stage joins |
| Leads (source sheet) | Raw Leads | Skip row 1 (metadata), row 2 = headers, data from row 3 | Lead lifecycle dates incl. SAL/SQL (12,705 rows). **Optional** — only needed when analysis requires SAL/SQL dates, velocity metrics, lead source, or full-funnel lifecycle counts. |
| Contacts (source sheet) | Raw Contacts | Skip row 1 (metadata), row 2 = headers, data from row 3 | Contact lifecycle dates incl. SAL/SQL (30,431 rows). **Optional** — only needed when analysis requires SAL/SQL dates, velocity metrics, lead source, or full-funnel lifecycle counts. |

> **IMPORTRANGE alternative:** For persistent workbench sheets that need live data, IMPORTRANGE can be used as an alternative ingestion method instead of copying raw data. This keeps the workbench sheet connected to the source and avoids stale snapshots. When using IMPORTRANGE, skip the RAW/USER_ENTERED rewrite step — Sheets will interpret values natively.

### Ingest Rules

- Write with `valueInputOption: RAW` to prevent Sheets from reformatting
- Rewrite numeric columns with `USER_ENTERED` after RAW ingest (Amount, Sort Score, Opportunities in Campaign, Actual Cost, etc.)
- Batch writes of 500 rows for large datasets
- Freeze header row on each Raw tab after writing
- Confirm row count matches source for each tab

---

## Duplicate Column Disambiguation

The Campaign Members tab has columns with identical names for contact vs lead:

- Status (cols I and T)
- Touch Stage (cols M and V)
- Sort Score (cols N and Y)
- Level (cols O and Z)
- Department (cols P and AA)

**Rule:** During Raw Campaign Members ingest, rename these headers to disambiguate:

- Col I → "Contact Status", Col T → "Lead Status"
- Col M → "Contact Touch Stage", Col V → "Lead Touch Stage"
- Col N → "Contact Sort Score", Col Y → "Lead Sort Score"
- Col O → "Contact Level", Col Z → "Lead Level"
- Col P → "Contact Department", Col AA → "Lead Department"

This renaming happens at ingest time by modifying the header row before writing to Raw Campaign Members.

---

## Lead/Contact Unification Rules

| Rule | Logic |
|------|-------|
| Default to Contact | When both contact and lead fields are non-blank, use contact value |
| Origin Type | "Lead" if Converted from Lead (col AD) = TRUE, else "Contact" |
| Account ID priority | Account ID (col H) first; if blank, use Converted Account ID (col AF) |
| Sort Score | Contact Sort Score first; if blank, Lead Sort Score. Convert to numeric. |
| MQL Start Date | **4-source enrichment cascade** (pre-computed in Python, pasted as static values): (1) CM Contact C MQL Start (col K), (2) CM Lead MQL Start (col W), (3) Raw Contacts C MQL Start (via Contact ID lookup), (4) Raw Leads MQL Start (via Lead ID lookup). First non-blank wins. |
| MQL End Date | Contact C MQL End Date (col L) first; if blank, Lead MQL End Date (col X). Wrap in DATEVALUE — source dates are text strings. |
| SAL Start Date | **Pre-computed enrichment**: Contact C SAL Start (from Raw Contacts via Contact ID) first; Lead SAL Start (from Raw Leads via Lead ID) fallback. Pasted as static values. |
| SAL End Date | Contact C SAL End Datetime (from Contact Lifecycle Mapping) first; if blank, Lead SAL End Date (from Lead Lifecycle Mapping). Wrap in DATEVALUE. |
| SQL Start Date | **Pre-computed enrichment**: Contact C SQL Start (from Raw Contacts via Contact ID) first; Lead SQL Start (from Raw Leads via Lead ID) fallback. Pasted as static values. |
| SQL End Date | Contact C SQL End Datetime (from Contact Lifecycle Mapping) first; if blank, Lead SQL End Date (from Lead Lifecycle Mapping). Wrap in DATEVALUE. |
| Lead Source | Contact Lead Source (col W, via Contact Lifecycle Mapping) first; if blank, Lead Lead Source (col S, via Lead Lifecycle Mapping). |
| Touch Stage 1 Date | Contact Touch Stage 1 Date (col S, via Contact Lifecycle Mapping) first; if blank, Lead Touch Stage 1 Date (col Q, via Lead Lifecycle Mapping). |
| Create Date | Contact C Lead Start Datetime (col U, via Contact Lifecycle Mapping) first; Lead Create Date (col R, via Lead Lifecycle Mapping) fallback. Represents when person first entered the system. |
| Opportunity Datetime | Contact C Opportunity Start Datetime (col V, via Contact Lifecycle Mapping). Contacts only — leads do not have this field. |
| Speed to Lead | Contact Speed to Lead (from Contact STL+Owner Mapping, source col X) first; Lead Speed to Lead (from Lead STL+Owner Mapping, source col T) fallback. Numeric (minutes). Pre-calculated in Salesforce. |
| Owner | Contact Owner (from Contact STL+Owner Mapping, source col Y) first; Lead Owner (from Lead STL+Owner Mapping, source col U) fallback. Text (rep name). |

> **Note:** SAL/SQL dates, lead source, touch stage dates, create dates, and opportunity datetimes are NOT on the Campaign Members tab — they come from the Leads/Contacts tabs via Lifecycle Mappings. This means Raw Leads and Raw Contacts must be ingested and their Mapping sections populated before these helper columns can resolve.

> **Enrichment note:** MQL Start, SAL Start, and SQL Start dates use a 4-source enrichment cascade pre-computed in Python (not formulas) because INDEX/MATCH formulas across 30K+ rows exceed Google Sheets resource limits when applied to 9K+ formula rows. The cascade checks CM Contact → CM Lead → Raw Contacts lookup → Raw Leads lookup, and the first non-blank value wins.

> **Phantom blank cells:** Cells written via the Google Sheets API with empty string values (`""`) appear blank but `ISBLANK()` returns FALSE and `<>""` returns TRUE. Always use `LEN(cell)>0` to check for non-blank content. This affects all raw data tabs written via the API.

---

## Cross-Sheet Join Rules

All joins done via VLOOKUP against Lookups tab data tables (not IMPORTRANGE):

- Lookups tab populated from Raw data tabs BEFORE Prepared Data formulas are written
- Join keys: ADMIN Campaign 18 Digit ID (campaign join), Converted Opportunity ID (opp join), Unified Account ID (account join), ADMIN Lead ID 18 Digit (lead lifecycle join), ADMIN Contact ID 18 Digit (contact lifecycle join)
- VLOOKUP with exact match (FALSE) for all joins
- Wrap in IFERROR to handle unmatched keys gracefully

---

## Calculated Columns

Add to the right of original data. See `data-dictionary.md` for the full helper column list. Organize by dependency tier:

### Tier 1 — Raw + Lookups

Campaign enrichment (VLOOKUP), field unification (IF), date parsing (TEXT/DATEVALUE/MONTH), MQL date unification (IF + DATEVALUE), SAL/SQL date unification (IF + DATEVALUE via Lifecycle Mappings), Campaign Start/End Date (VLOOKUP from Campaign Mapping), Unified Lead Source (contact-first from Lifecycle Mappings), Unified Touch Stage 1 Date (contact-first from Lifecycle Mappings), Unified Create Date (contact C Lead Start Datetime first, lead Create Date fallback), Unified Opportunity Datetime (contact only, from Contact Lifecycle Mapping). Dependencies: only raw columns + Lookups tab.

### Tier 2 — References Tier 1

Lifecycle ranking (VLOOKUP), Is MQL+ / Is SQL+ / Is SAL+ (VLOOKUP to Lifecycle Stage Mapping), Is Marketing Source (IF on Unified Lead Source), opportunity enrichment (VLOOKUP via Converted Opp ID), account name (VLOOKUP via Unified Account ID), velocity columns: Days Lead to MQL (Unified MQL Start Date - Unified Create Date), Days MQL to SAL, Days SAL to SQL, Days SQL to Opp, Days Lead to Opp, MQL Quarter Label (fiscal quarter from Unified MQL Start Date — for time-based MQL cohort analysis, distinct from Start Date-based Quarter Label). Dependencies: Tier 1 helper columns + Lookups tab.

### Tier 3 — References Tier 2

Boolean helpers (IF on Tier 2 values), numeric conversion (VALUE for Sort Score), new vs previously engaged (date comparison). Dependencies: Tier 2 helper columns.

**Build in tier order.** Write all Tier 1 formulas before starting Tier 2. Write all Tier 2 before Tier 3. This prevents #REF! errors from unresolved dependencies.

---

## Data Quality Checks

Run after prep, before analysis. User must acknowledge before proceeding.

| Check | How | Threshold |
|-------|-----|-----------|
| Duplicate Campaign Member ID | Count appearing more than once | Any > 0 |
| Missing Campaign 18 Digit ID | Blank in column A | Any > 0 |
| Campaign ID join coverage | % of Campaign IDs that match Raw Campaign Data | Should be 100% |
| Opp join coverage | % of non-blank Converted Opp IDs that match Raw Opportunities | Flag if < 90% |
| Account join coverage | % of non-blank Unified Account IDs that match | Flag if < 80% |
| Blank Unified Status | Neither contact nor lead status populated | Flag > 10% |
| Row count match | Raw Campaign Members rows = Prepared Data rows | Must be equal |
| Duplicate column names | No duplicate headers in Prepared Data | Must pass |
| Start Date format | All Start Dates parseable as YYYY-MM-DD | Flag non-parseable |
| MQL date coverage | % of Is MQL+ = "Yes" members with non-blank Unified MQL Start Date | Report coverage %. If < 50%, warn that period-based MQL counting will undercount — fall back to Is MQL+ for this analysis. |
| Lead ID join coverage | % of non-blank ADMIN Lead ID 18 Digit in Campaign Members that match Raw Leads | Flag if < 90%. Required for SAL/SQL enrichment. |
| Contact ID join coverage | % of non-blank ADMIN Contact ID 18 Digit in Campaign Members that match Raw Contacts | Flag if < 90%. Required for SAL/SQL enrichment. |
| SAL date coverage | % of SAL+ members (Lifecycle Rank <= 4) with non-blank Unified SAL Start Date | Report %. If sparse, SAL period metrics will undercount. |
| SQL date coverage | % of SQL+ members (Lifecycle Rank <= 3) with non-blank Unified SQL Start Date | Report %. If sparse, SQL period metrics will undercount. |
| Lead Source coverage | % of members with non-blank Unified Lead Source | Severity: **info**. Report coverage %. Low coverage limits Lead Source dimension analysis but is not blocking. |
| Velocity reasonableness | All velocity helper columns (Days Lead to MQL, etc.) must be positive and < 365 days | Severity: **warning**. Flag negative values (date ordering issue) and values > 365 (likely data quality issue). Do not fail — report for investigation. |
| Speed to Lead coverage | % of MQL+ members with non-blank Unified Speed to Lead | Severity: **info**. Report coverage %. Low coverage limits Speed to Lead analysis but is not blocking. |
| Speed to Lead reasonableness | All Unified Speed to Lead values >= 0 and < 525,600 (1 year in minutes) | Severity: **warning**. Flag negatives and extreme values (>525,600 min). Do not fail — report for investigation. |
| Owner coverage | % of members with non-blank Unified Owner | Severity: **info**. Report coverage %. |

### Report Format

```
Data Quality Report
-------------------
Total rows: [n]
Duplicate Campaign Member IDs: [n]
Missing Campaign 18 Digit ID: [n]
Campaign ID join coverage: [x]% ([n] unmatched)
Opp join coverage: [x]% ([n] unmatched of [m] non-blank)
Account join coverage: [x]% ([n] unmatched of [m] non-blank)
Blank Unified Status: [x]%
Duplicate column names in Prepared Data: [pass/fail]
Non-parseable Start Dates: [n]
MQL date coverage: [x]% of MQL+ members have Unified MQL Start Date [warn if < 50%]
Lead ID join coverage: [x]% ([n] unmatched of [m] non-blank)
Contact ID join coverage: [x]% ([n] unmatched of [m] non-blank)
SAL date coverage: [x]% of SAL+ members have Unified SAL Start Date
SQL date coverage: [x]% of SQL+ members have Unified SQL Start Date
Lead Source coverage: [x]% of members have Unified Lead Source
Velocity reasonableness: [n] negative values, [n] values > 365 days

Recommendation: [proceed / investigate before proceeding]
```
