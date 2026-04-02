# Model: Marketing Workbench

## Metadata

- **Name:** Marketing Workbench
- **Version:** v1.1
- **Description:** Persistent marketing analytics workbench with IMPORTRANGE raw data, shared Lookups, and 6 analytical models (Frontend Replica, Lead Cohort, Campaign Efficiency, Account Look-Back, Lead Tracing, Speed to Lead).
- **Owner:** BizOps
- **Created:** 2026-03-17

## Source & IMPORTRANGE Setup

See `sources.md` in this directory for source sheet definitions and IMPORTRANGE configuration.

---

## Tab Structure

| Tab Name | Index | Role |
|----------|-------|------|
| Raw Campaign Members | 0 | raw-data |
| Raw Leads | 1 | raw-data |
| Raw Contacts | 2 | raw-data |
| Raw Campaigns | 3 | raw-data |
| Raw Frontend Data | 4 | raw-data |
| Raw Opportunities | 5 | raw-data |
| Lookups | 6 | lookups |
| Prepared Data | 7 | prepared-data |
| Frontend Replica | 8 | analysis (Model #1) |
| Lead Cohort | 9 | analysis (Model #2) |
| Campaign Efficiency | 10 | analysis (Model #3) |
| Account Look-Back | 11 | analysis (Model #4) |
| Lead Tracing | 12 | analysis (Model #5) |
| Speed to Lead | 14 | analysis (Model #6) |
| Definitions | 15 | definitions |

**Title format:** `Marketing Analytics Workbench`

---

## Lookups

### Section 1: Campaign Mapping (A1:G{n})

| Col | Header |
|-----|--------|
| A | Campaign 18 Digit ID |
| B | Campaign ID |
| C | Name |
| D | Type |
| E | Start Date |
| F | End Date |
| G | Actual Cost |

Source: Raw Campaigns tab (Campaign tab via IMPORTRANGE).
Write with `RAW`, then rewrite col G (Actual Cost) with `USER_ENTERED` so Sheets treats numeric values correctly.

### Section 2: Opportunity Mapping (I1:O{n})

| Col | Header |
|-----|--------|
| I | Opp ID 18 Digit |
| J | Account Name |
| K | Stage |
| L | Amount |
| M | Close Date |
| N | Opp Type |
| O | Company Segment |

Source: Raw Opportunities tab.
Write with `RAW`, then rewrite col L (Amount) with `USER_ENTERED`.

### Section 3: Account Mapping (Q1:S{n})

| Col | Header |
|-----|--------|
| Q | Account ID |
| R | Account Name |
| S | Company Segment |

Source: Raw Opportunities (deduplicated by Account ID). One row per Account ID.
Write with `RAW`.

### Section 4: Lifecycle Stage Mapping (U1:Z10, hardcoded)

| Lifecycle Stage | Category | Rank | Is MQL+ | Is SQL+ | Is SAL+ |
|-----------------|----------|------|---------|---------|---------|
| Customer | Post-Sale | 1 | Yes | Yes | Yes |
| Opportunity | Post-Sale | 2 | Yes | Yes | Yes |
| SQL | Sales Qualified | 3 | Yes | Yes | Yes |
| SAL | Sales Accepted | 4 | Yes | Yes | Yes |
| MQL | Marketing Qualified | 5 | Yes | No | No |
| Lead | Pre-Qualified | 6 | No | No | No |
| Disqualified | Out | 7 | No | No | No |
| Closed Lost | Out | 8 | No | No | No |
| Partner | Other | 9 | No | No | No |

Range: U1:Z10 (header + 9 data rows).
Write with `RAW`.

### Section 5: Fiscal Period Mapping (AB1:AD13, hardcoded)

| Month Number | Fiscal Quarter | FY Add |
|--------------|---------------|--------|
| 1 | Q4 | 0 |
| 2 | Q1 | 1 |
| 3 | Q1 | 1 |
| 4 | Q1 | 1 |
| 5 | Q2 | 1 |
| 6 | Q2 | 1 |
| 7 | Q2 | 1 |
| 8 | Q3 | 1 |
| 9 | Q3 | 1 |
| 10 | Q3 | 1 |
| 11 | Q4 | 1 |
| 12 | Q4 | 1 |

Range: AB1:AD13 (header + 12 data rows).
Write with `RAW`.

### Section 6: Campaign Type Mapping (AF1:AG{n})

| Col | Header |
|-----|--------|
| AF | Campaign Type |
| AG | Campaign Type Category |

Source: Distinct Campaign Type values from Raw Campaigns. Leave Campaign Type Category blank for user to fill.
Write with `RAW`.

### Section 7: Lead Lifecycle Mapping (AI1:AQ{n})

| Col | Header |
|-----|--------|
| AI | ADMIN Lead ID 18 Digit |
| AJ | SAL Start Datetime |
| AK | SAL End Datetime |
| AL | SQL Start Datetime |
| AM | SQL End Datetime |
| AN | Lead Lifecycle Stage |
| AO | Lead Source |
| AP | Create Date |
| AQ | Touch Stage 1 Date |

Source: Raw Leads tab — cols E (Lead ID), M (SAL Start), N (SAL End), O (SQL Start), P (SQL End), H (Lifecycle Stage), S (Lead Source), R (Create Date), Q (Touch Stage 1 Date).
Write with `RAW`.

### Section 8: Contact Lifecycle Mapping (AS1:BC{n})

| Col | Header |
|-----|--------|
| AS | ADMIN Contact ID 18 Digit |
| AT | C SAL Start Datetime |
| AU | C SAL End Datetime |
| AV | C SQL Start Datetime |
| AW | C SQL End Datetime |
| AX | Contact Lifecycle Stage |
| AY | Lead Source |
| AZ | Touch Stage 1 Date |
| BA | C Lead Start Datetime |
| BB | C Opportunity Start Datetime |
| BC | Converted from Lead |

Source: Raw Contacts tab — cols F (Contact ID), K (SAL Start), L (SAL End), M (SQL Start), N (SQL End), J (Lifecycle Stage), W (Lead Source), S (Touch Stage 1 Date), U (C Lead Start), V (C Opportunity Start), T (Converted from Lead).
Write with `RAW`.

### Section 9: Lead STL + Owner Mapping (BE1:BG{n})

| Col | Header |
|-----|--------|
| BE | ADMIN Lead ID 18 Digit |
| BF | Speed to Lead |
| BG | Lead Owner |

Source: Raw Leads tab — cols E (Lead ID), T (Speed to Lead), U (Lead Owner).
Write with `RAW`, then rewrite col BF (Speed to Lead) with `USER_ENTERED` for numeric treatment.

### Section 10: Contact STL + Owner Mapping (BI1:BK{n})

| Col | Header |
|-----|--------|
| BI | ADMIN Contact ID 18 Digit |
| BJ | Speed to Lead |
| BK | Contact Owner |

Source: Raw Contacts tab — cols F (Contact ID), Y (Speed to Lead), Z (Contact Owner).
Write with `RAW`, then rewrite col BJ (Speed to Lead) with `USER_ENTERED` for numeric treatment.

---

## Tier 1 Helper Columns

Raw + Lookups only. Column letters are `[dynamic]` — discover by reading Prepared Data row 1 headers before writing.

| Col | Header | Formula (row N) | Notes |
|-----|--------|-----------------|-------|
| [dynamic] | Campaign Name | `=IFERROR(VLOOKUP(A{N},Lookups!$A:$G,3,FALSE),"")` | A = Campaign 18 Digit ID |
| [dynamic] | Campaign Type | `=IFERROR(VLOOKUP(A{N},Lookups!$A:$G,4,FALSE),"")` | |
| [dynamic] | Campaign Cost | `=IFERROR(VLOOKUP(A{N},Lookups!$A:$G,7,FALSE),"")` | |
| [dynamic] | Unified Status | `=IF([I]{N}<>"",[I]{N},[T]{N})` | I = Contact Status, T = Lead Status |
| [dynamic] | Unified Lifecycle Stage | `=IF([J]{N}<>"",[J]{N},[U]{N})` | J = Contact Lifecycle Stage, U = Lead Lifecycle Stage |
| [dynamic] | Unified Touch Stage | `=IF([M]{N}<>"",[M]{N},[V]{N})` | M = Contact Touch Stage, V = Lead Touch Stage |
| [dynamic] | Unified Sort Score | `=IF([N]{N}<>"",[N]{N},[Y]{N})` | N = Contact Sort Score, Y = Lead Sort Score |
| [dynamic] | Unified Level | `=IF([O]{N}<>"",[O]{N},[Z]{N})` | O = Contact Level, Z = Lead Level |
| [dynamic] | Unified Department | `=IF([P]{N}<>"",[P]{N},[AA]{N})` | P = Contact Department, AA = Lead Department |
| [dynamic] | Unified Account ID | `=IF([H]{N}<>"",[H]{N},[AF]{N})` | H = Account ID, AF = Converted Account ID |
| [dynamic] | Unified MQL Start Date | **Pre-computed** — 4-source cascade: CM K → CM W → Raw Contacts Q → Raw Leads K | See "Enriched Lifecycle Columns" in Implementation Notes |
| [dynamic] | Unified MQL End Date | `=IF([L]{N}<>"",DATEVALUE([L]{N}),IF([X]{N}<>"",DATEVALUE([X]{N}),""))` | L = C MQL End, X = Lead MQL End |
| [dynamic] | Unified SAL Start Date | **Pre-computed** — Raw Contacts SAL Start (via Contact ID) → Raw Leads SAL Start (via Lead ID) | See "Enriched Lifecycle Columns" in Implementation Notes |
| [dynamic] | Unified SAL End Date | `=IF([G]{N}<>"",IFERROR(DATEVALUE(LEFT(VLOOKUP([G]{N},Lookups!$AS:$BC,3,FALSE),10)),""),IF([Q]{N}<>"",IFERROR(DATEVALUE(LEFT(VLOOKUP([Q]{N},Lookups!$AI:$AQ,3,FALSE),10)),""),""))` | |
| [dynamic] | Unified SQL Start Date | **Pre-computed** — Raw Contacts SQL Start (via Contact ID) → Raw Leads SQL Start (via Lead ID) | See "Enriched Lifecycle Columns" in Implementation Notes |
| [dynamic] | Unified SQL End Date | `=IF([G]{N}<>"",IFERROR(DATEVALUE(LEFT(VLOOKUP([G]{N},Lookups!$AS:$BC,5,FALSE),10)),""),IF([Q]{N}<>"",IFERROR(DATEVALUE(LEFT(VLOOKUP([Q]{N},Lookups!$AI:$AQ,5,FALSE),10)),""),""))` | |
| [dynamic] | Campaign Start Date | `=IFERROR(VLOOKUP(A{N},Lookups!$A:$G,5,FALSE),"")` | |
| [dynamic] | Campaign End Date | `=IFERROR(VLOOKUP(A{N},Lookups!$A:$G,6,FALSE),"")` | |
| [dynamic] | Unified Lead Source | `=IF([G]{N}<>"",IFERROR(VLOOKUP([G]{N},Lookups!$AS:$BC,7,FALSE),""),IF([Q]{N}<>"",IFERROR(VLOOKUP([Q]{N},Lookups!$AI:$AQ,7,FALSE),""),""))` | Contact Lead Source first, Lead Lead Source fallback |
| [dynamic] | Unified Touch Stage 1 Date | `=IF([G]{N}<>"",IFERROR(VLOOKUP([G]{N},Lookups!$AS:$BC,8,FALSE),""),IF([Q]{N}<>"",IFERROR(VLOOKUP([Q]{N},Lookups!$AI:$AQ,9,FALSE),""),""))` | Contact col S first, Lead col Q fallback |
| [dynamic] | Unified Create Date | `=IF([G]{N}<>"",IFERROR(DATEVALUE(LEFT(VLOOKUP([G]{N},Lookups!$AS:$BC,9,FALSE),10)),""),IF([Q]{N}<>"",IFERROR(DATEVALUE(LEFT(VLOOKUP([Q]{N},Lookups!$AI:$AQ,8,FALSE),10)),""),""))` | Contact C Lead Start first, Lead Create Date fallback |
| [dynamic] | Unified Opportunity Datetime | `=IF([G]{N}<>"",IFERROR(VLOOKUP([G]{N},Lookups!$AS:$BC,10,FALSE),""),"")` | Contacts only — leads lack Opp datetime |
| [dynamic] | Origin Type | `=IF([AD]{N}="TRUE","Lead","Contact")` | AD = Converted from Lead |
| [dynamic] | Start Mo | `=IF([F]{N}="","",TEXT(DATEVALUE(LEFT([F]{N},10)),"YYYYMM"))` | F = Start Date |
| [dynamic] | Start Qtr | `=IF([F]{N}="","",VLOOKUP(MONTH(DATEVALUE(LEFT([F]{N},10))),Lookups!$AB:$AC,2,FALSE))` | |
| [dynamic] | Start Fiscal | `=IF([F]{N}="","",YEAR(DATEVALUE(LEFT([F]{N},10)))+VLOOKUP(MONTH(DATEVALUE(LEFT([F]{N},10))),Lookups!$AB:$AD,3,FALSE))` | |
| [dynamic] | Unified Speed to Lead | `=IF(LEN(G{N})>0,IFERROR(VLOOKUP(G{N},Lookups!$BI:$BJ,2,FALSE),""),IF(LEN(Q{N})>0,IFERROR(VLOOKUP(Q{N},Lookups!$BE:$BF,2,FALSE),""),""))` | Contact STL first (via Contact STL+Owner Mapping), Lead STL fallback. Minutes. |
| [dynamic] | Unified Owner | `=IF(LEN(G{N})>0,IFERROR(VLOOKUP(G{N},Lookups!$BI:$BK,3,FALSE),""),IF(LEN(Q{N})>0,IFERROR(VLOOKUP(Q{N},Lookups!$BE:$BG,3,FALSE),""),""))` | Contact Owner first, Lead Owner fallback. |

Write with `valueInputOption: USER_ENTERED` in 500-row batches.

---

## Tier 2 Helper Columns

References Tier 1 outputs. Column letters are `[dynamic]`.

| Col | Header | Formula (row N) | Notes |
|-----|--------|-----------------|-------|
| [dynamic] | Lifecycle Rank | `=IFERROR(VLOOKUP([Unified_Lifecycle]{N},Lookups!$U:$W,3,FALSE),"")` | |
| [dynamic] | Is MQL+ | `=IFERROR(VLOOKUP([Unified_Lifecycle]{N},Lookups!$U:$X,4,FALSE),"")` | |
| [dynamic] | Is SQL+ | `=IFERROR(VLOOKUP([Unified_Lifecycle]{N},Lookups!$U:$Y,5,FALSE),"")` | |
| [dynamic] | Is SAL+ | `=IFERROR(VLOOKUP([Unified_Lifecycle]{N},Lookups!$U:$Z,6,FALSE),"")` | |
| [dynamic] | Is Marketing Source | `=IF([Unified_Lead_Source]{N}="Marketing","Yes","No")` | Toggle filter for marketing-only analysis |
| [dynamic] | Has Opportunity | `=IF([AB]{N}<>"",1,0)` | AB = Converted Opportunity ID |
| [dynamic] | Days Lead to MQL | `=IF(AND([Unified_MQL_Start]{N}<>"",[Unified_Create_Date]{N}<>""),[Unified_MQL_Start]{N}-[Unified_Create_Date]{N},"")` | |
| [dynamic] | Days MQL to SAL | `=IF(AND([Unified_SAL_Start]{N}<>"",[Unified_MQL_Start]{N}<>""),[Unified_SAL_Start]{N}-[Unified_MQL_Start]{N},"")` | |
| [dynamic] | Days SAL to SQL | `=IF(AND([Unified_SQL_Start]{N}<>"",[Unified_SAL_Start]{N}<>""),[Unified_SQL_Start]{N}-[Unified_SAL_Start]{N},"")` | |
| [dynamic] | Days SQL to Opp | `=IF(AND([Unified_Opp_Datetime]{N}<>"",[Unified_SQL_Start]{N}<>""),DATEVALUE(LEFT([Unified_Opp_Datetime]{N},10))-[Unified_SQL_Start]{N},"")` | Contacts only |
| [dynamic] | Days Lead to Opp | `=IF(AND([Unified_Opp_Datetime]{N}<>"",[Unified_Create_Date]{N}<>""),DATEVALUE(LEFT([Unified_Opp_Datetime]{N},10))-[Unified_Create_Date]{N},"")` | Contacts only |
| [dynamic] | Opp Stage | `=IF([AB]{N}="","",IFERROR(VLOOKUP([AB]{N},Lookups!$I:$K,3,FALSE),""))` | |
| [dynamic] | Opp Amount | `=IF([AB]{N}="","",IFERROR(VLOOKUP([AB]{N},Lookups!$I:$L,4,FALSE),""))` | |
| [dynamic] | Opp Close Date | `=IF([AB]{N}="","",IFERROR(VLOOKUP([AB]{N},Lookups!$I:$M,5,FALSE),""))` | |
| [dynamic] | Opp Type | `=IF([AB]{N}="","",IFERROR(VLOOKUP([AB]{N},Lookups!$I:$N,6,FALSE),""))` | |
| [dynamic] | Account Name | `=IF([Unified_Acct_ID]{N}="","",IFERROR(VLOOKUP([Unified_Acct_ID]{N},Lookups!$Q:$R,2,FALSE),""))` | |
| [dynamic] | Quarter Label | `=IF([F]{N}="","","FY"&[Start_Fiscal]{N}&" "&[Start_Qtr]{N})` | |
| [dynamic] | MQL Quarter Label | `=IF(LEN(AR{N})=0,"","FY"&(YEAR(DATEVALUE(LEFT(AR{N},10)))+VLOOKUP(MONTH(DATEVALUE(LEFT(AR{N},10))),Lookups!$AB:$AD,3,FALSE))&" "&VLOOKUP(MONTH(DATEVALUE(LEFT(AR{N},10))),Lookups!$AB:$AC,2,FALSE))` | Fiscal quarter from MQL Start Date — for MQL cohort time analysis. Distinct from Quarter Label (campaign Start Date). |

Write with `USER_ENTERED` in 500-row batches.

---

## Tier 3 Helper Columns

References Tier 2 outputs. Column letters are `[dynamic]`.

| Col | Header | Formula (row N) | Notes |
|-----|--------|-----------------|-------|
| [dynamic] | Is Closed Won Opp | `=IF([Opp_Stage]{N}="9. Closed-Won",1,0)` | |
| [dynamic] | Sort Score Numeric | `=IF([Unified_Sort]{N}="","",IF(ISNUMBER([Unified_Sort]{N}),[Unified_Sort]{N},IFERROR(VALUE([Unified_Sort]{N}),"")))` | Numeric conversion of Sort Score |
| [dynamic] | New vs Previously Engaged | `=IF(OR([F]{N}="",[Unified_Create_Date]{N}=""),"",IF(DATEVALUE(LEFT([F]{N},10))<=[Unified_Create_Date]{N},"Previously Engaged","New"))` | Requires Unified Create Date to be populated |

Write with `USER_ENTERED` in 500-row batches.

---

## Sanity Checks

| Check | Rule | Threshold | Severity | Phase |
|-------|------|-----------|----------|-------|
| Row count preserved | Raw Campaign Members rows = Prepared Data rows | Exact match | hard-fail | data-quality |
| Campaign ID join coverage | 100% of rows match campaign in Lookups | 100% | hard-fail | data-quality |
| Opp join coverage | >= 90% of non-blank Converted Opp IDs resolve | 90% | warning | data-quality |
| Account join coverage | >= 80% of non-blank Unified Account IDs resolve | 80% | warning | data-quality |
| MQL count <= Total Members | Per campaign | MQLs <= Members | hard-fail | data-quality |
| Won Opps <= Total Opps | Per campaign | Won <= Total | hard-fail | data-quality |
| Opp Amount >= 0 | All resolved opportunity amounts | No negatives | warning | data-quality |
| Unified fields blank rate | Status, Lifecycle Stage blank rate | < 20% | warning | data-quality |
| Lead ID join coverage | >= 90% of non-blank Lead IDs match Raw Leads | 90% | warning | data-quality |
| Contact ID join coverage | >= 90% of non-blank Contact IDs match Raw Contacts | 90% | warning | data-quality |
| SAL date coverage | % of Is SQL+ = "Yes" with non-blank Unified SAL Start Date | Report % | info | data-quality |
| SQL date coverage | % of Is SQL+ = "Yes" with non-blank Unified SQL Start Date | Report % | info | data-quality |
| Velocity reasonableness | All velocity columns positive and < 365 days | Flag violations | warning | data-quality |
| Formula errors (data) | No #REF!, #N/A, #VALUE!, #DIV/0! in Tiers 1-3 | 0 errors | hard-fail | data-quality |
| IMPORTRANGE resolution | All 6 raw tabs resolve without #REF! | 0 errors | hard-fail | data-quality |
| Speed to Lead coverage | % of MQL+ members with non-blank Unified Speed to Lead | Report % | info | data-quality |
| Speed to Lead reasonableness | All Unified Speed to Lead values >= 0 and < 525,600 min | Flag violations | warning | data-quality |
| Owner coverage | % of members with non-blank Unified Owner | Report % | info | data-quality |

---

## Definitions Template

See `definitions-template.md` in this directory. Used by Review agent (Stage 4) to populate the Definitions tab.

---

## Writing Strategy

- **Batch size:** 500 rows per write for formula columns
- **valueInputOption:** `USER_ENTERED` for all formula columns; `RAW` for Lookups data tables (except numeric columns that need USER_ENTERED rewrite)
- **Tier order:** Tier 1 complete -> Tier 2 complete -> Tier 3 complete
- **Date handling:** Raw dates are text (e.g., "2025-02-08 15:18:35"). Formulas use `DATEVALUE(LEFT(cell,10))` to extract the date portion.
- **MQL/SAL/SQL date handling:** All datetime fields are text strings. Unified date formulas wrap values in `DATEVALUE()` so date comparisons work correctly.
- **IMPORTRANGE mode:** Skip RAW/USER_ENTERED rewrite step — Sheets interprets IMPORTRANGE values natively. Proceed directly to Lookups after IMPORTRANGE setup.
- **Duplicate header disambiguation:** Rename duplicate column headers at ingest time (Contact Status, Lead Status, etc.) per `skills/prep-marketing-data.md`.

## Implementation Notes

See `implementation-notes.md` in this directory. Critical rules for all workbench models:
- **Use SUMPRODUCT, not COUNTIFS** — COUNTIFS gives incorrect results on large formula-heavy sheets
- **Use LEN>0, not `<>""`** — API-written empty cells create phantom non-blank values
- **Pre-compute MQL/SAL/SQL dates in Python** — INDEX/MATCH across 30K+ rows hits resource limits
- **Count MQLs with LEN(MQL Start Date)>0** — matches Salesforce frontend "ever MQL'd" methodology
