# Skill: Create Analysis Sheet

## What It Does

Creates a new Google Sheet for analysis, copies raw data from a source sheet, and sets up the standard tab structure. This is the starting point for every analysis.

## When To Use

Sheet creation + tab setup for any pipeline. Called by data-prep stages before ingest. Data reading and Raw Data population are handled by `skills/ingest/{adapter}.md` — this skill creates the empty sheet structure.

## Inputs

| Input | Required | Description |
|-------|----------|-------------|
| `sourceSheetId` | Yes | Google Sheet ID to pull raw data from |
| `sourceRange` | Yes | Range to copy (e.g., "Sheet1!A1:AO1000") |
| `analysisName` | Yes | Human-readable name (e.g., "New Business Bookings Q1 FY2026") |
| `analysisTabs` | No | List of analysis tab names (1-3). Default: ["Analysis"] |

## How To Invoke

### Step 1: Create the new spreadsheet

```bash
gws sheets spreadsheets create --json '{
  "properties": {"title": "[analysisName] — [YYYY-MM-DD]"},
  "sheets": [
    {"properties": {"title": "Summary", "index": 0}},
    {"properties": {"title": "Raw Data", "index": 1}},
    {"properties": {"title": "Prepared Data", "index": 2}},
    {"properties": {"title": "Analysis", "index": 3}},
    {"properties": {"title": "Lookups", "index": 4}},
    {"properties": {"title": "Definitions", "index": 5}}
  ]
}'
```

If multiple analysis tabs are requested, add them at index 3, 4, ... and shift Lookups and Definitions accordingly.

### Steps 2-3: Ingest (moved to adapters)

Data reading and Raw Data population are now handled by `skills/ingest/{adapter}.md`. See `skills/ingest/README.md` for the adapter contract.

### Step 4: Freeze header row

```bash
gws sheets spreadsheets batchUpdate --params '{
  "spreadsheetId": "[newSheetId]"
}' --json '{
  "requests": [
    {
      "updateSheetProperties": {
        "properties": {
          "sheetId": [rawDataSheetId],
          "gridProperties": {"frozenRowCount": 1}
        },
        "fields": "gridProperties.frozenRowCount"
      }
    }
  ]
}'
```

**Note:** You need the `sheetId` (numeric ID) of the Raw Data tab, which is returned in the create response.

## Outputs

| Output | Description |
|--------|-------------|
| New spreadsheet ID | The ID of the created analysis sheet |
| New spreadsheet URL | `https://docs.google.com/spreadsheets/d/[id]` |
| Tab structure | Confirmation of tabs created |
| Row count | Number of rows copied to Raw Data |

## Error Handling

| Error | Action |
|-------|--------|
| 403 on source sheet | Source not shared with authenticated account. Ask user to share it. |
| Empty source range | No data found. Confirm the range with user. |
| Payload too large | Reduce batch size and retry. |

## Known gws Quirks

- `autoResizeDimensions` via batchUpdate returns httpError — skip auto-resize, use manual column widths if needed
- Tab names with spaces work in values get/update without quoting (gws handles it)
