# Skill: Format Output Sheet

## What It Does

Applies structural formatting to all tabs in an analysis sheet — headers, alignment, number formats, chromatic font colors, column widths, and border cleanup. Based on the FAST framework (Flexible, Appropriate, Structured, Transparent).

## When To Use

After Agent 3 (Analysis) completes, before Agent 4 (Review) begins — in both the sales and marketing pipelines. This is a non-destructive, formatting-only step. It never modifies cell values or formulas.

## Inputs

| Input | Required | Description |
|-------|----------|-------------|
| `spreadsheetId` | Yes | The analysis sheet |
| `tabManifest` | Yes | List of `{tabName, tabRole}` — role is one of: `raw-data`, `prepared-data`, `analysis`, `summary`, `deal-list`, `lookups`, `definitions` |

---

## Formatting Rules

### Base Layer (All Tabs)

Applied to every tab before tab-specific recipes:

1. **Verify frozen row** — confirm row 1 is frozen (`frozenRowCount: 1`). If not, freeze it.
2. **Header row styling** — bold, dark background (`#1a1a2e` → RGB 26,26,46), white text (`#ffffff`), bottom border (1px solid, `#cccccc` → RGB 204,204,204).
3. **Hide gridlines** — set `hideGridlines: true` via `updateSheetProperties`.
4. **Text alignment** — text/qualitative columns: left-aligned. Number/quantitative columns: right-aligned. Date columns: right-aligned.
5. **Date format** — all date columns: `yyyy-mm-dd` (ISO 8601).

### Tab-Specific Recipes & batchUpdate Patterns

See `format-recipes.md` for tab-role-specific formatting rules (raw-data, prepared-data, analysis, summary, deal-list, lookups, definitions) and all batchUpdate JSON request patterns.

---

## Column Classification

The agent reads row 1 headers and classifies each column by keyword matching:

| Type | Header Keywords | Alignment | Number Format |
|------|----------------|-----------|---------------|
| **Currency** | Amount, ARR, Value, Bookings, Cost, Revenue, Spend | Right | `#,##0` |
| **Percentage** | Rate, Conv, Accuracy, %, ROI | Right | `0.0%` |
| **Count** | Count, Logos, #, Members, MQLs, SQLs, Opps | Right | `#,##0` |
| **Date** | Date, Created, Closed | Right | `yyyy-mm-dd` |
| **Text** | Everything else | Left | None |

Classification is case-insensitive. If a header matches multiple types, use the first match in the table order above.

---

## Column Width Rules

Set via `updateDimensionProperties` with `DimensionRange` (dimension: `COLUMNS`).

| Column Content | Width (pixels) |
|---------------|---------------|
| Short text, IDs, booleans | 100 |
| Names, descriptions, notes | 200 |
| Numbers, currency, dates, percentages | 120 |

Width is determined by the column classification above: currency/percentage/count/date → 120px, text with "Name"/"Description"/"Note" in header → 200px, all other text → 100px.

---

## Border Rules

- **Remove vertical borders** — do not add any vertical rules
- **Light horizontal rules** between data rows: 1px solid `#e0e0e0` (RGB 224,224,224) — applied via `updateBorders` on data range (row 2 onward), bottom border only on each row
- **Header bottom border** is part of the base layer (1px solid `#cccccc`)

---

## Execution

Process each tab in the manifest sequentially:

### Per-Tab Steps

1. **Read sheet metadata** — `spreadsheets.get` with `fields=sheets.properties` to get `sheetId` (numeric), `gridProperties.rowCount`, `gridProperties.columnCount`
2. **Read row 1 headers** — `values.get` on `[tabName]!1:1` to classify columns
3. **For prepared-data only:** read plan doc to determine source vs calculated vs lookup columns for chromatic signifiers
4. **Build requests array** — combine all formatting operations for this tab into one array:
   - `updateSheetProperties` — frozen row + hidden gridlines
   - `repeatCell` — header styling, font colors, number formats, alignment, section headers, alternating rows
   - `updateDimensionProperties` — column widths
   - `updateBorders` — horizontal rules
5. **Fire single `batchUpdate`**:
   ```bash
   gws sheets spreadsheets batchUpdate --params '{
     "spreadsheetId": "[spreadsheetId]"
   }' --json '{
     "requests": [... all requests for this tab ...]
   }'
   ```
6. **Move to next tab**

## Error Handling

| Error | Action |
|-------|--------|
| `batchUpdate` fails on a tab | Log the error and tab name. Continue to next tab. Partial formatting is acceptable. |
| Sheet metadata read fails (403/404) | Skip that tab. Report in final output. |
| Ambiguous column classification (header matches nothing) | Default to text formatting (left-aligned, no number format, 100px width). |
| Tab in manifest but not in sheet | Skip. Report as "tab not found." |

---

## Verification

After formatting all tabs:

1. **Re-read each formatted tab** — `values.get` on rows 1-5 to confirm:
   - Headers are still present (not accidentally overwritten)
   - Formulas still evaluate (formatting didn't break references)
2. **Report results:**
   ```
   Formatting Complete
   -------------------
   Formatted: [list of tab names]
   Skipped: [list with reasons, if any]
   ```

---

## Constraints

- **Does NOT modify cell values or formulas** — formatting only
- **Does NOT merge cells** — banned per formatting standards
- **Does NOT add conditional formatting or heatmaps** — out of scope
- **Does NOT touch Raw Data content** — base layer styling only (headers, alignment)
- `autoResizeDimensions` returns httpError — always use manual column widths via `updateDimensionProperties`
