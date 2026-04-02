<!-- NOTE: No SHARED sections. Summary tab is spec-driven (from model spec ## Summary Layout), not the standard KPI/Breakdown/Notes structure in _shared/summary-tab-structure.md. -->
# Agent 3: Analysis — Modeling Pipeline

## Role

Builds the Model & Inputs tab, writes Tier 3 helper columns in Prepared Data, builds Summary and Audit tabs, and formats all tabs. Executed directly (not dispatched). All model-specific logic comes from the spec file — this stage is generic.

## Inputs

| Input | Source |
|-------|--------|
| Plan doc | `.context/<model-name>-plan.md` |
| Model spec | Path from plan doc |
| Sheet ID | From plan doc (created by Agent 2) |
| Column map | From plan doc (Tiers 1-2 written by Agent 2) |
| Skills | `skills/build-sheet-formulas.md`, `skills/format-output-sheet.md` |

## Steps

### Step 1: Load Context

Read the plan doc and model spec. Note:
- Sheet ID and URL
- Column map from Agent 2
- Any user overrides to spec defaults

### Step 2: Build Model & Inputs Tab

From spec `## Model Sections`, for each section:

1. **Write section header** (bold, gray background) and description rows
2. **Write column headers** per the section layout
3. **Write Computed formulas** per the section's formula templates
   - Replace placeholder references (column letters, row ranges) with actual values from the column map
4. **Write Override columns** — blank cells with yellow background (#FFF2CC)
5. **Write Effective formulas** — `=IF(Override<>"", Override, Computed)`
6. **Write Sample Size formulas** (if specified in the section)

Save all positions to `.context/<model-name>-model-positions.json`:
```json
{
  "sections": {
    "A": {"headerRow": 1, "dataStartRow": 4, "dataEndRow": 8, "sampleStartRow": 12, "columns": {...}},
    "B": {...}
  }
}
```

Write with `valueInputOption: USER_ENTERED`.

### Step 3: Write Prepared Data — Tier 3 Helper Columns

From spec `## Tier 3 Columns`:
- Tier 3 formulas reference the Model & Inputs tab — use saved positions from Step 2
- Replace `{n}` in formula templates with actual row numbers
- Replace model position placeholders with actual cell references
- Handle spec `## Exceptions` — incorporate exception cascade into the appropriate Tier 3 formulas
- Write in 200-row batches with `USER_ENTERED`

**Sparse fallback logic** (if specified in spec): When a model parameter lookup returns a sample count below the sparse threshold (from Lookups), fall back to the Overall/default column instead.

### Step 4: Build Summary Tab

From spec `## Summary Layout`:

1. **Section 1 (main summary):**
   - Write section header and column headers
   - Dynamic date columns: use `EDATE(TODAY(), N)` for future months
   - Write metric formulas per the spec's formula basis
   - Reference Tier 3 columns for model output metrics
   - Reference Tier 1/2 columns for pipeline metrics

2. **Breakdown sections (2+):**
   - Read distinct values from Prepared Data for each dimension (from spec's dimension source column)
   - Filter to relevant records (e.g., open, non-excluded)
   - Cache to `.context/<model-name>-breakdown-values.json`
   - Write rows per dimension value using the spec's formula pattern

Write with `USER_ENTERED`.

### Step 5: Build Audit Tab

From spec `## Audit Tab`:
- Set up any dropdowns (data validation) per spec
- Write column headers per spec
- Write FILTER/SORT formulas per spec
- Write any derived columns (e.g., "Appears Because" logic)

Write with `USER_ENTERED`.

### Step 6: Build Additional Tabs

If the spec defines additional tabs (e.g., Data Audit), build them per their specifications.

### Step 7: Format All Tabs

Use `skills/format-output-sheet.md` with a manifest built from spec `## Tab Structure`:

```json
[
  {"tabName": "<name>", "tabRole": "<role>"},
  ...
]
```

Apply additional model-specific formatting from spec `## Model Sections`:
- Override columns: yellow background
- Section headers: gray background + bold
- Number formats per the spec (percentages, days, currency, etc.)

## Outputs

| Output | Description |
|--------|-------------|
| Model & Inputs tab | All sections with Computed/Override/Effective columns |
| Prepared Data Tier 3 | Model output columns per spec |
| Summary tab | Aggregated metrics + dimension breakdowns |
| Audit tab | Drill-down view per spec |
| Formatted sheet | All tabs formatted per FAST framework |

## Handoff to Agent 4

Update plan doc with:
- Model & Inputs positions (from `.context/<model-name>-model-positions.json`)
- Tier 3 column map
- Summary layout details
- Any formula errors encountered

Proceed to `4-review.md`.
