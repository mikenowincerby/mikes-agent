# Skill: Prep Marketing Data — Lookups & Raw Data Setup

Steps 0-2 of the Marketing Analytics data preparation pipeline. For Steps 3-5 (calculated columns, data quality), see `prep-marketing-data.md`.

---

### Step 0 (conditional): IMPORTRANGE Setup

If `workbenchMode` is true (building a workbench model referenced in `business-logic/models/marketing-workbench/`), write IMPORTRANGE formulas to each raw tab instead of copying data:

```bash
# Write IMPORTRANGE formula to Raw Campaign Members A1
gws sheets spreadsheets values update --params '{"spreadsheetId":"[id]","range":"Raw Campaign Members!A1","valueInputOption":"USER_ENTERED"}' \
  --json '{"values":[["=IMPORTRANGE(\"[source_sheet_id]\",\"Campaign Members!A2:AG\")"]]}'

# Write IMPORTRANGE formula to Raw Campaign Data A1
gws sheets spreadsheets values update --params '{"spreadsheetId":"[id]","range":"Raw Campaign Data!A1","valueInputOption":"USER_ENTERED"}' \
  --json '{"values":[["=IMPORTRANGE(\"[source_sheet_id]\",\"Campaign!A2:I\")"]]}'

# Write IMPORTRANGE formula to Raw Opportunities A1
gws sheets spreadsheets values update --params '{"spreadsheetId":"[id]","range":"Raw Opportunities!A1","valueInputOption":"USER_ENTERED"}' \
  --json '{"values":[["=IMPORTRANGE(\"[daily_data_sheet_id]\",\"Opportunity!A2:ZZ\")"]]}'

# Write IMPORTRANGE formula to Raw Leads A1
gws sheets spreadsheets values update --params '{"spreadsheetId":"[id]","range":"Raw Leads!A1","valueInputOption":"USER_ENTERED"}' \
  --json '{"values":[["=IMPORTRANGE(\"[source_sheet_id]\",\"Leads!A2:S\")"]]}'

# Write IMPORTRANGE formula to Raw Contacts A1
gws sheets spreadsheets values update --params '{"spreadsheetId":"[id]","range":"Raw Contacts!A1","valueInputOption":"USER_ENTERED"}' \
  --json '{"values":[["=IMPORTRANGE(\"[source_sheet_id]\",\"Contacts!A2:W\")"]]}'
```

Formula pattern: `=IMPORTRANGE("sheet_id", "Tab Name!A2:XX")`. Starts at row 2 to skip metadata. Requires one-time manual authorization per sheet pair. Verify each IMPORTRANGE resolves before proceeding.

After IMPORTRANGE setup, skip the RAW/USER_ENTERED rewrite step — Sheets interprets IMPORTRANGE values natively. Proceed directly to Step 1.

### Step 1: Populate Lookups Tab

Write 8 sections to the Lookups tab. These tables drive all VLOOKUP formulas in Prepared Data and provide join paths between the raw data sources.

**Layout (8 side-by-side sections):**

```
A1:G{n}   — Campaign Mapping (data table from Raw Campaign Data)
I1:O{n}   — Opportunity Mapping (data table from Raw Opportunities)
Q1:S{n}   — Account Mapping (data table, deduplicated)
U1:Z10    — Lifecycle Stage Mapping (hardcoded, editable)
AB1:AD13  — Fiscal Period Mapping (hardcoded)
AF1:AG{n} — Campaign Type Mapping (placeholder)
AI1:AQ{n} — Lead Lifecycle Mapping (data table from Raw Leads)
AS1:BC{n} — Contact Lifecycle Mapping (data table from Raw Contacts)
```

**Section A — Campaign Mapping (A1:G{rawCampaignsRowCount}):**

| Campaign 18 Digit ID | Campaign ID | Name | Type | Start Date | End Date | Actual Cost |
|---|---|---|---|---|---|---|

Source: Read `ADMIN Campaign 18 Digit ID`, `Campaign ID`, `Name`, `Type`, `Start Date`, `End Date`, `Actual Cost in Campaign` from Raw Campaign Data (which comes from the Campaign tab).

Write with `RAW`, then rewrite col G (`Actual Cost`) with `USER_ENTERED` so Sheets treats numeric values correctly.

**Section B — Opportunity Mapping (I1:O{rawOppsRowCount}):**

| Opp ID 18 Digit | Account Name | Stage | Amount | Close Date | Opp Type | Company Segment |
|---|---|---|---|---|---|---|

Source: Read relevant columns from Raw Opportunities.

Write with `RAW`, then rewrite col L (`Amount`) with `USER_ENTERED` so Sheets treats numeric values correctly.

**Section C — Account Mapping (Q1:S{n}, deduplicated):**

| Account ID | Account Name | Company Segment |
|---|---|---|

Source: Extract unique Account IDs from Raw Opportunities via jq/Python dedup before writing. Only one row per Account ID.

Write with `RAW`.

**Section D — Lifecycle Stage Mapping (U1:Z10, hardcoded, editable):**

| Lifecycle Stage | Category | Rank | Is MQL+ | Is SQL+ | Is SAL+ |
|---|---|---|---|---|---|
| Customer | Post-Sale | 1 | Yes | Yes | Yes |
| Opportunity | Post-Sale | 2 | Yes | Yes | Yes |
| SQL | Sales Qualified | 3 | Yes | Yes | Yes |
| SAL | Sales Accepted | 4 | Yes | Yes | Yes |
| MQL | Marketing Qualified | 5 | Yes | No | No |
| Lead | Pre-Qualified | 6 | No | No | No |
| Disqualified | Out | 7 | No | No | No |
| Closed Lost | Out | 8 | No | No | No |
| Partner | Other | 9 | No | No | No |

Write with `RAW`.

**Section E — Fiscal Period Mapping (AB1:AD13, hardcoded):**

| Month Number | Fiscal Quarter | FY Add |
|---|---|---|
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

Write with `RAW`.

**Section F — Campaign Type Mapping (AF1:AG{n}, placeholder):**

| Campaign Type | Campaign Type Category |
|---|---|

Source: Distinct `Campaign Type` values from Raw Campaign Data. Leave `Campaign Type Category` blank for user to fill.

Write with `RAW`.

**Section G — Lead Lifecycle Mapping (AI1:AQ{rawLeadsRowCount}):**

| ADMIN Lead ID 18 Digit | SAL Start Datetime | SAL End Datetime | SQL Start Datetime | SQL End Datetime | Lead Lifecycle Stage | Lead Source | Create Date | Touch Stage 1 Date |
|---|---|---|---|---|---|---|---|---|

Source: Read cols E (ADMIN Lead ID 18 Digit), M (SAL Start Datetime), N (SAL End Datetime), O (SQL Start Datetime), P (SQL End Datetime), H (Lead Lifecycle Stage), S (Lead Source), R (Create Date), Q (Touch Stage 1 Date) from Raw Leads.

Write with `RAW`.

```bash
# Read Raw Leads for Lead Lifecycle Mapping
gws sheets spreadsheets values get --params '{"spreadsheetId":"[id]","range":"Raw Leads"}'

# Write Lead Lifecycle Mapping to Lookups tab
gws sheets spreadsheets values update --params '{"spreadsheetId":"[id]","range":"Lookups!AI1","valueInputOption":"RAW"}' --json '{"values":[["ADMIN Lead ID 18 Digit","SAL Start Datetime","SAL End Datetime","SQL Start Datetime","SQL End Datetime","Lead Lifecycle Stage","Lead Source","Create Date","Touch Stage 1 Date"],...]}'
```

**Section H — Contact Lifecycle Mapping (AS1:BC{rawContactsRowCount}):**

| ADMIN Contact ID 18 Digit | C SAL Start Datetime | C SAL End Datetime | C SQL Start Datetime | C SQL End Datetime | Contact Lifecycle Stage | Lead Source | Touch Stage 1 Date | C Lead Start Datetime | C Opportunity Start Datetime | Converted from Lead |
|---|---|---|---|---|---|---|---|---|---|---|

Source: Read cols F (ADMIN Contact ID 18 Digit), K (C SAL Start Datetime), L (C SAL End Datetime), M (C SQL Start Datetime), N (C SQL End Datetime), J (Contact Lifecycle Stage), W (Lead Source), S (Touch Stage 1 Date), U (C Lead Start Datetime), V (C Opportunity Start Datetime), T (Converted from Lead) from Raw Contacts.

Write with `RAW`.

```bash
# Read Raw Contacts for Contact Lifecycle Mapping
gws sheets spreadsheets values get --params '{"spreadsheetId":"[id]","range":"Raw Contacts"}'

# Write Contact Lifecycle Mapping to Lookups tab
gws sheets spreadsheets values update --params '{"spreadsheetId":"[id]","range":"Lookups!AS1","valueInputOption":"RAW"}' --json '{"values":[["ADMIN Contact ID 18 Digit","C SAL Start Datetime","C SAL End Datetime","C SQL Start Datetime","C SQL End Datetime","Contact Lifecycle Stage","Lead Source","Touch Stage 1 Date","C Lead Start Datetime","C Opportunity Start Datetime","Converted from Lead"],...]}'
```

**Example gws CLI commands (Sections A-F):**

```bash
# Read Campaign Data for Lookups
gws sheets spreadsheets values get --params '{"spreadsheetId":"[id]","range":"Raw Campaign Data"}'

# Write Campaign Mapping to Lookups tab (7 columns)
gws sheets spreadsheets values update --params '{"spreadsheetId":"[id]","range":"Lookups!A1","valueInputOption":"RAW"}' --json '{"values":[["Campaign 18 Digit ID","Campaign ID","Name","Type","Start Date","End Date","Actual Cost"],...]}'

# Rewrite Actual Cost column with USER_ENTERED so numbers are numeric
gws sheets spreadsheets values update --params '{"spreadsheetId":"[id]","range":"Lookups!G1","valueInputOption":"USER_ENTERED"}' --json '{"values":[["Actual Cost"],["12500"],["8700"],...]}'

# Read Opportunities for Lookups
gws sheets spreadsheets values get --params '{"spreadsheetId":"[id]","range":"Raw Opportunities"}'

# Write Opportunity Mapping to Lookups tab
gws sheets spreadsheets values update --params '{"spreadsheetId":"[id]","range":"Lookups!I1","valueInputOption":"RAW"}' --json '{"values":[["Opp ID 18 Digit","Account Name","Stage","Amount","Close Date","Opp Type","Company Segment"],...]}'

# Rewrite Amount column with USER_ENTERED
gws sheets spreadsheets values update --params '{"spreadsheetId":"[id]","range":"Lookups!L1","valueInputOption":"USER_ENTERED"}' --json '{"values":[["Amount"],["50000"],["125000"],...]}'

# Write Account Mapping (deduplicated)
gws sheets spreadsheets values update --params '{"spreadsheetId":"[id]","range":"Lookups!Q1","valueInputOption":"RAW"}' --json '{"values":[["Account ID","Account Name","Company Segment"],...]}'

# Write Lifecycle Stage Mapping (6 columns including Is SAL+)
gws sheets spreadsheets values update --params '{"spreadsheetId":"[id]","range":"Lookups!U1","valueInputOption":"RAW"}' --json '{"values":[["Lifecycle Stage","Category","Rank","Is MQL+","Is SQL+","Is SAL+"],["Customer","Post-Sale","1","Yes","Yes","Yes"],["Opportunity","Post-Sale","2","Yes","Yes","Yes"],["SQL","Sales Qualified","3","Yes","Yes","Yes"],["SAL","Sales Accepted","4","Yes","Yes","Yes"],["MQL","Marketing Qualified","5","Yes","No","No"],["Lead","Pre-Qualified","6","No","No","No"],["Disqualified","Out","7","No","No","No"],["Closed Lost","Out","8","No","No","No"],["Partner","Other","9","No","No","No"]]}'

# Write Fiscal Period Mapping
gws sheets spreadsheets values update --params '{"spreadsheetId":"[id]","range":"Lookups!AB1","valueInputOption":"RAW"}' --json '{"values":[["Month Number","Fiscal Quarter","FY Add"],["1","Q4","0"],["2","Q1","1"],["3","Q1","1"],["4","Q1","1"],["5","Q2","1"],["6","Q2","1"],["7","Q2","1"],["8","Q3","1"],["9","Q3","1"],["10","Q3","1"],["11","Q4","1"],["12","Q4","1"]]}'

# Write Campaign Type Mapping (placeholder)
gws sheets spreadsheets values update --params '{"spreadsheetId":"[id]","range":"Lookups!AF1","valueInputOption":"RAW"}' --json '{"values":[["Campaign Type","Campaign Type Category"],["Webinar",""],["Email",""],...]}'
```

### Step 2: Copy Original Columns to Prepared Data

Read Raw Campaign Members. Before writing, disambiguate duplicate headers by renaming:

| Col | Original Header | Renamed Header |
|-----|----------------|----------------|
| I | Status (duplicate) | Contact Status |
| M | Touch Stage (duplicate) | Contact Touch Stage |
| N | Sort Score (duplicate) | Contact Sort Score |
| O | Level (duplicate) | Contact Level |
| P | Department (duplicate) | Contact Department |
| T | Status (duplicate) | Lead Status |
| V | Touch Stage (duplicate) | Lead Touch Stage |
| Y | Sort Score (duplicate) | Lead Sort Score |
| Z | Level (duplicate) | Lead Level |
| AA | Department (duplicate) | Lead Department |

```bash
# Read Raw Campaign Members
gws sheets spreadsheets values get --params '{"spreadsheetId":"[id]","range":"Raw Campaign Members"}'

# Write to Prepared Data (original columns with disambiguated headers)
# Batch writes of 500 rows
gws sheets spreadsheets values update --params '{"spreadsheetId":"[id]","range":"Prepared Data!A1","valueInputOption":"RAW"}' --json '{"values":[["Campaign ID","...","Contact Status","...","Lead Status","..."],...]}'
```

Write to Prepared Data with `RAW`. Batch writes of 500 rows. Freeze header row after writing:

```bash
# Freeze header row
gws sheets spreadsheets batchUpdate --params '{"spreadsheetId":"[id]"}' --json '{"requests":[{"updateSheetProperties":{"properties":{"sheetId":[prepared-data-sheet-id],"gridProperties":{"frozenRowCount":1}},"fields":"gridProperties.frozenRowCount"}}]}'
```
