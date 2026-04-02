# Agent: Sales Analytics Data Prep

- **Role:** Creates the analysis sheet, ingests raw data, builds Lookups + formula-based Prepared Data
- **Trigger:** Plan doc exists at `.context/sales-analytics-plan.md` with Approach Validation PASSED
- **Position:** Agent 2 of 4 in the Sales Analytics pipeline

## References

For complete business logic reading order, see `agents/pipelines/sales-analytics/domain-config.md § Reading Order`.

Read before executing:
- `.context/sales-analytics-plan.md` — the plan doc (read first, update before handoff)
- `business-logic/sales/data-prep-rules.md` — data standardization, calculated columns, quality checks
- `business-logic/sales/data-dictionary.md` — SF fields, helper field derivations, lookup mappings
- `business-logic/_shared/formula-rules.md` — formula-first principles
- `business-logic/sales/forecast-data-prep-rules.md` — forecast-specific data prep (forecast accuracy only)
- `skills/create-analysis-sheet.md` — how to create the sheet and ingest data
- `skills/prep-sales-data.md` — how to build Lookups and write row-by-row formulas

## Pipeline

### Step 0: Resolve Sources

Before any ingest, resolve source aliases from domain-config's `## Ingest Config` table:

1. For each source row, if the Params field contains `source: $ALIAS`, execute `skills/resolve-source.md` with that alias
2. The skill reads `sources.md` and returns: adapter type, connection params, column mappings, value mappings
3. Use the resolved connection params (e.g., `sheetId`) when calling the adapter skill in Step 1
4. If column mappings are returned, apply them after ingest (rename Raw Data headers to canonical names)

### Step 1: Create Sheet + Ingest

1. Create new Google Sheet with standard tab structure per `skills/create-analysis-sheet.md`
2. Read `## Ingest Config` from `domain-config.md` to determine adapter and source params
3. For each source row in Ingest Config, follow the adapter skill at `skills/ingest/{adapter}.md`:
   - Pass the source params + target sheet ID + target tab name
   - Verify the adapter output: row count, column headers, numeric columns rewritten
4. Confirm total row count matches expected source size

> Follow the Lookups build process in `codespecs/lookups-pattern.md`.

**Sales lookup sections:**
- Stage Mapping (Stage → Pipeline Category / Detail Category)
- Use Case Mapping (Primary Use Case → Use Case)
- Fiscal Period Mapping (Month Number → Fiscal Quarter / FY Add)

### Step 3: Write Prepared Data

Follow `skills/prep-sales-data.md` Steps 2-4:
1. Copy original columns from Raw Data to Prepared Data (static, `RAW`)
2. Add calculated column headers
3. Write row-by-row formulas in tier order (`USER_ENTERED`):
   - **Tier 1** (raw + Lookups): Pipeline Category, Use Case, CreateMo, CreateQtr, Create Fiscal, CloseMo, CloseQtr, Close Fiscal
   - **Tier 2** (Tier 1 helpers): Is Closed Won, Is Closed Lost, Closed?, Quarter Label, Expansion ARR
   - **Tier 3** (Tier 2 helpers): Sales Cycle Days, Pipeline Velocity Days

**Example — correct Tier 1 formula write:**
```bash
gws sheets spreadsheets values update --params '{"spreadsheetId":"[id]","range":"Prepared Data!AF2","valueInputOption":"USER_ENTERED"}' \
  --json '{"values":[["=IFERROR(VLOOKUP(G2,Lookups!$A:$B,2,FALSE),\"\")"]]}'
```

### Step 4: Data Quality Checks

Follow `skills/prep-sales-data.md` Step 5. Present the data quality report to the user. **Wait for acknowledgment before handing off to Agent 3.**

### Step 5: Update Plan Doc

Add to `.context/sales-analytics-plan.md`:
- `## Sheet:` spreadsheet ID + URL
- `## Column Map:` header name → column letter for all columns
- `## Data Quality:` summary of report + user acknowledgment

## Anti-Patterns

- **DON'T** write static values to Prepared Data calculated columns — use Sheet formulas
- **DON'T** use ARRAYFORMULA — write row-by-row
- **DON'T** write Tier 2 before Tier 1 resolves
- **DON'T** proceed to analysis without user acknowledging data quality report

## Verification

- [ ] Raw Data row count matches source
- [ ] Lookups tab populated with all 3 mapping tables
- [ ] Read back Prepared Data with `FORMATTED_VALUE` — formulas resolve without errors
- [ ] Row count: Raw Data = Prepared Data
- [ ] Plan doc updated with Sheet ID, column map, data quality summary

---

## Forecast Accuracy

When the analysis type is forecast accuracy, follow the standard pipeline steps above with these modifications.

### Additional References

- `business-logic/sales/forecast-data-prep-rules.md` — data sources, helper columns, quality checks specific to forecast accuracy
- `business-logic/sales/forecast-accuracy-metrics.md` — forecast level definitions (needed to understand helper column purpose)

### Skills Used

- `skills/create-analysis-sheet.md` — creates the analysis sheet (same as standard)
- `skills/prep-sales-data.md` — Lookups and base formula patterns (extended below for forecast-specific columns)

### Modified Pipeline

**Step 1 (Create Sheet + Ingest) changes:**
- Source data comes from TWO tabs: Opportunity (for deal attributes) and Forecast Accuracy (for snapshot data)
- Copy the relevant snapshot columns (forecast + actuals dates) from the Forecast Accuracy tab to Raw Data
- Include all 5 fields per snapshot: Amount, Forecast Category, Close Date, Next Step, Stage

**Step 2 (Build Lookups Tab) changes:**
- Same Lookups as standard analysis (Stage Mapping, Use Case Mapping, Fiscal Period Mapping)
- No additional Lookups needed for forecast accuracy

**Step 3 (Write Prepared Data) changes:**
- After copying original columns from Raw Data, write forecast-specific helper columns per `forecast-data-prep-rules.md`
- Follow the tier order defined in that document:
  - **Tier 1:** Base lookups from snapshot columns + Opportunity attribute lookups (Rep, Use Case, Lead Source)
  - **Tier 2:** Pipeline Category (at actuals), Close Date In Period booleans, Is Closed Won, In Forecast: Commit / Commit + Most Likely / Commit + Most Likely + Best Case
  - **Tier 3:** Forecasted & Won: Commit / Commit + Most Likely / Commit + Most Likely + Best Case
  - **Category movement:** Cat (snapshot 1/2/3), Category Changed?
- All columns are formulas — no static values
- Row-by-row formulas — no ARRAYFORMULA

**Step 4 (Data Quality Checks) changes:**
- Run forecast-specific quality checks from `forecast-data-prep-rules.md` instead of (not in addition to) standard checks:
  - Snapshot columns exist for both dates
  - Opp ID coverage
  - Valid Forecast Category values
  - Valid Stage values at actuals snapshot
  - Row count match
