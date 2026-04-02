# Data Layer Portability — Design Spec

## Problem

Sheet IDs are hardcoded across ~15 files (domain-configs, data-dictionaries, planners, knowledge.md). A new user must hunt through all of them to point the system at their own data. There's no way to swap data sources without editing internal pipeline files, and no onboarding path for someone who finds this project on GitHub.

## Goals

1. **Centralize all data source configuration** into a single file (`sources.md`)
2. **Design an adapter-agnostic config layer** so adding new source types (Salesforce API, SQL, CSV) later is a config change, not a rewrite
3. **Create a setup wizard** that walks external users through first-time configuration interactively
4. **Document expected data schemas** so users can assess compatibility before committing to setup

## Non-Goals

- Building new adapters (Salesforce, SQL, datalake) — only sheets and csv exist today, that's fine
- Changing the formula-first analysis pattern — Sheets remains the analysis medium
- Modifying analysis or review agents — they work on Prepared Data and are already source-agnostic

---

## Design

### 1. Central Source Registry (`sources.md`)

A single file at project root mapping source aliases to connection details.

```markdown
# Source Registry

## Sources

| Alias | Adapter | Connection | Notes |
|-------|---------|-----------|-------|
| DAILY_DATA | sheets | sheetId: `13bmyVaMfh9SR2z0mi7HnQCXLAlkqQcolUeJ7q6ZYlYc` | Salesforce daily refresh. Opportunity + Forecast Accuracy tabs. |
| MARKETING_DATA | sheets | sheetId: `1rkuB6sbsKxkXv_DzlGff0oHKTFEHXMw_SDniErYiX8E` | Campaign Members, Campaign, Leads, Contacts, Master Campaign Frontend Data tabs. |
| CS_DATA | sheets | sheetId: `1MlqIcr9O99-KJu7ngizl2k18FHYdq3JAQhAVMifLPsI` | Opportunity, Account, Subskribe Order Line, User tabs. |

## Column Mappings

Optional overrides when a user's column names differ from the canonical schema.

| Alias | Tab | User Column | Canonical Column |
|-------|-----|-------------|-----------------|
<!-- Empty by default — populated by setup wizard when user's data has different column names -->

## Value Mappings

Optional overrides when categorical values differ (e.g., different CRM stage names).

| Alias | Column | User Value | Canonical Value |
|-------|--------|-----------|----------------|
<!-- Empty by default — populated by setup wizard -->

## Schema Requirements

### DAILY_DATA — Opportunity tab

| Column | Type | Required | Description |
|--------|------|----------|-------------|
| Opportunity Name | text | yes | Unique deal identifier |
| Amount | numeric | yes | Deal value in dollars |
| Close Date | date | yes | Expected or actual close date |
| Stage | text | yes | Pipeline stage (maps to stage categories) |
| Opp Type | text | yes | "New Business" or "Existing Business" |
| Lead Source | text | yes | Deal origin channel |
| Stage 2 Entry Date | date | yes | Date anchor for pipeline metrics |
| Account Name | text | no | Parent account |
| Owner | text | no | Rep assignment |

Full field details: `business-logic/sales/data-dictionary.md`

### MARKETING_DATA — Campaign Members tab

| Column | Type | Required | Description |
|--------|------|----------|-------------|
| Campaign Name | text | yes | Campaign identifier |
| Lead/Contact ID | text | yes | Person identifier |
| Status | text | yes | Member status in campaign |
| Created Date | date | yes | Membership date |

Full field details: `business-logic/marketing/data-dictionary.md`

### CS_DATA — Opportunity tab

| Column | Type | Required | Description |
|--------|------|----------|-------------|
| Account Name | text | yes | Customer account |
| Amount | numeric | yes | Deal value |
| Subskribe Order Delta ARR | numeric | yes | ARR change |
| CSM | text | yes | Customer Success Manager |
| Stage | text | yes | Deal stage |

Full field details: `business-logic/customer-success/data-dictionary.md`
```

**Adapter-agnostic design:** The Alias stays constant regardless of adapter type. Swapping from Sheets to Salesforce API means changing one row's Adapter + Connection fields. Domain-configs don't change.

### 2. Domain-Config Changes

Replace hardcoded Sheet IDs with alias references in two sections per domain-config:

**`## Data Sources` table:**
```markdown
| Source | Connection | Tab | Notes |
|--------|-----------|-----|-------|
| Daily Data (default) | $DAILY_DATA | Opportunity | READ-ONLY. Daily Salesforce refresh. |
```

**`## Ingest Config` table:**
```markdown
| Daily Data | sheets | source: $DAILY_DATA, tab: Opportunity, readOnly: true, numeric_columns: [...] |
```

The `sheets` adapter in the Ingest Config row is redundant with the adapter in sources.md — but kept for readability and as a local override point. If they conflict, sources.md wins.

### 3. Source Resolution Skill (`skills/resolve-source.md`)

A skill executed as Step 0 of every data-prep stage, before ingest.

**Steps:**
1. Read `sources.md`
2. Find the row matching the given alias
3. Extract: adapter type, connection params
4. Check `## Column Mappings` for any overrides for this alias+tab
5. Check `## Value Mappings` for any overrides for this alias+column
6. Return resolved params to the calling agent

**Output contract:**
```
adapter: sheets
connection: { sheetId: "abc123..." }
column_mappings: { "Deal Stage": "Stage", "Deal Value": "Amount" }
value_mappings: { "Stage": { "Qualified": "Stage 2", "Proposal": "Stage 4" } }
```

**Column mapping application:** After ingest writes to Raw Data tab, if column mappings exist, rename headers before data-prep begins. Value mappings are applied during Lookups tab construction (extending existing lookup patterns).

### 4. Setup Wizard (`skills/setup.md`)

An interactive agent skill for first-time configuration.

**Flow:**

1. **Auth check** — verify `gws auth login` works, or confirm CSV-only mode
2. **For each source alias** in the sources.md template:
   - Ask: "Where is your [Opportunity / Campaign / Account] data?"
   - Options: Google Sheet URL, local CSV path, or "skip this domain"
   - If Sheet: extract Sheet ID from URL, verify access with a test read
   - If CSV: verify file exists, read headers
3. **Schema validation** — read headers from each source, compare against Schema Requirements
   - Show: "Found 10/12 required columns. Missing: `Opp Type`, `Lead Source`"
   - Ask: "Do you have these under different names?" → capture column mappings
4. **Value mapping** — for key categorical fields (Stage, Opp Type), sample unique values and compare against expected values
   - Show: "Your Stage values: Qualified, Proposal, Closed Won. Expected: Stage 1-6, 9-11"
   - Ask: "Want me to create a mapping?" → build value mapping overrides
5. **Write `sources.md`** with resolved connections, column mappings, and value mappings
6. **Verify** — test ingest of 10 rows from each source to confirm resolution works

### 5. Data-Prep Agent Changes

Each data-prep instruction file gets a new Step 0 before existing ingest steps:

```markdown
### Step 0: Resolve sources

Read `skills/resolve-source.md` and execute for each source in `## Ingest Config`.
This resolves $ALIAS references to actual connection params and loads any column/value mappings.
```

After ingest (existing Step 1), if column mappings were returned:

```markdown
### Step 1b: Apply column mappings (if any)

If resolve-source returned column_mappings, rename Raw Data headers to canonical names.
Use gws sheets batchUpdate to update header row cells.
```

Value mappings are handled naturally by the existing Lookups tab pattern — the wizard adds override rows.

---

## Files Changed

### New files (3)

| File | Purpose |
|------|---------|
| `sources.md` | Central source registry with schema requirements, column/value mappings |
| `skills/setup.md` | Interactive setup wizard |
| `skills/resolve-source.md` | Source alias resolution skill |

### Modified files (~15)

| File | Change |
|------|--------|
| `agents/pipelines/sales-analytics/domain-config.md` | Replace Sheet IDs with `$DAILY_DATA` in Data Sources + Ingest Config |
| `agents/pipelines/marketing-analytics/domain-config.md` | Replace Sheet IDs with `$MARKETING_DATA` + `$DAILY_DATA` |
| `agents/pipelines/customer-success-analytics/domain-config.md` | Replace Sheet IDs with `$CS_DATA` |
| `agents/pipelines/sales-analytics/2-data-prep.md` | Add Step 0: resolve sources |
| `agents/pipelines/marketing-analytics/2-data-prep.md` | Add Step 0: resolve sources |
| `agents/pipelines/customer-success-analytics/2-data-prep.md` | Add Step 0: resolve sources |
| `agents/pipelines/sales-analytics/1-planner.md` | Remove hardcoded Sheet ID references |
| `agents/pipelines/marketing-analytics/1-planner.md` | Remove hardcoded Sheet ID references |
| `knowledge.md` | Replace Sheet IDs with aliases + reference to sources.md |
| `business-logic/sales/data-dictionary.md` | Replace Sheet ID reference with alias |
| `business-logic/sales/forecast-data-prep-rules.md` | Replace Sheet ID with alias |
| `business-logic/marketing/data-dictionary.md` | Replace Sheet ID with alias |
| `business-logic/models/marketing-workbench/sources.md` | Replace Sheet IDs with aliases |
| `business-logic/models/ops-forecast/spec.md` | Replace Sheet ID with alias |
| `agents/meta/domain-builder/domain-config-schema.md` | Document alias resolution pattern, update Ingest Config schema |
| `CLAUDE.md` | Reference sources.md in Cold Start, mention setup wizard |

### Unchanged

Formula rules, analysis agents, review agents, metrics files, sanity checks, plan-doc format, inspection protocol, ingest adapter skills (sheets.md, csv.md). The entire analysis layer is untouched.

---

## Verification

1. **Alias resolution:** Run a sales-analytics pipeline end-to-end — confirm data-prep resolves `$DAILY_DATA` from sources.md and ingests correctly
2. **Setup wizard:** Run `skills/setup.md` from scratch with a test Google Sheet URL — confirm it produces a valid sources.md
3. **Schema validation:** Point setup wizard at a CSV with 2 missing columns — confirm it detects gaps and offers mapping
4. **No regressions:** Existing pipelines produce identical output (same row counts, same formulas) after the change
5. **External user test:** Clone the repo fresh, follow setup wizard with a sample CSV — confirm it gets to a working state
