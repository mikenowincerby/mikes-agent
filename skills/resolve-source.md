# Skill: Resolve Source Alias

Resolves `$ALIAS` references in domain-config `## Ingest Config` tables to actual adapter params by reading `sources.md`.

## When To Use

Before any ingest step. Data-prep agents call this as Step 0 before following adapter skills (e.g., `skills/ingest/sheets.md`).

## Params (from the calling agent)

| Param | Required | Description |
|-------|----------|-------------|
| `alias` | Yes | The source alias to resolve (e.g., `DAILY_DATA`) |
| `tab` | No | Specific tab name if the alias has multiple tabs |

## Steps

### Step 1: Read source registry

Read `sources.md` → `## Sources` table. Find the row where Alias matches the requested alias.

If `sources.md` does not exist, hard-fail — project not configured.

If no row matches, hard-fail — alias not registered.

### Step 2: Extract connection params

From the matching row, extract:

- **Adapter type** (e.g., `sheets`, `csv`) — determines which `skills/ingest/{adapter}.md` to follow
- **Connection params** (e.g., `sheetId: abc123...`) — passed directly to the adapter skill

If `tab` param was provided, use it. Otherwise use the default tab from the Sources table row.

### Step 3: Check column mappings

Read `sources.md` → `## Column Mappings` table. Find any rows where Alias matches AND (Tab matches the resolved tab OR Tab is blank for alias-wide mappings).

Collect as a dict of `{User Column → Canonical Column}` pairs. Empty dict if no mappings found.

### Step 4: Check value mappings

Read `sources.md` → `## Value Mappings` table. Find any rows where Alias matches.

Collect as a dict of `{Column: {User Value → Canonical Value}}` pairs. Empty dict if no mappings found.

### Step 5: Return resolved params

Return to the calling agent:

```
adapter: [adapter type]
connection: { [connection params] }
column_mappings: { "User Col": "Canonical Col", ... }
value_mappings: { "Column": { "User Val": "Canonical Val" } }
```

The calling agent then dispatches the appropriate adapter skill at `skills/ingest/{adapter}.md` with the resolved connection params.

## Post-Ingest: Apply Column Mappings

If `column_mappings` is non-empty, after the ingest adapter writes Raw Data:

1. Read the header row of the Raw Data tab
2. For each mapping, find the User Column header cell and rename it to the Canonical Column name
3. Write updated headers with `batchUpdate`:

```bash
gws sheets spreadsheets values update --params '{
  "spreadsheetId": "[targetSheetId]",
  "range": "[rawDataTab]!A1:[lastCol]1",
  "valueInputOption": "RAW"
}' --json '{"values": [[...updated headers...]]}'
```

This ensures downstream formulas reference canonical column names regardless of source naming.

## Post-Ingest: Apply Value Mappings

Value mappings are applied via the Lookups tab pattern — the setup wizard adds override rows to the appropriate Lookups section. No extra step needed here; the existing Lookups + VLOOKUP formula chain handles value normalization at prep time.

## Output

| Field | Value |
|-------|-------|
| adapter | Adapter type from sources.md (e.g., `sheets`, `csv`) |
| connection | Connection params dict (passed to adapter skill) |
| column_mappings | Dict of user → canonical column name mappings (empty if none) |
| value_mappings | Dict of column → {user_val → canonical_val} mappings (empty if none) |

## Error Handling

| Error | Severity | Action |
|-------|----------|--------|
| `sources.md` does not exist | hard-fail | Project not configured — run `skills/setup.md` |
| Alias not found in sources.md | hard-fail | Source not registered — run setup wizard to add it |
| Adapter type not recognized | hard-fail | No adapter skill at `skills/ingest/{adapter}.md` |
| Tab not found for alias | hard-fail | Tab name does not match any entry — verify source config |
