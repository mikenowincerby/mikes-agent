# Agent 2: Data Prep — Modeling Pipeline

## Role

Creates the analysis sheet, ingests raw data, populates Lookups, and writes Prepared Data Tiers 1-2. Executed directly (not dispatched). All model-specific logic comes from the spec file — this stage is generic.

## Inputs

For complete business logic reading order, see `agents/pipelines/modeling/domain-config.md § Reading Order`.

| Input | Source |
|-------|--------|
| Plan doc | `.context/<model-name>-plan.md` |
| Model spec | Path from plan doc (registry or .context) |
| Skills | `skills/create-analysis-sheet.md` |

## Steps

### Step 1: Load Spec

Read the plan doc to get the spec path. Read the model spec. All subsequent steps reference spec sections by name.

### Step 2: Create Analysis Sheet

Use `skills/create-analysis-sheet.md` with tab structure from spec `## Tab Structure`.

Title format from spec `## Metadata` name + current date.

### Step 3: Ingest Raw Data

Read `## Ingest Config` from `domain-config.md`. If Ingest Config says "Model-specific" (as is the default for modeling), read source config from the model spec's `## Source` section instead.

Follow the adapter skill at `skills/ingest/{adapter}.md`:
- Pass source params from spec (sheet ID, tab, row offset, column range)
- Write to Raw Data tab
- Verify row count and column headers match spec expectations

Cache raw data to `.context/<model-name>-raw-data.json` for reference.

### Step 4: Write Prepared Data — Original Columns

Copy all original columns from Raw Data to Prepared Data as static values. Freeze header row.

<!-- NOTE: Modeling Lookups are spec-driven (variable sections and content per model spec ## Lookups) instead of the standard lookups-pattern. See codespecs/lookups-pattern.md for the standard version. -->
### Step 5: Populate Lookups Tab

Write each section from spec `tiers.md` `## Lookups` (or `spec.md` `## Lookups` if present):
- Follow the specified ranges, headers, and values exactly
- Use the specified write mode (RAW or USER_ENTERED) per section
- **Use Case / categorical mappings:** Verify against actual raw data values before writing. Read distinct values from the source column and confirm all are covered.
<!-- DEVIATION: Modeling Lookups sections are spec-driven (variable count and content) rather than hardcoded -->

### Step 6: Write Prepared Data — Tier 1 Helper Columns

From spec's `tiers.md` `## Tier 1 Helper Columns`:
- Write each column's formula row by row (no ARRAYFORMULA)
- Replace `{n}` in formula templates with the actual row number
- Write with `valueInputOption: USER_ENTERED` in 200-row batches
- 1-2 second delay between batches

**Column letter verification:** The spec's column letters assume a specific number of original columns. Read the actual Prepared Data headers to confirm where helper columns start. Adjust all column references if needed.

### Step 7: Write Prepared Data — Tier 2 Helper Columns

From spec's `tiers.md` `## Tier 2 Helper Columns`:
- Same writing strategy as Tier 1
- Tier 2 formulas may reference Tier 1 columns — verify Tier 1 is complete before starting

### Step 8: Run Data Quality Checks

From spec `## Sanity Checks`, run all checks with `Phase: data-quality`:
- Read back data with `FORMATTED_VALUE` to verify formulas resolved
- For each check: compare against the specified rule and threshold
- Classify results by severity (hard-fail / warning / info)

Present quality report. **Wait for user acknowledgment before proceeding.**

If any hard-fail checks fail, investigate and fix before continuing.

## Outputs

| Output | Description |
|--------|-------------|
| Analysis sheet | Multi-tab Google Sheet with Raw Data + Lookups + Prepared Data (Tiers 1-2) |
| Sheet ID | Saved to plan doc |
| Column map | Header → column letter mapping for all columns (original + Tier 1 + Tier 2) |
| Data quality report | Presented to user |

## Handoff to Agent 3

Update plan doc with:
- Sheet ID and URL
- Column map (original + Tier 1 + Tier 2)
- Data quality summary
- Row count

Proceed to `3-analysis.md`.
