# Domain Config Schema

The `domain-config.md` file is the per-pipeline constant store. Every registered pipeline has one at `agents/{pipeline}/domain-config.md`. It is read by the CoS at dispatch time and referenced by all stage instruction files.

## Existing Sections

These sections exist in all current domain-configs.

### `## Data Sources`

| Column | Required | Description |
|--------|----------|-------------|
| Source | Yes | Human-readable source name |
| Connection | Yes | Source alias (e.g., `$DAILY_DATA` — resolved via `sources.md`), Google Sheet ID, file path, or other connection reference |
| Tab / Table | Yes | Specific tab, table, or query target |
| Notes | No | Read-only flag, refresh schedule, etc. |

Also includes plan doc path (e.g., `.context/{pipeline}-plan.md`).

### `## Metric Catalog`

| Column | Required | Description |
|--------|----------|-------------|
| Category | Yes | Metric grouping (e.g., Volume, Conversion, Velocity, Quality) |
| Metrics | Yes | Comma-separated metric names in this category |

Reference to full definitions file: `business-logic/{domain}/metrics.md`.

### `## Dimensions`

Free-text list of available analysis dimensions. Must include:
- Time dimension with granularity options (week/month/quarter/year)
- Date anchor column (which date field drives time-based analysis)
- At least one categorical dimension (Segment, Team, Region, etc.)

### `## Lookups Sections`

| Column | Required | Description |
|--------|----------|-------------|
| # | Yes | Section number (determines layout order) |
| Range | Yes | Cell range in Lookups tab (e.g., `A1:C10`) |
| Type | Yes | What this mapping does (e.g., Stage Mapping, Use Case Mapping) |
| Source | Yes | Where the mapping data comes from (data-dictionary field or manual) |

### `## Sanity Checks`

| Column | Required | Description |
|--------|----------|-------------|
| Check | Yes | Human-readable check name |
| Rule | Yes | What to verify (e.g., "Raw Data rows = Prepared Data rows") |
| Severity | Yes | `hard-fail`, `warning`, or `info` per severity taxonomy |

Universal checks (always include):
- Row count preserved (hard-fail)
- No #REF! or #VALUE! errors in Prepared Data (hard-fail)

### `## Intentional Deviations`

Free-text documentation of any places where this pipeline intentionally deviates from shared patterns in `codespecs/`. If none, state "None — follows all shared patterns."

---

## New Sections (Added in Phase 1)

### `## Stages`

Ordered stage sequence for this pipeline. The CoS reads this to determine what to dispatch and in what order.

| Column | Required | Description |
|--------|----------|-------------|
| Order | Yes | Numeric execution order (1, 2, 3, ...) |
| Stage | Yes | Stage name (e.g., `planner`, `data-prep`, `analysis`, `review`) |
| Instruction File | Yes | Filename within `agents/{pipeline}/` (e.g., `2-data-prep.md`) |
| Dispatch File | Yes | Entry in `.claude/agents/` (e.g., `sales-data-prep`), or `inline` for planner |
| Skip Conditions | Yes | Complexity tier(s) that skip this stage (e.g., `Express`), or `never` |

**Example (standard 4-stage):**

| Order | Stage | Instruction File | Dispatch File | Skip Conditions |
|-------|-------|-----------------|---------------|-----------------|
| 1 | planner | 1-planner.md | inline | never |
| 2 | data-prep | 2-data-prep.md | sales-data-prep | never |
| 3 | analysis | 3-analysis.md | sales-analysis | never |
| 4 | review | 4-review.md | sales-review | Express |

### `## Context Inlining`

Files to include in dispatch prompts. Eliminates redundant file reads by subagents.

| Column | Required | Description |
|--------|----------|-------------|
| File | Yes | Path from repo root (e.g., `business-logic/_shared/formula-rules.md`) |
| Scope | Yes | Which stages receive this file: `all stages` or specific stage names (e.g., `data-prep`, `analysis, review`) |

**Example:**

| File | Scope |
|------|-------|
| `business-logic/_shared/formula-rules.md` | all stages |
| `agents/pipelines/sales-analytics/domain-config.md` | all stages |
| `business-logic/sales/data-prep-rules.md` | data-prep |
| `business-logic/sales/metrics.md` | analysis, review |

### `## Ingest Config`

Data source adapters and their parameters. Read by data-prep stages to determine how to ingest data.

| Column | Required | Description |
|--------|----------|-------------|
| Source Name | Yes | Human-readable name matching a `## Data Sources` entry |
| Adapter | Yes | Adapter type: `sheets`, `csv`, `database`, `api` (see `skills/ingest/README.md`) |
| Params | Yes | Adapter-specific parameters (see adapter skill files for required params) |

**Source alias resolution:** Params may reference a source alias from `sources.md` using `source: $ALIAS` syntax instead of hardcoding connection details (e.g., `sheetId`). Data-prep agents resolve aliases via `skills/resolve-source.md` as Step 0 before ingest. This keeps connection details centralized in `sources.md`.

**Optional field — `numeric_columns`:** List of column names that must be rewritten with `USER_ENTERED` after `RAW` ingest. When specified, this list overrides the adapter's heuristic-based numeric detection (which matches names like Amount, ARR, Count, Score, Days). Use this when your domain has numeric columns with non-standard names that the heuristic would miss.

Format: `numeric_columns: [Column A, Column B, Column C]` appended to the Params field.

**Example:**

| Source Name | Adapter | Params |
|-------------|---------|--------|
| Daily Data | sheets | source: $DAILY_DATA, tab: Opportunity, readOnly: true, numeric_columns: [Amount, Amount Weighted, Order Delta ARR, Days in Stage] |
| QBOR CSV | csv | path: `Files/QBOR.csv`, encoding: UTF-8 |

**Special case — model-specific:** Modeling pipelines may specify "Model-specific" to indicate that source config comes from the model spec's `## Source` section rather than this table.

---

## Extension Point

### `## Inspection Overrides` (Optional)

Domain-specific inspection checks run IN ADDITION to the universal checklists in `codespecs/inspection-protocol.md`.

| Column | Required | Description |
|--------|----------|-------------|
| Stage | Yes | Which stage this check runs after (e.g., `data-prep`, `analysis`) |
| Check | Yes | What to verify |
| Severity | Yes | `hard-fail`, `warning`, or `info` |

**Example:**

| Stage | Check | Severity |
|-------|-------|----------|
| data-prep | Verify model spec positions JSON is present | hard-fail |
| analysis | Summary tab has at least 3 metric rows | warning |

---

## Section Order Convention

Sections should appear in this order in domain-config files:

1. Data Sources
2. Metric Catalog
3. Dimensions
4. Lookups Sections
5. Sanity Checks
6. Intentional Deviations
7. Stages
8. Context Inlining
9. Ingest Config
10. Inspection Overrides (if applicable)
