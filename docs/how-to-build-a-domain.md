# How to Build a Domain

This guide walks you through creating a new analytics pipeline using the domain builder. By the end, you'll have a fully functional pipeline that can answer questions about your domain.

## Prerequisites

### 1. Tools and authentication

Run `./bootstrap.sh` to install the `gws` CLI and authenticate with Google Workspace. You need:
- Google Sheets read access to your data source
- Google Drive access for creating output sheets
- Claude Code installed and configured

### 2. Google resource IDs

Copy `config/resources.example.yaml` to `config/resources.yaml` and fill in your Google resource IDs. The example file lists every ID the system references — Sheet IDs for data sources, Drive folder IDs for output, etc.

If you're adding a new domain (not modifying existing ones), you only need the IDs for YOUR data source. The existing pipeline IDs are for the reference implementations.

### 3. Source data

Your data must be accessible as either:
- **Google Sheets** — the sheet must be readable by your authenticated account
- **CSV/Excel file** — the file must be at a local path accessible to the agent

Other data sources (databases, APIs) require a custom ingest adapter. See `skills/ingest/README.md` for the adapter contract.

## Using the domain builder

The fastest way to build a new pipeline is the domain builder — an interactive agent that collects your domain info via Q&A and scaffolds all pipeline files automatically.

### Start the conversation

Tell the agent:

> "Create a new pipeline for [your domain]"

or

> "Scaffold a new analytics domain for [your domain]"

The domain builder will guide you through 4 phases:

### Phase 1: Understand your domain

The builder asks about:
- **Pipeline identity** — kebab-case name, display name, trigger keywords
- **Data source** — Google Sheet ID or CSV path, tab name
- **Metrics** — what you want to measure, grouped by category
- **Dimensions** — how you slice the data (time, segments, teams, etc.)

**Data-first approach:** If your data source is accessible, the builder reads it first and uses column names to inform its questions. Instead of "what metrics do you track?" it asks "I see columns X, Y, Z — which are the metrics you want to analyze?"

### Phase 2: Design decisions

The builder asks about:
- **Lookups mappings** — which fields need lookup tables (stage mapping, category mapping, etc.)
- **Calculated columns** — helper columns for Prepared Data (fiscal quarter from date, flags, categories)
- **Sanity checks** — what to verify (row count, value ranges, cross-field consistency)

For each design decision, the builder presents 2-3 options with trade-offs and a recommendation.

### Phase 3: Review and approve

Before writing any files, the builder presents a complete summary:

```
Pipeline: finance-analytics
Display Name: Finance Analytics
Trigger Keywords: budget, expense, revenue forecast, P&L, financial
Data Source: Google Sheets (sheet ID: abc123, tab: Monthly Actuals)
Metrics: 12 across 4 categories (Revenue, Expense, Margin, Forecast)
Dimensions: Time (month/quarter/year), Department, Cost Center, GL Code
Lookups: 3 mapping tables
Sanity Checks: 8 (4 hard-fail, 3 warning, 1 info)
Stages: 4 (planner → data-prep → analysis → review)
```

**Hard gate:** No files are written until you approve this summary.

### Phase 4: Scaffold

The builder creates all required files:

```
agents/pipelines/finance-analytics/
  ├── domain-config.md      — pipeline constants and configuration
  ├── 1-planner.md          — scoping and planning instructions
  ├── 2-data-prep.md        — data ingestion and preparation
  ├── 3-analysis.md         — formula building and analysis
  └── 4-review.md           — validation and sanity checks

business-logic/finance/
  ├── metrics.md            — metric definitions, formulas, sanity checks
  ├── data-dictionary.md    — field mappings and helper columns
  └── data-prep-rules.md    — transformation rules

.claude/agents/
  ├── finance-data-prep.md  — dispatch file for data-prep stage
  ├── finance-analysis.md   — dispatch file for analysis stage
  └── finance-review.md     — dispatch file for review stage
```

It also updates `business-logic/pipeline-registry.md` with your new pipeline.

## What gets created

### Domain config (`agents/{pipeline}/domain-config.md`)

The central configuration file. Contains:

| Section | What it defines |
|---------|----------------|
| Data Sources | Sheet IDs, tabs, read-only flags |
| Metric Catalog | Metric categories and names (references metrics.md for full definitions) |
| Dimensions | Time + categorical dimensions |
| Lookups Sections | Mapping tables for the Lookups tab |
| Sanity Checks | Validation rules with severity levels |
| Stages | Stage sequence, dispatch files, skip conditions |
| Context Inlining | Which files each stage needs in its prompt |
| Ingest Config | Adapter type and parameters per data source |

Full schema: `agents/meta/domain-builder/domain-config-schema.md`

### Stage instruction files

Four files following the standard pipeline pattern:

| File | Stage | What it does |
|------|-------|-------------|
| `1-planner.md` | Plan | Classifies complexity, scopes the analysis, builds the plan doc |
| `2-data-prep.md` | Data Prep | Ingests data, creates Lookups, builds Prepared Data with helper columns |
| `3-analysis.md` | Analysis | Writes formulas (SUMIFS, COUNTIFS), builds Summary + deal lists |
| `4-review.md` | Review | Verifies formulas, runs sanity checks, writes Definitions tab |

Each file references shared patterns from `codespecs/` via `<!-- SHARED: {block-name} -->` markers. This keeps domain-specific logic separate from framework patterns.

### Business logic files

| File | Purpose |
|------|---------|
| `metrics.md` | Metric definitions with formulas, dimensions, and sanity check rules |
| `data-dictionary.md` | Source field mappings, helper column derivations, type information |
| `data-prep-rules.md` | Standardization rules, calculated columns, quality checks |

These files encode your domain's institutional knowledge — the definitions, edge cases, and rules that a human analyst would know.

### Dispatch files

Located at `.claude/agents/{pipeline}-{stage}.md`. These are Claude Code-specific files that wire the orchestration loop to your stage instructions. They define:

- Which tools the subagent can use
- What context it receives (plan doc, inlined files)
- The output contract (RESULT template with status, outputs, issues)

## After scaffolding

### Test your pipeline

Ask a question that matches your trigger keywords:

> "How did [metric] look last [time period]?"

The orchestrator will route to your pipeline, run through all 4 stages, and deliver a Google Sheet.

### Iterate on business logic

The most valuable files to refine over time:

1. **`metrics.md`** — add more metrics, refine formulas, add sanity checks
2. **`data-dictionary.md`** — add helper columns as you discover new analysis patterns
3. **`data-prep-rules.md`** — add quality checks for data issues you encounter

### Validate your pipeline

The domain builder has a validate mode that checks your pipeline against the schema:

> "Validate the finance-analytics pipeline"

This runs 7 checks: file existence, required sections, SHARED block markers, stage consistency, ingest config, sanity check coverage, and naming conventions.

## Manual creation (without domain builder)

If you prefer to create files manually:

1. Copy an existing pipeline directory (e.g., `agents/pipelines/sales-analytics/`) as a starting point
2. Update `domain-config.md` with your data sources, metrics, dimensions, etc.
3. Create business logic files at `business-logic/{your-domain}/`
4. Create dispatch files at `.claude/agents/{pipeline}-{stage}.md`
5. Add your pipeline to `business-logic/pipeline-registry.md`
6. Run the domain builder in validate mode to check your work

Reference: `agents/meta/domain-builder/domain-config-schema.md` for required sections and `codespecs/agent-authoring.md` for dispatch file structure.

## Tips

- **Start simple.** Begin with 3-5 metrics and 2-3 dimensions. You can always add more.
- **Let the data inform design.** If the builder can access your data source, it will read columns and suggest metrics/dimensions. This is faster than describing your data from memory.
- **Check the reference pipelines.** Sales Analytics is the most mature — study its `domain-config.md` and `metrics.md` for patterns to follow.
- **Encode edge cases early.** The "institutional knowledge" that makes analyses trustworthy lives in `metrics.md` (sanity checks) and `data-prep-rules.md` (quality checks). Add these as you discover them.
- **Formula-first always.** Every output cell must have a formula. If something can't be expressed as a sheet formula, use `compute-and-push` (Python computation pushed as static values with explicit labeling).
