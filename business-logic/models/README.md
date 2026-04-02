# Model Registry

The modeling pipeline (`agents/pipelines/modeling/`) executes data-driven models that score, forecast, or classify individual records (deals, accounts, leads) using historical patterns. Each model is defined by a **spec file** that parameterizes the generic pipeline.

## Registry vs Ad-Hoc

| Mode | When | Spec Location | Lifecycle |
|------|------|---------------|-----------|
| **Registry** | Repeatable model with validated methodology | `business-logic/models/<name>/spec.md` | Permanent — versioned in git |
| **Ad-hoc** | One-time or experimental model | `.context/<name>-spec.md` | Ephemeral — lives in .context |

The planner (`agents/pipelines/modeling/1-planner.md`) detects which mode to use:
- If the user's request matches a registered model → load its spec, confirm scope
- If no match → build a spec conversationally, section by section

## Promoting Ad-Hoc to Registry

After a successful ad-hoc model run:
1. Copy `.context/<name>-spec.md` to `business-logic/models/<name>/spec.md`
2. Add an entry to the Registered Models table below
3. Commit to git

## Canonical Spec Format

Every model spec — registry or ad-hoc — follows this section structure. The generic pipeline stages reference these sections by name.

```markdown
# Model: <Name>

## Metadata
- **Name:** Human-readable model name
- **Version:** Semantic version (e.g., v2.0)
- **Description:** One-line summary of what the model does
- **Owner:** Who maintains this model
- **Created:** Date

## Source
- **Sheet ID:** Google Sheet ID
- **Tab:** Tab name to read from
- **Row Offset:** Where headers and data start (e.g., "Row 1 is banner; headers at Row 2; data at Row 3")
- **Column Range:** e.g., "A2:AC"
- **Required Fields:** List of field names that must exist for the model to work

## Tab Structure
Ordered list of output tabs with formatting roles:
| Tab Name | Index | Role |
|----------|-------|------|
| ... | 0 | summary / deal-list / analysis / prepared-data / raw-data / lookups / definitions |

## Lookups
Section-by-section Lookups tab content. Each section:
- **Range:** e.g., A1:C10
- **Headers:** Column headers
- **Values:** The mapping data (table or description)
- **Write mode:** RAW or USER_ENTERED

## Tier 1 Helper Columns
Columns that reference ONLY raw data + Lookups.
| Col | Header | Formula (row n) | Notes |
|-----|--------|-----------------|-------|

## Tier 2 Helper Columns
Columns that reference Tier 1 outputs.
| Col | Header | Formula (row n) | Notes |
|-----|--------|-----------------|-------|

## Model Sections
For each section in the Model & Inputs tab:
### Section X: <Name>
- **Row range:** e.g., rows 1-16
- **Layout:** Describe the matrix structure (rows, columns)
- **Computed formula:** The COUNTIFS/AVERAGEIFS pattern
- **Sample size formula:** (if applicable)
- **Override/Effective:** How overrides work
- **Sparse fallback:** What happens when sample < threshold

## Tier 3 Helper Columns
Columns that reference Model & Inputs tab. Written AFTER Model sections.
| Col | Header | Logic | Formula (row n) |
|-----|--------|-------|-----------------|

## Exceptions
| Condition | Conv Rate | Close Date | Value Field | Notes |
|-----------|-----------|------------|-------------|-------|

## Summary Layout
### Section 1: <Name>
- Row layout, metric formulas, column structure
### Section 2+: Breakdowns
- Dimension, source column, metrics per dimension value

## Audit Tab
- **Dropdown:** Location, values, data validation
- **Columns:** Ordered list of column headers
- **Filter formula:** The FILTER/SORT pattern
- **Derived columns:** Any calculated columns in the audit view

## Sanity Checks
| Check | Rule | Threshold | Severity | Phase |
|-------|------|-----------|----------|-------|
Severity: hard-fail / warning / info
Phase: data-quality (run after Tier 2) / model-review (run in review stage)

## Definitions Template
### Section 1: Methodology Overview
Content for rows N-M
### Section 2: FAQ
Questions and answers
### Section 3: Metric Definitions
| Metric | Definition | Formula | Source Column |
### Section 4: Data Source & Refresh
Source details, computation method, override instructions
### Section 5: Assumptions & Limitations
What the model assumes and where it breaks down
```

## Registered Models

| Model | Spec Path | Description |
|-------|-----------|-------------|
| Ops Forecast | `ops-forecast/spec.md` | Stage x Use Case conversion rates + Lead Source adjustments → per-deal Ops Conv Rate + Ops Close Date |
| Marketing Workbench | `marketing-workbench/spec.md` | Persistent workbench with IMPORTRANGE data, 5 analytical models (Frontend Replica, Lead Cohort, Campaign Efficiency, Account Look-Back, Lead Tracing) |
