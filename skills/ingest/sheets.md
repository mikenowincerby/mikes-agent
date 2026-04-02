# Ingest Adapter: Google Sheets

Reads data from a Google Sheet tab and writes to the Raw Data tab of the analysis sheet.

## Params (from domain-config `## Ingest Config`)

| Param | Required | Description |
|-------|----------|-------------|
| `sheetId` | Yes | Source Google Sheet ID |
| `tab` | Yes | Source tab name |
| `range` | No | Specific range (default: entire tab) |
| `readOnly` | No | If true, confirms source won't be modified (documentation only) |
| `rowOffset` | No | Skip N rows from top (e.g., banner rows). Default: 0 |
| `numeric_columns` | No | Explicit list of column names to rewrite as numeric. Overrides heuristic detection. |

## Steps

### Step 1: Read source data

```bash
gws sheets spreadsheets values get --params '{
  "spreadsheetId": "[sheetId]",
  "range": "[tab]![range or A:ZZ]"
}'
```

Strip the `stderr` "Using keyring backend" line before parsing JSON output.

If `rowOffset` is specified, discard the first N rows from the response.

### Step 2: Expand target grid if needed

If source has >1000 rows or >26 columns, expand the Raw Data tab grid:

```bash
gws sheets spreadsheets batchUpdate --params '{
  "spreadsheetId": "[targetSheetId]"
}' --json '{
  "requests": [{
    "updateSheetProperties": {
      "properties": {
        "sheetId": [rawDataSheetId],
        "gridProperties": {"rowCount": [sourceRows + 100], "columnCount": [sourceCols + 5]}
      },
      "fields": "gridProperties.rowCount,gridProperties.columnCount"
    }
  }]
}'
```

### Step 3: Write to Raw Data tab

```bash
gws sheets spreadsheets values update --params '{
  "spreadsheetId": "[targetSheetId]",
  "range": "[targetTab]!A1",
  "valueInputOption": "RAW"
}' --json '{"values": [...]}'
```

**Large datasets (1000+ rows, 40+ cols):** Write in batches of 500 rows to stay within payload limits. Track offset and continue until all rows are written.

### Step 4: Rewrite numeric columns with USER_ENTERED

RAW ingest stores numbers as text, breaking SUMIFS/AVERAGEIFS. Identify numeric columns using this priority:
1. **Explicit list from domain-config:** If `## Ingest Config` includes a `numeric_columns` field for this source, use that list.
2. **Heuristic fallback:** If no explicit list, detect by column name pattern (Amount, ARR, Count, Score, Days, etc.).

Rewrite identified numeric columns:

```bash
gws sheets spreadsheets values update --params '{
  "spreadsheetId": "[targetSheetId]",
  "range": "[targetTab]![col][startRow]:[col][endRow]",
  "valueInputOption": "USER_ENTERED"
}' --json '{"values": [[val1], [val2], ...]}'
```

Batch in 300-row chunks per column. This is the critical step that makes formula-based analysis work.

### Step 5: Freeze header row

```bash
gws sheets spreadsheets batchUpdate --params '{
  "spreadsheetId": "[targetSheetId]"
}' --json '{
  "requests": [{
    "updateSheetProperties": {
      "properties": {
        "sheetId": [rawDataSheetId],
        "gridProperties": {"frozenRowCount": 1}
      },
      "fields": "gridProperties.frozenRowCount"
    }
  }]
}'
```

## Output

| Field | Value |
|-------|-------|
| Row count | Number of data rows written (excluding header) |
| Column headers | Array of header strings from row 1 |
| Write mode | RAW (with numeric columns rewritten as USER_ENTERED) |
| Numeric columns rewritten | List of column letters rewritten |

## Error Handling

| Error | Severity | Action |
|-------|----------|--------|
| 403 on source sheet | hard-fail | Source not shared with authenticated account |
| Empty source range | hard-fail | No data found — confirm range with user |
| Payload too large | warning | Reduce batch size to 200 rows and retry |
| Numeric column detection misses a column | info | Formulas return 0 — add column to rewrite list |
