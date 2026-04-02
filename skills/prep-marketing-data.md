# Skill: Prep Marketing Data

## What It Does

Populates the Lookups tab with join-enabling data tables and mapping tables, copies raw Campaign Member data to Prepared Data, disambiguates duplicate column headers, and writes row-by-row Google Sheets formulas for all calculated columns. Every calculated cell is a formula — not a static value.

## When To Use

Data preparation step of the Marketing Analytics pipeline (Agent 2).

## Inputs

| Input | Required | Description |
|-------|----------|-------------|
| `spreadsheetId` | Yes | The analysis sheet (created by `create-analysis-sheet`) |
| `rawMembersRowCount` | Yes | Row count of Raw Campaign Members (including header) |
| `rawOppsRowCount` | Yes | Row count of Raw Opportunities (including header) |
| `rawCampaignsRowCount` | Yes | Row count of Raw Campaign Data (including header) |
| `rawLeadsRowCount` | Yes | Row count of Raw Leads (including header) |
| `rawContactsRowCount` | Yes | Row count of Raw Contacts (including header) |
| `workbenchMode` | No | If true, raw tabs were populated via IMPORTRANGE (skip RAW/USER_ENTERED rewrite) |

## How To Invoke

### Steps 0-2: Lookups & Raw Data Setup

See `prep-lookups-marketing.md` for IMPORTRANGE setup (Step 0), Lookups tab population (Step 1), and raw data copy to Prepared Data (Step 2).

### Step 3: Write Calculated Column Headers

Add headers for all calculated columns to the right of original data in row 1. Reference `business-logic/marketing/data-dictionary.md` for the full list.

**Note:** Column letters depend on how many original columns exist. Always discover dynamically by reading Prepared Data row 1 — do not assume fixed positions.

```bash
# Read current headers to discover next available column
gws sheets spreadsheets values get --params '{"spreadsheetId":"[id]","range":"Prepared Data!1:1"}'

# Write calculated column headers starting at the next available column
gws sheets spreadsheets values update --params '{"spreadsheetId":"[id]","range":"Prepared Data![col]1","valueInputOption":"RAW"}' --json '{"values":[["Campaign Name","Campaign Type","Campaign Cost","Unified Status","Unified Lifecycle Stage","Unified Touch Stage","Unified Sort Score","Unified Level","Unified Department","Unified Account ID","Unified MQL Start Date","Unified MQL End Date","Unified SAL Start Date","Unified SAL End Date","Unified SQL Start Date","Unified SQL End Date","Campaign Start Date","Campaign End Date","Unified Lead Source","Unified Touch Stage 1 Date","Unified Create Date","Unified Opportunity Datetime","Origin Type","Start Mo","Start Qtr","Start Fiscal","Lifecycle Rank","Is MQL+","Is SQL+","Is SAL+","Is Marketing Source","Has Opportunity","Days Lead to MQL","Days MQL to SAL","Days SAL to SQL","Days SQL to Opp","Days Lead to Opp","Opp Stage","Opp Amount","Opp Close Date","Opp Type","Account Name","Quarter Label","Is Closed Won Opp","Sort Score Numeric","New vs Previously Engaged"]]}'
```

### Step 4: Write Row-by-Row Formulas (Tier Order)

Write formulas in tier order — each tier's dependencies must be resolved before writing the next tier. Use `valueInputOption: USER_ENTERED`.

**Tier 1 — References raw columns + Lookups only:**

| Col | Header | Formula (row N) |
|-----|--------|----------------|
| [dynamic] | Campaign Name | `=IFERROR(VLOOKUP(A{N},Lookups!$A:$G,3,FALSE),"")` |
| [dynamic] | Campaign Type | `=IFERROR(VLOOKUP(A{N},Lookups!$A:$G,4,FALSE),"")` |
| [dynamic] | Campaign Cost | `=IFERROR(VLOOKUP(A{N},Lookups!$A:$G,7,FALSE),"")` |
| [dynamic] | Unified Status | `=IF(I{N}<>"",I{N},T{N})` |
| [dynamic] | Unified Lifecycle Stage | `=IF(J{N}<>"",J{N},U{N})` |
| [dynamic] | Unified Touch Stage | `=IF(M{N}<>"",M{N},V{N})` |
| [dynamic] | Unified Sort Score | `=IF(N{N}<>"",N{N},Y{N})` |
| [dynamic] | Unified Level | `=IF(O{N}<>"",O{N},Z{N})` |
| [dynamic] | Unified Department | `=IF(P{N}<>"",P{N},AA{N})` |
| [dynamic] | Unified Account ID | `=IF(H{N}<>"",H{N},AF{N})` |
| [dynamic] | Unified MQL Start Date | **Pre-computed in Python** — 4-source cascade: CM K (Contact MQL) → CM W (Lead MQL) → Raw Contacts Q (via Contact ID) → Raw Leads K (via Lead ID). Written as static values with `RAW`. |
| [dynamic] | Unified MQL End Date | `=IF(L{N}<>"",DATEVALUE(L{N}),IF(X{N}<>"",DATEVALUE(X{N}),""))` |
| [dynamic] | Unified SAL Start Date | **Pre-computed in Python** — Contact SAL Start (from Raw Contacts via Contact ID) → Lead SAL Start (from Raw Leads via Lead ID). Written as static values with `RAW`. |
| [dynamic] | Unified SAL End Date | `=IF(G{N}<>"",IFERROR(DATEVALUE(LEFT(VLOOKUP(G{N},Lookups!$AS:$BC,3,FALSE),10)),""),IF(Q{N}<>"",IFERROR(DATEVALUE(LEFT(VLOOKUP(Q{N},Lookups!$AI:$AQ,3,FALSE),10)),""),""))` |
| [dynamic] | Unified SQL Start Date | **Pre-computed in Python** — Contact SQL Start (from Raw Contacts via Contact ID) → Lead SQL Start (from Raw Leads via Lead ID). Written as static values with `RAW`. |
| [dynamic] | Unified SQL End Date | `=IF(G{N}<>"",IFERROR(DATEVALUE(LEFT(VLOOKUP(G{N},Lookups!$AS:$BC,5,FALSE),10)),""),IF(Q{N}<>"",IFERROR(DATEVALUE(LEFT(VLOOKUP(Q{N},Lookups!$AI:$AQ,5,FALSE),10)),""),""))` |
| [dynamic] | Campaign Start Date | `=IFERROR(VLOOKUP(A{N},Lookups!$A:$G,5,FALSE),"")` |
| [dynamic] | Campaign End Date | `=IFERROR(VLOOKUP(A{N},Lookups!$A:$G,6,FALSE),"")` |
| [dynamic] | Unified Lead Source | `=IF(G{N}<>"",IFERROR(VLOOKUP(G{N},Lookups!$AS:$BC,7,FALSE),""),IF(Q{N}<>"",IFERROR(VLOOKUP(Q{N},Lookups!$AI:$AQ,7,FALSE),""),""))` |
| [dynamic] | Unified Touch Stage 1 Date | `=IF(G{N}<>"",IFERROR(VLOOKUP(G{N},Lookups!$AS:$BC,8,FALSE),""),IF(Q{N}<>"",IFERROR(VLOOKUP(Q{N},Lookups!$AI:$AQ,9,FALSE),""),""))` |
| [dynamic] | Unified Create Date | `=IF(G{N}<>"",IFERROR(DATEVALUE(LEFT(VLOOKUP(G{N},Lookups!$AS:$BC,9,FALSE),10)),""),IF(Q{N}<>"",IFERROR(DATEVALUE(LEFT(VLOOKUP(Q{N},Lookups!$AI:$AQ,8,FALSE),10)),""),""))` |
| [dynamic] | Unified Opportunity Datetime | `=IF(G{N}<>"",IFERROR(VLOOKUP(G{N},Lookups!$AS:$BC,10,FALSE),""),"")` |
| [dynamic] | Origin Type | `=IF(AD{N}="TRUE","Lead","Contact")` |
| [dynamic] | Start Mo | `=IF(F{N}="","",TEXT(DATEVALUE(LEFT(F{N},10)),"YYYYMM"))` |
| [dynamic] | Start Qtr | `=IF(F{N}="","",VLOOKUP(MONTH(DATEVALUE(LEFT(F{N},10))),Lookups!$AB:$AC,2,FALSE))` |
| [dynamic] | Start Fiscal | `=IF(F{N}="","",YEAR(DATEVALUE(LEFT(F{N},10)))+VLOOKUP(MONTH(DATEVALUE(LEFT(F{N},10))),Lookups!$AB:$AD,3,FALSE))` |

**Tier 2 — References Tier 1 helper columns:**

| Col | Header | Formula (row N) |
|-----|--------|----------------|
| [dynamic] | Lifecycle Rank | `=IFERROR(VLOOKUP([Unified_Lifecycle]{N},Lookups!$U:$W,3,FALSE),"")` |
| [dynamic] | Is MQL+ | `=IFERROR(VLOOKUP([Unified_Lifecycle]{N},Lookups!$U:$X,4,FALSE),"")` |
| [dynamic] | Is SQL+ | `=IFERROR(VLOOKUP([Unified_Lifecycle]{N},Lookups!$U:$Y,5,FALSE),"")` |
| [dynamic] | Is SAL+ | `=IFERROR(VLOOKUP([Unified_Lifecycle]{N},Lookups!$U:$Z,6,FALSE),"")` |
| [dynamic] | Is Marketing Source | `=IF([Unified_Lead_Source]{N}="Marketing","Yes","No")` |
| [dynamic] | Has Opportunity | `=IF(AB{N}<>"",1,0)` |
| [dynamic] | Days Lead to MQL | `=IF(AND([Unified_MQL_Start]{N}<>"",[Unified_Create_Date]{N}<>""),[Unified_MQL_Start]{N}-[Unified_Create_Date]{N},"")` |
| [dynamic] | Days MQL to SAL | `=IF(AND([Unified_SAL_Start]{N}<>"",[Unified_MQL_Start]{N}<>""),[Unified_SAL_Start]{N}-[Unified_MQL_Start]{N},"")` |
| [dynamic] | Days SAL to SQL | `=IF(AND([Unified_SQL_Start]{N}<>"",[Unified_SAL_Start]{N}<>""),[Unified_SQL_Start]{N}-[Unified_SAL_Start]{N},"")` |
| [dynamic] | Days SQL to Opp | `=IF(AND([Unified_Opp_Datetime]{N}<>"",[Unified_SQL_Start]{N}<>""),DATEVALUE(LEFT([Unified_Opp_Datetime]{N},10))-[Unified_SQL_Start]{N},"")` |
| [dynamic] | Days Lead to Opp | `=IF(AND([Unified_Opp_Datetime]{N}<>"",[Unified_Create_Date]{N}<>""),DATEVALUE(LEFT([Unified_Opp_Datetime]{N},10))-[Unified_Create_Date]{N},"")` |
| [dynamic] | Opp Stage | `=IF(AB{N}="","",IFERROR(VLOOKUP(AB{N},Lookups!$I:$K,3,FALSE),""))` |
| [dynamic] | Opp Amount | `=IF(AB{N}="","",IFERROR(VLOOKUP(AB{N},Lookups!$I:$L,4,FALSE),""))` |
| [dynamic] | Opp Close Date | `=IF(AB{N}="","",IFERROR(VLOOKUP(AB{N},Lookups!$I:$M,5,FALSE),""))` |
| [dynamic] | Opp Type | `=IF(AB{N}="","",IFERROR(VLOOKUP(AB{N},Lookups!$I:$N,6,FALSE),""))` |
| [dynamic] | Account Name | `=IF([Unified_Acct_ID]{N}="","",IFERROR(VLOOKUP([Unified_Acct_ID]{N},Lookups!$Q:$R,2,FALSE),""))` |
| [dynamic] | Quarter Label | `=IF(F{N}="","","FY"&[Start_Fiscal]{N}&" "&[Start_Qtr]{N})` |

**Tier 3 — References Tier 2 helper columns:**

| Col | Header | Formula (row N) |
|-----|--------|----------------|
| [dynamic] | Is Closed Won Opp | `=IF([Opp_Stage]{N}="9. Closed-Won",1,0)` |
| [dynamic] | Sort Score Numeric | `=IF([Unified_Sort]{N}="","",IF(ISNUMBER([Unified_Sort]{N}),[Unified_Sort]{N},IFERROR(VALUE([Unified_Sort]{N}),"")))` |
| [dynamic] | New vs Previously Engaged | `=IF(OR(F{N}="",[Lead_Created_Date]{N}=""),"",IF(DATEVALUE(LEFT(F{N},10))<=DATEVALUE(LEFT([Lead_Created_Date]{N},10)),"Previously Engaged","New"))` |

**Note:** "New vs Previously Engaged" requires a Lead Created Date column in the source data. If this column is not present in Raw Campaign Members, skip this formula and leave the column header as a placeholder.

**Note:** Column letters shown above are indicative based on the original data layout. Actual column letters MUST be discovered dynamically by reading Prepared Data row 1 headers before writing formulas. Replace `[Unified_Lifecycle]`, `[Unified_Acct_ID]`, `[Unified_Sort]`, `[Unified_Lead_Source]`, `[Unified_MQL_Start]`, `[Unified_SAL_Start]`, `[Unified_SQL_Start]`, `[Unified_Create_Date]`, `[Unified_Opp_Datetime]`, `[Start_Fiscal]`, `[Start_Qtr]`, `[Opp_Stage]`, and `[Lead_Created_Date]` with the actual column letters discovered from the header row.

**Writing strategy:** Generate all formulas for a tier in Python, then write in batches of 500 rows using `USER_ENTERED`. Write each tier fully before starting the next.

**Date handling:** Raw Data dates are text (e.g., "2025-02-08 15:18:35") because they were written with `RAW`. Formulas use `DATEVALUE(LEFT(cell,10))` to extract the YYYY-MM-DD portion and convert to a Sheets date.

**MQL date handling:** MQL Start/End Date fields (K, L for contact; W, X for lead) are also text strings. The Unified MQL Start/End Date formulas wrap values in `DATEVALUE()` so date comparisons (`<=`, `>=`) work correctly. Without DATEVALUE, Sheets compares text strings lexicographically, causing silent failures in period-based MQL counting.

**SAL/SQL date handling:** SAL/SQL dates come from the Leads/Contacts tabs via Lifecycle Mappings in the Lookups tab. These are also text strings (datetimes). Formulas use `DATEVALUE(LEFT(...,10))` to convert to Sheets dates.

### Step 5: Run Data Quality Checks

Run all checks from `business-logic/marketing/data-prep-rules.md`. Read back Prepared Data with `FORMATTED_VALUE` to verify formula outputs, then present the report to the user.

**Wait for user acknowledgment before proceeding to analysis.**

## Outputs

| Output | Description |
|--------|-------------|
| Lookups tab | 8 sections: Campaign Mapping (7 cols), Opportunity Mapping, Account Mapping, Lifecycle Stage Mapping (6 cols incl. Is SAL+), Fiscal Period Mapping, Campaign Type Mapping, Lead Lifecycle Mapping (9 cols), Contact Lifecycle Mapping (11 cols) |
| Prepared Data tab | Original columns (static, renamed headers) + calculated columns (row-by-row formulas) including velocity columns (Days Lead to MQL, Days MQL to SAL, Days SAL to SQL, Days SQL to Opp, Days Lead to Opp) |
| Data quality report | Printed to user for review |
| Column map | Header name → column letter mapping (needed by analysis agent) |

## Key Rules

- **Raw Data tabs are NEVER modified** — all changes go to Prepared Data and Lookups
- **Lookups tab is populated BEFORE any Prepared Data formulas are written**
- **Every calculated column is a formula** — except Unified MQL/SAL/SQL Start Dates which are pre-computed in Python (see enrichment note below)
- **Row-by-row formulas only** — no ARRAYFORMULA. Each cell is independently inspectable
- **VLOOKUP for all mappings and joins** — no hardcoded IF chains. If a mapping needs to change, the user edits the Lookups tab
- **Build in tier order** — Tier 1 → Tier 2 → Tier 3. Dependencies must resolve before dependents
- **Write in batches of 500 rows** with `USER_ENTERED` for formula cells
- User must acknowledge data quality report before analysis proceeds
- **Duplicate column headers must be disambiguated at ingest time** — rename before writing to Prepared Data
- **Contact-first precedence for all unified fields** — Contact value wins when both Contact and Lead values exist
- **Account ID → Converted Account ID fallback** for account joins — use Contact Account ID first, fall back to Lead Converted Account ID
- **All gws CLI operations** — never raw curl
- **IMPORTRANGE mode:** When `workbenchMode` is true, skip the RAW/USER_ENTERED rewrite step — Sheets interprets IMPORTRANGE values natively
- **SUMPRODUCT over COUNTIFS:** All analysis formulas must use SUMPRODUCT, not COUNTIFS. COUNTIFS gives incorrect results on large formula-heavy Google Sheets (known bug). Use `LEN(cell)>0` instead of `<>""` for non-blank checks (phantom blank cells from API writes).
- **Pre-computed enrichment columns:** Unified MQL Start Date, Unified SAL Start Date, and Unified SQL Start Date are pre-computed in Python using a 4-source cascade (CM Contact → CM Lead → Raw Contacts lookup → Raw Leads lookup) and pasted as static values. INDEX/MATCH formulas across 30K+ rows exceed Sheets resource limits when applied to 9K+ rows. These are the ONLY columns that use static values instead of formulas.
