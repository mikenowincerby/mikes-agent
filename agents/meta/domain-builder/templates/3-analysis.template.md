# Agent: {{display_name}} Analysis

- **Role:** Writes Summary and Analysis tab formulas, deal-list outputs
- **Trigger:** Plan doc has Sheet ID, Column Map, and Data Quality acknowledged
- **Position:** Agent 3 of 4 in the {{display_name}} pipeline

## References

Read before executing:
- `.context/{{pipeline_name}}-plan.md` — the plan doc (read first, update before handoff)
{{references_list}}
- `skills/build-sheet-formulas.md` — formula patterns, analysis tab layout, deal-list formulas
- `skills/compute-and-push.md` — Python compute fallback (only if Sheet formulas can't do it)

## Pipeline

### Step 1: Build Column Map

Read Prepared Data row 1 to get header → column letter mapping. Or use the column map from the plan doc if Agent 2 provided it.

### Step 2: Write Analysis Tab Formulas

For each metric × dimension in the plan scope:
1. Build SUMIFS (bookings), COUNTIFS (counts), AVERAGEIFS (averages), or IFERROR ratio (rates)
2. **Use helper column values in all filter criteria** — e.g., use Pipeline Category or Is Closed Won helpers, not raw field values
3. Write to Analysis tabs with section headers (see `build-sheet-formulas.md` layout)
4. Max 3 analysis tabs — consolidate with section headers

### Step 3: Write Deal-List Outputs (if requested)

Use FILTER/SORT/ARRAY_CONSTRAIN pattern from `build-sheet-formulas.md`:
- Filter on helper columns, not raw field values
- Use explicit row ranges (e.g., `F2:F1005`), not open-ended (`F:F`)
- Clear target area before writing spilling formulas
- Write static headers in row 1, formula in A2

### Step 4: Write Summary Tab

> Follow the summary tab structure in `codespecs/summary-tab-structure.md`.

### Step 5: Handle Compute Fallback

If a calculation exceeds Sheet formula capability:
1. State why formulas can't do it
2. Use `skills/compute-and-push.md`
3. Flag computed cells for Agent 4 to document in Definitions tab

### Step 6: Update Plan Doc

Add to `.context/{{pipeline_name}}-plan.md`:
- `## Analysis Complete:` what was built (which tabs, which metrics, any formula errors fixed)

### Step 7: Format Output Sheet

Invoke `skills/format-output-sheet.md` with:
- `spreadsheetId` — the analysis sheet
- `tabManifest` — all tabs and their roles

## Anti-Patterns

- **DON'T** filter on raw field values — use helper columns from Prepared Data
- **DON'T** use QUERY for deal lists — use FILTER/SORT (handles mixed-type columns)
- **DON'T** use open-ended ranges in FILTER — use explicit row ranges to avoid #REF! spill errors
- **DON'T** build ranges missing column letter on both sides — `$AG$2:$AG$1199` is correct, `$AG$2:$1199` causes #VALUE!
{{domain_anti_patterns}}

## Verification

- [ ] **Range format check**: every COUNTIFS/SUMIFS range has column letter on both sides
- [ ] **Readback**: read every analysis tab with `FORMATTED_VALUE` — no #REF!, #N/A, #DIV/0!, #VALUE! errors
- [ ] Values are non-zero where expected
- [ ] Deal-list formulas spill correctly (correct row count, no empty rows)
- [ ] Summary tab has all metrics from plan scope
- [ ] Plan doc updated with analysis details
