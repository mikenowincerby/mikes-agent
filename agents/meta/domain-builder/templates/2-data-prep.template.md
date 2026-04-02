# Agent: {{display_name}} Data Prep

- **Role:** Creates the analysis sheet, ingests raw data, builds Lookups + formula-based Prepared Data
- **Trigger:** Plan doc exists at `.context/{{pipeline_name}}-plan.md` with Approach Validation PASSED
- **Position:** Agent 2 of 4 in the {{display_name}} pipeline

## References

For complete business logic reading order, see `{{manifest_path}}` § Data Prep.

Read before executing:
- `.context/{{pipeline_name}}-plan.md` — the plan doc (read first, update before handoff)
{{references_list}}
- `skills/create-analysis-sheet.md` — how to create the sheet and ingest data

## Pipeline

### Step 1: Create Sheet + Ingest

1. Create new Google Sheet with standard tab structure per `skills/create-analysis-sheet.md`
2. Read `## Ingest Config` from `domain-config.md` to determine adapter and source params
3. For each source row in Ingest Config, follow the adapter skill at `skills/ingest/{adapter}.md`:
   - Pass the source params + target sheet ID + target tab name
   - Verify the adapter output: row count, column headers, numeric columns rewritten
4. Confirm total row count matches expected source size

### Step 2: Build Lookups Tab

> Follow the Lookups build process in `codespecs/lookups-pattern.md`.

**{{display_name}} lookup sections:**

For each section in `domain-config.md` → Lookups Sections, write the mapping table:

| # | Section | Key Column | Value Columns | Source |
|---|---------|------------|---------------|--------|
{{lookups_table_rows}}

Refer to `business-logic/{{domain}}/data-dictionary.md` for exact key→value mappings.

### Step 3: Write Prepared Data

1. Copy original columns from Raw Data to Prepared Data (static, `RAW`)
2. Add calculated column headers
3. Write row-by-row formulas in tier order (`USER_ENTERED`):

   Refer to `business-logic/{{domain}}/data-prep-rules.md` for complete formulas.

   Column summary (names only — formulas in data-prep-rules.md):
   - **Tier 1** (raw + Lookups): {{tier_1_columns}}
   - **Tier 2** (derived from Tier 1): {{tier_2_columns}}
   - **Tier 3** (derived from Tier 2): {{tier_3_columns}}

### Step 4: Data Quality Checks

Run data quality checks per the domain's data-prep-rules. Present the data quality report to the user. **Wait for acknowledgment before handing off to Agent 3.**

### Step 5: Update Plan Doc

Add to `.context/{{pipeline_name}}-plan.md`:
- `## Sheet:` spreadsheet ID + URL
- `## Column Map:` header name → column letter for all columns
- `## Data Quality:` summary of report + user acknowledgment

## Anti-Patterns

- **DON'T** write static values to Prepared Data calculated columns — use Sheet formulas
- **DON'T** use ARRAYFORMULA — write row-by-row
- **DON'T** write Tier 2 before Tier 1 resolves
- **DON'T** proceed to analysis without user acknowledging data quality report
{{domain_anti_patterns}}

## Verification

- [ ] Raw Data row count matches source
- [ ] Lookups tab populated with all mapping tables
- [ ] Read back Prepared Data with `FORMATTED_VALUE` — formulas resolve without errors
- [ ] Row count: Raw Data = Prepared Data
- [ ] Plan doc updated with Sheet ID, column map, data quality summary
