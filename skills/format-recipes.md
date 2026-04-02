# Format Output Sheet — Tab-Specific Recipes & batchUpdate Patterns

Tab-role-specific formatting rules and all batchUpdate JSON request patterns. For base layer rules, column classification, and execution flow, see `format-output-sheet.md`.

---

## Tab-Specific Recipes

#### raw-data
- Base layer only
- No font color changes (this is source data, preserve as-is)

#### prepared-data
- Base layer + **chromatic signifiers** on data cells (row 2 onward):
  - **Blue font** (`#0000ff` → RGB 0,0,255): source columns carried forward from Raw Data (written with `RAW` during ingest)
  - **Black font** (`#000000` → RGB 0,0,0): calculated helper columns (formulas written during data prep)
  - **Green font** (`#006400` → RGB 0,100,0): columns sourced from Lookups tab (VLOOKUP-driven)
- Classification source: the plan doc from Agent 2 tracks which columns are source vs calculated vs lookup

#### analysis
- Base layer + additional styling:
  - **Section header rows** (identified by text in column A with no formula, followed by a blank row then column headers): bold, 11pt font, light gray background (`#f0f0f0` → RGB 240,240,240), spanning all used columns
  - **Number formatting** (units go in the header, not in cells):
    - Currency columns: `#,##0` (no dollar sign — put "(USD)" in header)
    - Percentage columns: `0.0%`
    - Count columns: `#,##0`

#### summary
- Same recipe as `analysis`
- **Row-level number formatting:** Summary tabs often mix currency, count, and percentage rows in the same columns. When column headers don't indicate the number type (e.g., generic "AT1", "AT2"), classify by **row label** instead:
  - Row labels containing "$", "Amount", "Revenue", "Bookings", "Value", "ARR" → currency `#,##0`
  - Row labels containing "Accuracy", "Rate", "Conv", "%" → percentage `0.0%`
  - Row labels containing "Count", "Deals", "Logos", "#" → count `#,##0`
  - Apply formatting to the data cells in that row (not the label column)
- **Mid-tab section headers:** Summary tabs may have additional section dividers (e.g., "PIPELINE STATUS") below the main data. Scan all rows — any ALL CAPS text row followed by data rows gets section header styling (bold, 11pt, gray bg).

#### deal-list
- **Multi-section handling:** Deal-list tabs often contain multiple sections (e.g., "Deals Moved Out", "Category Drift", "Deals Moved Into"). Each section has its own title row(s), column header row, and data rows. The agent must:
  1. Scan all rows to identify section boundaries (look for ALL CAPS titles or rows with text in col A followed by a blank row then column headers)
  2. Apply section header styling (bold, 11pt, gray bg) to each section's title/subtitle rows
  3. Apply column header styling (dark bg, white text) to each section's header row
  4. Apply number formatting per section based on that section's column headers (columns may differ between sections)
  5. Apply alternating row shading within each section's data rows independently
- **Alternating row shading** per section's data rows:
  - Odd rows: white (`#ffffff`)
  - Even rows: light gray (`#f8f9fa` → RGB 248,249,250)
- Currency, percentage, and count formatting same as `analysis`

#### lookups
- Base layer only
- **Green font** (`#006400`) on all data cells (row 2 onward) — signals "internal reference tab"

#### definitions
- Base layer only
- **Column A bold** (term/metric name column)

---

## batchUpdate Request Patterns

### updateSheetProperties (freeze + hide gridlines)
```json
{
  "updateSheetProperties": {
    "properties": {
      "sheetId": SHEET_ID,
      "gridProperties": {"frozenRowCount": 1, "hideGridlines": true}
    },
    "fields": "gridProperties.frozenRowCount,gridProperties.hideGridlines"
  }
}
```

### repeatCell (header row styling)
```json
{
  "repeatCell": {
    "range": {
      "sheetId": SHEET_ID,
      "startRowIndex": 0,
      "endRowIndex": 1,
      "startColumnIndex": 0,
      "endColumnIndex": COL_COUNT
    },
    "cell": {
      "userEnteredFormat": {
        "backgroundColor": {"red": 0.102, "green": 0.102, "blue": 0.18},
        "textFormat": {
          "bold": true,
          "foregroundColor": {"red": 1, "green": 1, "blue": 1}
        },
        "borders": {
          "bottom": {
            "style": "SOLID",
            "color": {"red": 0.8, "green": 0.8, "blue": 0.8}
          }
        }
      }
    },
    "fields": "userEnteredFormat(backgroundColor,textFormat,borders)"
  }
}
```

### repeatCell (right-align number columns)
```json
{
  "repeatCell": {
    "range": {
      "sheetId": SHEET_ID,
      "startRowIndex": 1,
      "endRowIndex": ROW_COUNT,
      "startColumnIndex": COL_INDEX,
      "endColumnIndex": COL_INDEX + 1
    },
    "cell": {
      "userEnteredFormat": {
        "horizontalAlignment": "RIGHT",
        "numberFormat": {"type": "NUMBER", "pattern": "#,##0"}
      }
    },
    "fields": "userEnteredFormat(horizontalAlignment,numberFormat)"
  }
}
```

### repeatCell (percentage columns)
```json
{
  "repeatCell": {
    "range": {
      "sheetId": SHEET_ID,
      "startRowIndex": 1,
      "endRowIndex": ROW_COUNT,
      "startColumnIndex": COL_INDEX,
      "endColumnIndex": COL_INDEX + 1
    },
    "cell": {
      "userEnteredFormat": {
        "horizontalAlignment": "RIGHT",
        "numberFormat": {"type": "PERCENT", "pattern": "0.0%"}
      }
    },
    "fields": "userEnteredFormat(horizontalAlignment,numberFormat)"
  }
}
```

### repeatCell (chromatic font color — e.g., blue for source columns)
```json
{
  "repeatCell": {
    "range": {
      "sheetId": SHEET_ID,
      "startRowIndex": 1,
      "endRowIndex": ROW_COUNT,
      "startColumnIndex": COL_INDEX,
      "endColumnIndex": COL_INDEX + 1
    },
    "cell": {
      "userEnteredFormat": {
        "textFormat": {
          "foregroundColor": {"red": 0, "green": 0, "blue": 1}
        }
      }
    },
    "fields": "userEnteredFormat(textFormat.foregroundColor)"
  }
}
```

### repeatCell (section header rows — analysis/summary tabs)
```json
{
  "repeatCell": {
    "range": {
      "sheetId": SHEET_ID,
      "startRowIndex": SECTION_ROW_INDEX,
      "endRowIndex": SECTION_ROW_INDEX + 1,
      "startColumnIndex": 0,
      "endColumnIndex": COL_COUNT
    },
    "cell": {
      "userEnteredFormat": {
        "backgroundColor": {"red": 0.941, "green": 0.941, "blue": 0.941},
        "textFormat": {"bold": true, "fontSize": 11}
      }
    },
    "fields": "userEnteredFormat(backgroundColor,textFormat)"
  }
}
```

### repeatCell (alternating row shading — deal-list tabs)
Apply to even-numbered data rows (0-indexed: rows 2, 4, 6, ...):
```json
{
  "repeatCell": {
    "range": {
      "sheetId": SHEET_ID,
      "startRowIndex": EVEN_ROW_INDEX,
      "endRowIndex": EVEN_ROW_INDEX + 1,
      "startColumnIndex": 0,
      "endColumnIndex": COL_COUNT
    },
    "cell": {
      "userEnteredFormat": {
        "backgroundColor": {"red": 0.973, "green": 0.976, "blue": 0.98}
      }
    },
    "fields": "userEnteredFormat(backgroundColor)"
  }
}
```

### updateDimensionProperties (column widths)
```json
{
  "updateDimensionProperties": {
    "properties": {"pixelSize": 120},
    "range": {
      "sheetId": SHEET_ID,
      "dimension": "COLUMNS",
      "startIndex": COL_INDEX,
      "endIndex": COL_INDEX + 1
    },
    "fields": "pixelSize"
  }
}
```
