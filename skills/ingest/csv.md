# Ingest Adapter: CSV / Excel

Reads data from a local CSV/Excel file or a Google Drive file, and writes to the Raw Data tab of the analysis sheet.

## Params (from domain-config `## Ingest Config`)

| Param | Required | Description |
|-------|----------|-------------|
| `path` | Yes (local) | Local file path (CSV, TSV, XLSX) |
| `driveFileId` | Yes (Drive) | Google Drive file ID (alternative to path) |
| `sheet` | No | Sheet name for Excel files (default: first sheet) |
| `delimiter` | No | For CSV/TSV (default: auto-detect from extension) |
| `encoding` | No | File encoding (default: UTF-8) |
| `headerRow` | No | Row number containing headers (default: 1) |
| `skipRows` | No | Rows to skip from top before header (default: 0) |
| `numeric_columns` | No | Explicit list of column names to rewrite as numeric. Overrides heuristic detection. |

Exactly one of `path` or `driveFileId` is required.

## Steps

### Step 1: Read source data

**Local file:**
```bash
# CSV — read with Python (handles encoding, delimiters, quoting)
python3 -c "
import csv, json, sys
with open('[path]', encoding='[encoding]') as f:
    reader = csv.reader(f, delimiter='[delimiter]')
    rows = [row for row in reader]
    rows = rows[[skipRows]:]
print(json.dumps(rows))
" > /tmp/ingest-data.json
```

**Excel (.xlsx):**
```bash
python3 -c "
import json
try:
    import openpyxl
except ImportError:
    import subprocess; subprocess.check_call(['pip3', 'install', 'openpyxl'])
    import openpyxl
wb = openpyxl.load_workbook('[path]', read_only=True, data_only=True)
ws = wb['[sheet]'] if '[sheet]' else wb.active
rows = [[str(cell) if cell is not None else '' for cell in row] for row in ws.iter_rows(values_only=True)]
rows = rows[[skipRows]:]
print(json.dumps(rows))
" > /tmp/ingest-data.json
```

**Drive file:**
```bash
# Download from Drive first
gws drive files get --params '{"fileId": "[driveFileId]"}' --download /tmp/ingest-source.csv
# Then read as local file (same as above)
```

### Step 2: Validate data shape

```bash
python3 -c "
import json
with open('/tmp/ingest-data.json') as f:
    rows = json.load(f)
headers = rows[0]
data_rows = rows[1:]
print(f'Headers: {len(headers)} columns')
print(f'Data rows: {len(data_rows)}')
print(f'First 5 headers: {headers[:5]}')
if len(data_rows) == 0:
    print('ERROR: No data rows found')
    exit(1)
"
```

### Step 3: Write to Raw Data tab

Same as Sheets adapter Step 3 — write with `valueInputOption: RAW`, batch in 500-row chunks.

### Step 4: Rewrite numeric columns with USER_ENTERED

Same as Sheets adapter Step 4 — detect numeric columns (explicit list from domain-config first, then heuristic fallback) and rewrite with `USER_ENTERED`.

### Step 5: Freeze header row

Same as Sheets adapter Step 5.

## Output

Same output contract as Sheets adapter (row count, column headers, write mode, numeric columns rewritten).

## Error Handling

| Error | Severity | Action |
|-------|----------|--------|
| File not found | hard-fail | Verify path / Drive file ID |
| Encoding error | hard-fail | Try common encodings (UTF-8, Latin-1, CP1252) |
| Empty file | hard-fail | No data — confirm file with user |
| openpyxl not installed | info | Auto-install via pip3 |
| Drive export fails | hard-fail | File not shared or wrong format |
