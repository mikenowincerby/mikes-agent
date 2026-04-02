# Naming Conventions

Consistent naming across files, tabs, columns, and identifiers.

---

## Pipeline Directories

| Type | Pattern | Examples |
|------|---------|----------|
| Analysis pipelines | `agents/{domain}-analytics/` | `sales-analytics/`, `marketing-analytics/` |
| Non-analysis pipelines | `agents/{domain}/` | `modeling/` |

The `-analytics` suffix signals that the pipeline produces a Google Sheets deliverable with standard tabs (Summary, Analysis, etc.). Non-analysis pipelines (modeling, scoring) have spec-driven tab structures.

## File Naming

| File Type | Pattern | Examples |
|-----------|---------|----------|
| Agent instruction files | `{N}-{stage}.md` | `1-planner.md`, `2-data-prep.md`, `3-analysis.md`, `4-review.md` |
| Dispatch files | `{pipeline}-{stage}.md` | `sales-data-prep.md`, `marketing-review.md` |
| Domain config | `domain-config.md` | One per pipeline directory |
| Business logic (domain-specific) | `{domain}/{type}.md` | `marketing/metrics.md`, `marketing/data-dictionary.md` |
| Business logic (universal) | `{type}.md` | `formula-rules.md`, `analysis-patterns.md` |
| Skills | `{verb}-{object}.md` | `create-analysis-sheet.md`, `build-sheet-formulas.md` |
| Plan docs | `.context/{pipeline}-plan.md` | `.context/sales-analytics-plan.md` |
| Model specs | `.context/{model-name}-spec.md` or `business-logic/models/{model-name}/spec.md` | Registry models use `business-logic/`, ad-hoc use `.context/` |
| Shared blocks | `codespecs/{block-name}.md` | `lookups-pattern.md`, `definitions-pattern.md` |
| Pipeline reading order | `agents/{pipeline}/domain-config.md § Reading Order` | Inlined in each domain-config |

## Tab Naming

Standard tabs (every analysis sheet):

| Tab | Purpose |
|-----|---------|
| `Summary` | Headline KPIs + dimensional breakdowns |
| `Raw Data` (or `Raw {Source}`) | Unmodified source data. Multiple raw tabs use source name: `Raw Campaign Members`, `Raw Opportunities` |
| `Prepared Data` | Cleaned data with helper columns and formulas |
| `Lookups` | Editable mapping tables for categorical dimensions |
| `Analysis` | SUMIFS/COUNTIFS formulas and deal lists |
| `Definitions` | Metric definitions, methodology, data sources |

Pipeline-specific tabs:

| Tab | Pipeline | Purpose |
|-----|----------|---------|
| `Model & Inputs` | Modeling | Computed/Override/Effective columns |
| `Audit` | Modeling | Model validation and sensitivity |

**Rules:**
- Title case, spaces not hyphens: `Prepared Data` not `prepared-data`
- Max 3 analysis tabs — consolidate with section headers
- Modeling tabs come from the model spec, not this convention

## Column Naming

| Tier | Convention | Examples |
|------|-----------|----------|
| Raw columns | Match source field names exactly | `Account Name`, `Close Date`, `Amount` |
| Tier 1 helpers | Descriptive, derived from raw + Lookups | `Pipeline Category`, `Quarter Label`, `Unified Lifecycle Stage` |
| Tier 2 helpers | Prefix with derivation hint | `Is Closed Won`, `Has Opportunity`, `Lifecycle Rank` |
| Boolean helpers | Always prefix with `Is ` or `Has ` | `Is MQL+`, `Is Excluded`, `Has Opportunity` |

## Lookups Section Naming

All Lookups sections follow the `{Dimension} Mapping` pattern:

| Pattern | Examples |
|---------|----------|
| `{Dimension} Mapping` | `Stage Mapping`, `Use Case Mapping`, `Campaign Type Mapping`, `Lifecycle Stage Mapping` |

This was standardized in W4. Never use bare names like "Stage Lookup" or "Type Categories."

## Identifiers in Code

| Entity | Convention | Example |
|--------|-----------|---------|
| Column map keys | Match header text exactly | `{"Quarter Label": "AH", "Is Closed Won": "AF"}` |
| Formula references | `$` lock + tab name in quotes | `'Prepared Data'!$F:$F` |
| Plan doc sections | Title case with `##` | `## Sheet:`, `## Column Map:`, `## Data Quality:` |

---

## Related

- `codespecs/agent-authoring.md` — file structure conventions for agent files
- `codespecs/formula-patterns.md` — formula-level conventions
