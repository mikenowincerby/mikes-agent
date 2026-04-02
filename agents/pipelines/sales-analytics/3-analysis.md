# Agent: Sales Analytics Analysis

- **Role:** Writes Summary and Analysis tab formulas, deal-list outputs
- **Trigger:** Plan doc has Sheet ID, Column Map, and Data Quality acknowledged
- **Position:** Agent 3 of 4 in the Sales Analytics pipeline

## References

Read before executing:
- `.context/sales-analytics-plan.md` — the plan doc (read first, update before handoff)
- `business-logic/sales/metrics.md` — metric definitions, formulas, sanity check rules
- `business-logic/_shared/formula-rules.md` — formula-first principles
- `skills/build-sheet-formulas.md` — formula patterns, analysis tab layout, deal-list formulas
- `skills/compute-and-push.md` — Python compute fallback (only if Sheet formulas can't do it)
- `business-logic/sales/forecast-accuracy-metrics.md` — forecast accuracy formulas and tier definitions (forecast accuracy only)

## Pipeline

### Step 1: Build Column Map

Read Prepared Data row 1 to get header → column letter mapping. Or use the column map from the plan doc if Agent 2 provided it.

### Step 2: Write Analysis Tab Formulas

For each metric × dimension in the plan scope:
1. Build SUMIFS (bookings), COUNTIFS (counts), AVERAGEIFS (averages), or IFERROR ratio (win rate)
2. **Use helper column values in all filter criteria** — e.g., Pipeline Category = "Won", not Stage = "9. Closed-Won"
3. Write to Analysis tabs with section headers (see `build-sheet-formulas.md` layout)
4. Max 3 analysis tabs — consolidate with section headers

### Step 3: Write Deal-List Outputs (if requested)

Use FILTER/SORT/ARRAY_CONSTRAIN pattern from `build-sheet-formulas.md`:
- Filter on helper columns (Pipeline Category, Is Closed Won), not raw Stage
- Use explicit row ranges (e.g., `F2:F1005`), not open-ended (`F:F`)
- Clear target area before writing spilling formulas
- Write static headers in row 1, formula in A2

> Follow the summary tab structure in `codespecs/summary-tab-structure.md`.

**Sales KPIs for Section A:**
- Total Pipeline (USD) — or the primary volume metric for the analysis type
- Weighted Pipeline (USD)
- Deal Count
- Average Deal Size (USD)
- Win Rate (%)
- Additional KPIs as relevant (Won Count, Lost Count, Open Pipeline Count, etc.)

### Step 5: Handle Compute Fallback

If a calculation exceeds Sheet formula capability:
1. State why formulas can't do it
2. Use `skills/compute-and-push.md`
3. Flag computed cells for Agent 4 to document in Definitions tab

### Step 6: Update Plan Doc

Add to `.context/sales-analytics-plan.md`:
- `## Analysis Complete:` what was built (which tabs, which metrics, any formula errors fixed)

### Step 7: Format Output Sheet

Invoke `skills/format-output-sheet.md` with:
- `spreadsheetId` — the analysis sheet
- `tabManifest` — all tabs and their roles (e.g., `{tabName: "Raw Data", tabRole: "raw-data"}`, `{tabName: "Prepared Data", tabRole: "prepared-data"}`, etc.)

This applies structural formatting (headers, alignment, number formats, chromatic font colors, column widths, borders) to all tabs before handing off to the review agent.

## Anti-Patterns

- **DON'T** filter on raw Stage strings — use Pipeline Category, Is Closed Won, Closed?
- **DON'T** use QUERY for deal lists — use FILTER/SORT (handles mixed-type columns)
- **DON'T** use open-ended ranges in FILTER — use explicit row ranges to avoid #REF! spill errors
- **DON'T** build ranges missing column letter on both sides — `$AG$2:$AG$1199` is correct, `$AG$2:$1199` causes #VALUE! in multi-criteria COUNTIFS/SUMIFS

## Verification

- [ ] **Range format check**: every COUNTIFS/SUMIFS range has column letter on both sides (e.g., `$AG$2:$AG$1199`)
- [ ] **Readback**: read every analysis tab with `FORMATTED_VALUE` — no #REF!, #N/A, #DIV/0!, #VALUE! errors
- [ ] Values are non-zero where expected (bookings, counts, averages)
- [ ] Deal-list formulas spill correctly (correct row count, no empty rows)
- [ ] Summary tab has all metrics from plan scope
- [ ] Plan doc updated with analysis details

---

## Forecast Accuracy

When the analysis type is forecast accuracy, follow the standard pipeline steps above with these modifications.

### Additional References

- `business-logic/sales/forecast-accuracy-metrics.md` — accuracy formulas, tier definitions, sanity checks

### Skills Used

- `skills/build-sheet-formulas.md` — primary tool for writing accuracy formulas
- `skills/compute-and-push.md` — fallback ONLY after 3 failed formula attempts (see constraint below)

### Formula-First Hard Constraint

**Only fall back to `compute-and-push` after 3 failed formula attempts.** Each failure must be documented in the plan doc with:
1. The formula attempted
2. The error encountered
3. Why the formula approach cannot work

### Modified Pipeline

**Step 2 (Write Analysis Tab Formulas) — Accuracy Metrics:**

Write accuracy formulas for each forecast level (Commit, Commit + Most Likely, Commit + Most Likely + Best Case) and each dimension. All division formulas wrapped in `IFERROR(..., "N/A")`:

**Dollar Accuracy:**
```
=IFERROR(
  SUMIFS([Amount at actuals col], [Is Closed Won at actuals col], TRUE, [Close Date In Period at actuals col], TRUE)
  / SUMIFS([Amount at forecast col], [In Forecast: <level> col], TRUE),
  "N/A"
)
```

**Count Accuracy:**
```
=IFERROR(
  COUNTIFS([Is Closed Won at actuals col], TRUE, [Close Date In Period at actuals col], TRUE)
  / COUNTIFS([In Forecast: <level> col], TRUE),
  "N/A"
)
```

**Deal Accuracy:**
```
=IFERROR(
  COUNTIFS([Forecasted & Won: <level> col], TRUE)
  / COUNTIFS([In Forecast: <level> col], TRUE),
  "N/A"
)
```

Replace `[column references]` with actual column letters from the Prepared Data column map.

**Breakdown by cut:** Same formulas with additional SUMIFS/COUNTIFS criteria:
- By Rep: add `[Rep col], "rep name"` criterion
- By Use Case: add `[Use Case col], "use case"` criterion
- By Lead Source: add `[Lead Source col], "source"` criterion

**Step 3 (Write Deal-List Outputs) — Category Movement:**

Use FILTER/SORT to build deal lists showing category movement:
```
=FILTER(
  {[Opp ID col], [Name col], [Rep col], [Amount col], [Cat snapshot 1 col], [Cat snapshot 2 col], [Cat snapshot 3 col], [Stage at actuals col]},
  [Category Changed? col] = TRUE
)
```

Sort by Rep, then Amount descending.

**Step 4 (Write Summary Tab):**

Summary tab should contain:
- Overall accuracy metrics (Commit, Commit + Most Likely, Commit + Most Likely + Best Case) for the target period
- Dollar Accuracy, Count Accuracy, Deal Accuracy for each forecast level
- Period-over-period comparison if prior period snapshots exist
