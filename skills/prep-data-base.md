# Skill: Prep Data — Base Foundation

## What It Does

Shared foundation for all data-prep skills. Populates the Lookups tab, copies raw data to Prepared Data, and writes row-by-row formulas in tier order. Domain-specific prep skills extend this with their own Lookups content, calculated columns, and quality checks.

## When To Use

Extended by domain-specific prep skills (e.g., `prep-sales-data.md`). Not called directly — the domain skill calls these steps and adds its own logic.

## Inputs

| Input | Required | Source |
|-------|----------|--------|
| `spreadsheetId` | Yes | The analysis sheet (from data-prep stage) |
| `rawDataRowCount` | Yes | Row count from ingest adapter output |
| `domain-config` | Yes | Pipeline's `domain-config.md` — provides Lookups sections, sanity checks |
| `data-prep-rules` | Yes | Pipeline's data-prep-rules file (from `business-logic/{domain}/`) |
| `data-dictionary` | Yes | Pipeline's data-dictionary file (from `business-logic/{domain}/`) |

## Steps

### Step 1: Populate Lookups Tab

Read the `## Lookups Sections` from `domain-config.md`. For each section:

1. Write section header to Lookups tab at the specified column range
2. Write mapping data from `data-dictionary` (the mappings for this Lookups section)
3. Write using `valueInputOption: RAW`

**Layout:** Sections are side-by-side in the Lookups tab, separated by empty columns. Column ranges are defined in domain-config (e.g., `A1:C10`, `E1:F4`, `H1:J13`).

Verify all Lookups sections populated by reading back headers from each section's first row.

### Step 2: Copy Original Columns to Prepared Data

Read Raw Data and write to Prepared Data as static values:

```bash
gws sheets spreadsheets values get --params '{"spreadsheetId":"[id]","range":"Raw Data"}'
gws sheets spreadsheets values update --params '{"spreadsheetId":"[id]","range":"Prepared Data!A1","valueInputOption":"RAW"}' --json '{"values":[...]}'
```

Write in batches of 500 rows for large datasets. Freeze header row after writing.

### Step 3: Write Calculated Column Headers

Add headers for all calculated columns (from domain-specific prep rules) to the right of the original data in Prepared Data row 1.

**Column letter discovery:** Read existing Prepared Data headers to find the first empty column. Never hardcode column positions — they depend on the number of original columns.

Write headers with `valueInputOption: RAW`.

### Step 4: Write Row-by-Row Formulas (Tier Order)

Write formulas in tier order — each tier's dependencies must be resolved before writing the next tier. Use `valueInputOption: USER_ENTERED`.

**Tier structure:**
- **Tier 1** — References raw columns + Lookups only (VLOOKUPs, date parsing, direct references)
- **Tier 2** — References Tier 1 helper columns (aggregations, flags, derived values)
- **Tier 3** — References Tier 2 helper columns (calculations requiring full dependency chain)

**Writing strategy:** Generate all formulas for a tier, then write in batches of 500 rows using `USER_ENTERED`. Write each tier fully before starting the next.

**Date handling:** Raw Data dates are text (e.g., "2025-02-08 15:18:35") because they were written with `RAW`. Formulas use `DATEVALUE(LEFT(cell,10))` to extract the YYYY-MM-DD portion and convert to a Sheets date.

**Row-by-row formulas only** — no ARRAYFORMULA. Each cell is independently inspectable.

### Step 5: Run Data Quality Checks

Run all checks from the domain's data-prep-rules file and domain-config's `## Sanity Checks` (filtered to checks with stage = data-quality or data-prep).

1. Read back Prepared Data with `FORMATTED_VALUE` to verify formula outputs
2. For each check: compare against the specified rule and threshold
3. Classify results by severity (hard-fail / warning / info)
4. Present the data quality report to the user

**Wait for user acknowledgment before proceeding to analysis.**

## Key Rules

- **Raw Data tab is NEVER modified** — all changes go to Prepared Data
- **Lookups tab is populated BEFORE any Prepared Data formulas are written**
- **Every calculated column is a formula** — never write Python-computed static values
- **Row-by-row formulas only** — no ARRAYFORMULA
- **VLOOKUP for all mappings** — no hardcoded IF chains
- **Build in tier order** — Tier 1 → Tier 2 → Tier 3
- **Write in batches of 500 rows** with `USER_ENTERED` for formula cells
- User must acknowledge data quality report before analysis proceeds

## Outputs

| Output | Description |
|--------|-------------|
| Lookups tab | Editable mapping tables (domain-specific sections) |
| Prepared Data tab | Original columns (static) + calculated columns (row-by-row formulas) |
| Data quality report | Printed to user for review |
| Column map | Header name → column letter mapping (needed by formula skill) |
