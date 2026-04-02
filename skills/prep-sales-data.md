# Skill: Prep Sales Data

## What It Does

Builds Lookups and writes Prepared Data formulas for the Sales Analytics pipeline. Extends `skills/prep-data-base.md` with sales-specific mappings and calculated columns.

## Base Skill

Follow `skills/prep-data-base.md` for the shared pattern (Lookups → Copy → Headers → Tiers → Quality Checks). This file provides the sales-specific content for each step.

## When To Use

Step 4 (Prep) of the Sales Analytics pipeline.

## Inputs

| Input | Required | Description |
|-------|----------|-------------|
| `spreadsheetId` | Yes | The analysis sheet (created by `create-analysis-sheet`) |
| `rawDataRange` | Yes | Row count of Raw Data (e.g., 1005 rows including header) |

## How To Invoke

### Sales-Specific: Lookups Content (base Step 1)

3 side-by-side sections for the Lookups tab. Write mapping tables from `business-logic/sales/data-dictionary.md`. The user can edit them to change categorizations.

**Layout (3 side-by-side sections):**

```
A1:C10  — Stage Mapping
E1:F4   — Use Case Mapping
H1:J13  — Fiscal Period Mapping
```

**Section A — Stage Mapping:**

| Stage | Pipeline Category | Detail Category |
|-------|------------------|-----------------|
| 1. Lead Verification | PrePipeline | PrePipeline |
| 2. Discovery | Pipeline | Early Pipeline |
| 3. Scoping | Pipeline | Early Pipeline |
| 4. Solution Validation \| Trial | Pipeline | Mid Pipeline |
| 5. Solutions Proposal | Pipeline | Mid Pipeline |
| 6. Negotiate and Close | Pipeline | Late Pipeline |
| 9. Closed-Won | Won | Won |
| 10. Closed-Lost | Lost | Lost |
| 11. Qualified-Out | QualifiedOut | QualifiedOut |

**Section B — Use Case Mapping:**

| Primary Use Case (raw) | Use Case |
|------------------------|----------|
| Social Media Access (Shared Accounts) | Social Media Access |
| Access Management (EPM, SSO, MFA) | Access Management |
| Identity Security (Lifecycle, Posture) | Identity Security |

(Unmatched values default to "Other" via IFERROR wrapper in formulas)

**Section C — Fiscal Period Mapping:**

| Month Num | Fiscal Quarter | FY Add |
|-----------|---------------|--------|
| 1 | Q4 | 0 |
| 2 | Q1 | 1 |
| ... | ... | ... |
| 12 | Q4 | 1 |

Write using `valueInputOption: RAW`.

### Step 2: Copy Original Columns to Prepared Data

Read Raw Data and write to Prepared Data as static values:

```bash
# Read Raw Data (skip title row if present — header is row with field names)
gws sheets spreadsheets values get --params '{"spreadsheetId":"[id]","range":"Raw Data"}'

# Write to Prepared Data (original columns only)
gws sheets spreadsheets values update --params '{"spreadsheetId":"[id]","range":"Prepared Data!A1","valueInputOption":"RAW"}' --json '{"values":[...]}'
```

Write in batches of 500 rows for large datasets. Freeze header row after writing.

### Step 3: Write Calculated Column Headers

Add headers for all calculated columns to the right of the original data in row 1:

| Col | Header |
|-----|--------|
| V | Sales Cycle Days |
| W | Pipeline Velocity Days |
| X | CreateMo |
| Y | CreateQtr |
| Z | Create Fiscal |
| AA | CloseMo |
| AB | CloseQtr |
| AC | Close Fiscal |
| AD | Quarter Label (Close) |
| AE | Use Case |
| AF | Pipeline Category |
| AG | Expansion ARR |
| AH | Is Closed Won |
| AI | Is Closed Lost |
| AJ | Closed? |

**Note:** Column letters depend on how many original columns exist. Always discover dynamically — don't assume fixed positions.

### Sales-Specific: Calculated Columns (base Step 4)

Column letters below assume the original data ends at column U (21 cols). Always discover dynamically — don't assume fixed positions.

Write formulas in tier order — each tier's dependencies must be resolved before writing the next tier. Use `valueInputOption: USER_ENTERED`.

**Tier 1 — References raw columns + Lookups only:**

| Col | Header | Formula (row N) |
|-----|--------|----------------|
| AF | Pipeline Category | `=IFERROR(VLOOKUP(G{N},Lookups!$A:$B,2,FALSE),"")` |
| AE | Use Case | `=IFERROR(VLOOKUP(Q{N},Lookups!$E:$F,2,FALSE),"Other")` |
| X | CreateMo | `=IF(H{N}="","",TEXT(DATEVALUE(LEFT(H{N},10)),"YYYYMM"))` |
| Y | CreateQtr | `=IF(H{N}="","",VLOOKUP(MONTH(DATEVALUE(LEFT(H{N},10))),Lookups!$H:$I,2,FALSE))` |
| Z | Create Fiscal | `=IF(H{N}="","",YEAR(DATEVALUE(LEFT(H{N},10)))+VLOOKUP(MONTH(DATEVALUE(LEFT(H{N},10))),Lookups!$H:$J,3,FALSE))` |
| AA | CloseMo | `=IF(J{N}="","",TEXT(DATEVALUE(LEFT(J{N},10)),"YYYYMM"))` |
| AB | CloseQtr | `=IF(J{N}="","",VLOOKUP(MONTH(DATEVALUE(LEFT(J{N},10))),Lookups!$H:$I,2,FALSE))` |
| AC | Close Fiscal | `=IF(J{N}="","",YEAR(DATEVALUE(LEFT(J{N},10)))+VLOOKUP(MONTH(DATEVALUE(LEFT(J{N},10))),Lookups!$H:$J,3,FALSE))` |

**Tier 2 — References Tier 1 helper columns:**

| Col | Header | Formula (row N) |
|-----|--------|----------------|
| AH | Is Closed Won | `=IF(AF{N}="Won",1,0)` |
| AI | Is Closed Lost | `=IF(AF{N}="Lost",1,0)` |
| AJ | Closed? | `=IF(OR(AF{N}="Won",AF{N}="Lost"),1,0)` |
| AD | Quarter Label (Close) | `=IF(J{N}="","","FY"&AC{N}&" "&AB{N})` |
| AG | Expansion ARR | `=IF(AND(F{N}="Existing Business",T{N}>0),T{N},0)` |

**Tier 3 — References Tier 2 helper columns:**

| Col | Header | Formula (row N) |
|-----|--------|----------------|
| V | Sales Cycle Days | `=IF(AJ{N}=1,DATEVALUE(LEFT(J{N},10))-DATEVALUE(LEFT(H{N},10)),"")` |
| W | Pipeline Velocity Days | `=IF(AND(AH{N}=1,I{N}<>""),DATEVALUE(LEFT(J{N},10))-DATEVALUE(LEFT(I{N},10)),"")` |

**Writing strategy:** Generate all formulas for a tier in Python, then write in batches of 500 rows using `USER_ENTERED`. Write each tier fully before starting the next.

**Date handling:** Raw Data dates are text (e.g., "2025-02-08 15:18:35") because they were written with `RAW`. Formulas use `DATEVALUE(LEFT(cell,10))` to extract the YYYY-MM-DD portion and convert to a Sheets date.

### Sales-Specific: Quality Checks (base Step 5)

Run all checks from `business-logic/sales/data-prep-rules.md`. Read back Prepared Data with `FORMATTED_VALUE` to verify formula outputs, then present the report to the user.

**Wait for user acknowledgment before proceeding to analysis.**

## Outputs

| Output | Description |
|--------|-------------|
| Lookups tab | Editable mapping tables (Stage, Use Case, Fiscal Period) |
| Prepared Data tab | Original columns (static) + calculated columns (row-by-row formulas) |
| Data quality report | Printed to user for review |
| Column map | Header name → column letter mapping (needed by formula skill) |

## Key Rules

- **Raw Data tab is NEVER modified** — all changes go to Prepared Data
- **Lookups tab is populated BEFORE any Prepared Data formulas are written**
- **Every calculated column is a formula** — never write Python-computed static values
- **Row-by-row formulas only** — no ARRAYFORMULA. Each cell is independently inspectable
- **VLOOKUP for all mappings** — no hardcoded IF chains. If a mapping needs to change, the user edits the Lookups tab
- **Build in tier order** — Tier 1 → Tier 2 → Tier 3. Dependencies must resolve before dependents
- **Write in batches of 500 rows** with `USER_ENTERED` for formula cells
- User must acknowledge data quality report before analysis proceeds
