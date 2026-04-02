# Agent: Marketing Analytics Data Prep

- **Role:** Creates the analysis sheet, ingests raw data from multiple sources, builds Lookups + formula-based Prepared Data
- **Trigger:** Plan doc exists at `.context/marketing-analytics-plan.md` with Approach Validation PASSED
- **Position:** Agent 2 of 4 in the Marketing Analytics pipeline

## References

For complete business logic reading order, see `agents/pipelines/marketing-analytics/domain-config.md § Reading Order`.

Read before executing:
- `.context/marketing-analytics-plan.md` — the plan doc (read first, update before handoff)
- `business-logic/marketing/data-prep-rules.md` — data standardization, calculated columns, quality checks
- `business-logic/marketing/data-dictionary.md` — source fields, helper field derivations, lookup mappings
- `business-logic/_shared/formula-rules.md` — formula-first principles
- `skills/create-analysis-sheet.md` — how to create the sheet and ingest data
- `skills/prep-marketing-data.md` — how to build Lookups and write row-by-row formulas

## Pipeline

### Step 0a: Resolve Sources

Before any ingest, resolve source aliases from domain-config's `## Ingest Config` table:

1. For each source row, if the Params field contains `source: $ALIAS`, execute `skills/resolve-source.md` with that alias
2. The skill reads `sources.md` and returns: adapter type, connection params, column mappings, value mappings
3. Use the resolved connection params (e.g., `sheetId`) when calling the adapter skill in Step 1
4. If column mappings are returned, apply them after ingest (rename Raw Data headers to canonical names)

### Step 0b (conditional): IMPORTRANGE Setup

If building a workbench model (referenced in `business-logic/models/marketing-workbench/`), use IMPORTRANGE instead of copying data. Write a single IMPORTRANGE formula in cell A1 of each raw tab:

```
=IMPORTRANGE("sheet_id", "Tab Name!A2:XX")
```

This starts at row 2 to skip the metadata row. IMPORTRANGE requires one-time manual authorization per sheet pair. After IMPORTRANGE, skip the RAW/USER_ENTERED rewrite step in Step 1. For ad-hoc analyses, skip Step 0 and continue with the copy-based approach in Step 1.

### Step 1: Create Sheet + Ingest

1. Create new Google Sheet per `skills/create-analysis-sheet.md` — tab structure: Summary, Raw Campaign Data, Raw Campaign Members, Raw Opportunities, Raw Leads, Raw Contacts, Prepared Data, Analysis, Lookups, Definitions
2. **Never write to source data sheets** (Marketing Campaign Data or Daily Data sheets from plan doc `## Data Sources`). Always create a NEW analysis sheet.
3. **Conditional (workbench mode):** If plan doc specifies IMPORTRANGE mode, follow the IMPORTRANGE alternative in Step 0 above instead of direct ingest.
4. Read `## Ingest Config` from `domain-config.md` — 6 source rows, all using `sheets` adapter
5. For each source row, follow `skills/ingest/sheets.md`:
   - Write each source to its own raw tab (Raw Campaign Members, Raw Campaign Data, Raw Opportunities, Raw Leads, Raw Contacts, Master Campaign Frontend Data)
   - Verify row count per source
6. Confirm all raw tabs populated

> Follow the Lookups build process in `codespecs/lookups-pattern.md`.

**Marketing lookup sections:**
<!-- DEVIATION: Marketing has 8 Lookups sections (vs Sales' 3) due to multi-source joins + lifecycle enrichment -->

Follow `skills/prep-lookups-marketing.md` Step 1. Write all 8 sections:
1. **Campaign Mapping** (A-G) — data table from Raw Campaign Data (Campaign 18 Digit ID, Campaign ID, Name, Type, Start Date, End Date, Actual Cost). Sourced from Campaign tab.
2. **Opportunity Mapping** (I-O) — data table from Raw Opportunities (Opp ID, Account Name, Stage, Amount, Close Date, Opp Type, Company Segment)
3. **Account Mapping** (Q-S) — deduplicated from Raw Opportunities (Account ID, Account Name, Company Segment)
4. **Lifecycle Stage Mapping** (U-Z) — hardcoded, editable (Lifecycle Stage, Category, Rank, Is MQL+, Is SQL+, Is SAL+)
5. **Fiscal Period Mapping** (AB-AD) — hardcoded (Month Number, Fiscal Quarter, FY Add)
6. **Campaign Type Mapping** (AF-AG) — placeholder for user-defined grouping
7. **Lead Lifecycle Mapping** (AI-AQ) — data table from Raw Leads (ADMIN Lead ID 18 Digit, SAL Start Datetime, SAL End Datetime, SQL Start Datetime, SQL End Datetime, Lead Lifecycle Stage, Lead Source, Create Date, Touch Stage 1 Date)
8. **Contact Lifecycle Mapping** (AS-BC) — data table from Raw Contacts (ADMIN Contact ID 18 Digit, C SAL Start Datetime, C SAL End Datetime, C SQL Start Datetime, C SQL End Datetime, Contact Lifecycle Stage, Lead Source, Touch Stage 1 Date, C Lead Start Datetime, C Opportunity Start Datetime, Converted from Lead)

### Step 3: Write Prepared Data

Follow `skills/prep-lookups-marketing.md` Step 2 (copy columns) then `skills/prep-marketing-data.md` Steps 3-4:
1. Copy original columns from Raw Campaign Members to Prepared Data (static, `valueInputOption: RAW`)
2. Disambiguate duplicate headers (Campaign Member fields vs Campaign fields vs Opportunity fields)
3. Add calculated column headers
4. Write row-by-row formulas in tier order (`valueInputOption: USER_ENTERED`):
   - **Tier 1** (raw + Lookups only): Campaign Name, Campaign Type, Campaign Cost, Unified Status, Unified Lifecycle Stage, Unified Touch Stage, Unified Sort Score, Unified Level, Unified Department, Unified Account ID, Unified MQL Start Date, Unified MQL End Date, Unified SAL Start Date, Unified SAL End Date, Unified SQL Start Date, Unified SQL End Date, Campaign Start Date, Campaign End Date, Unified Lead Source, Unified Touch Stage 1 Date, Unified Create Date, Unified Opportunity Datetime, Origin Type, Start Mo, Start Qtr, Start Fiscal
   - **Tier 2** (references Tier 1): Lifecycle Rank, Is MQL+, Is SQL+, Is SAL+, Is Marketing Source, Has Opportunity, Days Lead→MQL, Days MQL→SAL, Days SAL→SQL, Days SQL→Opp, Days Lead→Opp, Opp Stage, Opp Amount, Opp Close Date, Opp Type, Account Name, Quarter Label
   - **Tier 3** (references Tier 2): Is Closed Won Opp, Sort Score Numeric, New vs Previously Engaged (requires Lead Created Date column — pending user addition)

**Example — correct Tier 1 formula write (campaign name lookup via Lookups tab):**
```bash
gws sheets spreadsheets values update --params '{"spreadsheetId":"[id]","range":"Prepared Data!AB2","valueInputOption":"USER_ENTERED"}' \
  --json '{"values":[["=IFERROR(VLOOKUP(A2,Lookups!$A:$G,3,FALSE),\"\")"]]}'
```

### Step 4: Data Quality Checks

Follow `skills/prep-marketing-data.md` Step 5. Present the data quality report to the user. **Wait for acknowledgment before handing off to Agent 3.**

### Step 5: Update Plan Doc

Add to `.context/marketing-analytics-plan.md`:
- `## Sheet:` spreadsheet ID + URL
- `## Column Map:` header name -> column letter for all columns (Raw + Prepared)
- `## Data Quality:` summary of report + user acknowledgment

## Anti-Patterns

- **DON'T** write static values to Prepared Data calculated columns — use Sheet formulas
- **DON'T** use ARRAYFORMULA — write row-by-row
- **DON'T** write Tier 2 before Tier 1 resolves
- **DON'T** proceed to analysis without user acknowledging data quality report
- **DON'T** write to source data sheets (Marketing Campaign Data or Daily Data from plan doc `## Data Sources`)

## Verification

- [ ] Raw data row counts match sources (all 6 tabs: Raw Campaign Data, Raw Campaign Members, Raw Opportunities, Raw Leads, Raw Contacts, plus Campaign tab source)
- [ ] Lookups tab populated with all 8 sections
- [ ] Velocity columns (Days Lead→MQL, Days MQL→SAL, etc.) present and resolving in Prepared Data
- [ ] Read back Prepared Data with `FORMATTED_VALUE` — formulas resolve without errors
- [ ] Row count: Raw Campaign Members = Prepared Data
- [ ] Plan doc updated with Sheet ID, column map, data quality summary
