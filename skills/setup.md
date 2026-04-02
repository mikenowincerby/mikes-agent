# Skill: Setup Wizard

## What It Does

Interactive first-time configuration. Walks a new user through connecting their data sources and writes a fully populated `sources.md`. Handles Google Sheets and CSV adapters, validates schema compatibility, and records column/value mappings for data with non-standard naming conventions.

## When To Use

- First time setting up the project (no `sources.md` exists or it contains only the empty template)
- Re-configuring data sources (user wants to point at different sheets or switch adapters)

## Prerequisites

| Prerequisite | Required | Notes |
|-------------|----------|-------|
| Google Workspace auth | Only if using Sheets | `gws auth login -s sheets,drive` — verified in Step 2 |

## Inputs

| Input | Required | Description |
|-------|----------|-------------|
| User presence | Yes | This is an interactive skill — every step prompts the user |

## How To Invoke

### Step 1: Check Existing Configuration

Read `sources.md`. Inspect the Sources table for populated Connection values.

- **If connections are already populated:** Present current config to the user and ask: "You already have sources configured. Do you want to reconfigure from scratch or keep existing?" If keep, stop here.
- **If empty or file missing:** Proceed to Step 2.

### Step 2: Auth Check

Ask the user: **"Will you be using Google Sheets as your data source?"**

**If yes:**

```bash
gws drive files list
```

- If the command succeeds: auth is working, proceed.
- If it fails: guide the user through auth setup:
  1. Run `gws auth login -s sheets,drive`
  2. Follow the browser flow
  3. Re-test with `gws drive files list`
  4. If still failing, refer user to `guides/gws-quickstart.md` and hard-fail.

**If no (CSV-only):** Note that Sheets adapter features (live formulas, collaborative editing) won't be available. Proceed with CSV configuration.

### Step 3: Configure Each Source Alias

For each alias in the Sources table (`DAILY_DATA`, `MARKETING_DATA`, `CS_DATA`):

1. Present the alias name and its description from the Notes column
2. Ask: **"Where is your [description] data?"**
   - **Google Sheet URL** → extract the Sheet ID from the URL (the long alphanumeric string between `/d/` and `/edit`), set adapter to `google-sheets`
   - **Local CSV/Excel file path** → set adapter to `csv`
   - **"Skip"** → leave connection blank, note as unconfigured
3. **If Google Sheet:** verify access by reading the first row of the first expected tab:
   ```bash
   gws sheets spreadsheets values get --params '{"spreadsheetId":"[id]","range":"[first tab]!A1:A5"}'
   ```
   - If 403 or error: "Can't access this sheet. Make sure it's shared with your Google account." Offer to retry or skip.
4. **If CSV:** verify file exists and is readable:
   ```bash
   head -1 [path]
   ```
   - If file not found: "File not found at that path. Please check and try again." Offer to retry or skip.

### Step 4: Schema Validation

For each configured source, validate headers against Schema Requirements in `sources.md`.

1. Read the headers from the source:
   - Sheets: `gws sheets spreadsheets values get --params '{"spreadsheetId":"[id]","range":"[tab]!1:1"}'`
   - CSV: `head -1 [path]`
2. For each relevant tab listed under "Tabs by Source" in `sources.md`, compare headers against the Schema Requirements table for that alias + tab
3. Report to the user:
   - **"Found X/Y required columns"**
   - List any missing required columns
4. **If match rate < 50%:** warn the user — "Less than half the required columns were found. This may require significant mapping work. Want to proceed?"
5. For each missing column, ask:
   - **"Do you have this data under a different column name? If so, what is it called?"**
   - If yes: record the mapping (User Column -> Canonical Column) for the Column Mappings table
   - If no: warn that features dependent on this column won't work

### Step 5: Value Mapping (Key Categorical Fields)

For each configured source with categorical fields that have expected values (e.g., Stage, Opportunity Type, Primary Use Case):

1. Read unique values from key columns:
   - **DAILY_DATA / Opportunity:** Stage, Opportunity Type, Primary Use Case
   - **CS_DATA / Opportunity:** Stage, Opportunity Type
   - **MARKETING_DATA / Campaign Members:** Status
2. Compare against canonical values in the data dictionaries referenced by Schema Requirements
3. **If mismatches detected:**
   - Show the user their values vs expected values side by side
   - Ask: **"Want me to create mappings between your values and the expected values?"**
   - If yes: walk through each mismatched value, ask what it should map to
   - Record as value mappings for the Value Mappings table
4. **If values match:** confirm and move on

### Step 6: Write sources.md

1. Update the Sources table with adapter + connection for each configured alias
2. Write any column mappings to the Column Mappings table
3. Write any value mappings to the Value Mappings table
4. **Preserve the Schema Requirements section unchanged** — never modify it
5. Read back the file to confirm it was written correctly

### Step 7: Verification

For each configured source, run a lightweight test ingest:

1. Read 5-10 rows of data through the configured connection
   ```bash
   # Sheets example
   gws sheets spreadsheets values get --params '{"spreadsheetId":"[id]","range":"[tab]!A1:Z10"}'
   ```
2. Verify data comes through with expected shape (correct number of columns, non-empty rows)
3. If column mappings exist, verify the mapped column names are present in the source
4. Report per source: **Pass** or **Fail** with details

### Step 8: Next Steps

Tell the user:

- "Configuration complete. Your data sources are stored in `sources.md`."
- "To reconfigure later, run this setup wizard again."
- "To add a new data source type, create an adapter skill at `skills/ingest/{type}.md`."
- List which pipelines are now usable based on configured sources (e.g., "DAILY_DATA configured — Sales Analytics pipeline is ready").

## Outputs

| Field | Value |
|-------|-------|
| Sources configured | Count of aliases with valid connections |
| Sources skipped | Count of aliases left unconfigured |
| Column mappings | Count of column name overrides written |
| Value mappings | Count of categorical value overrides written |
| Verification | Pass/fail per source |

## Error Handling

| Error | Severity | Action |
|-------|----------|--------|
| `gws auth` fails | hard-fail | Guide user through auth setup per `guides/gws-quickstart.md` |
| Sheet not accessible (403) | warning | Ask user to check sharing permissions, offer to skip |
| CSV file not found | warning | Ask user to verify path, offer to skip |
| Schema validation < 50% match | warning | Warn that significant mapping work needed, ask if they want to proceed |
| Test ingest fails | warning | Show error, ask user to fix source data, offer to retry or skip |

## Key Rules

- **This is interactive.** Never assume answers — ask the user at every decision point.
- **Never modify Schema Requirements.** Those are the canonical definitions owned by domain configs.
- **Validate before writing.** Every connection is tested before it goes into `sources.md`.
- **Column mappings preserve pipeline logic.** The mapping layer means pipeline formulas reference canonical names — the adapter handles translation.
- **One source at a time.** Complete configuration + validation for each alias before moving to the next.
