# Summary Tab Structure

> Shared reference block. Pipeline-specific customizations belong in `domain-config.md`.
> Sync marker: `<!-- SHARED: summary-tab-structure -->`

## Pattern

Every Summary tab must follow this structure, in order:

**Section A — Headline KPIs (rows 1-12):**
A vertical KPI block with 5-8 top-level metrics. These are the numbers a reader sees in the first 3 seconds. Format: Column A = Metric name, Column B = Value. One metric per row. No breakdown by dimension here — just the totals.

**Section B — Primary Breakdown Table(s) (rows 14+):**
The requested dimensional breakdowns (e.g., by Segment, by Campaign Type). Each breakdown is a table with section header, column headers, data rows, and a Total row.

**Section C — Notes (after last table):**
Caveats and assumptions: date range, date anchor, cohort definition, any known data gaps. Keep to 3-5 bullet points.

**Why this structure matters:** Without Section A, the reader must scan a breakdown table and find the Total row to get headline numbers. The KPI block provides instant context before the detail.

## Customization Points

- **Section A metrics:** Pipeline-specific. Sales uses Total Pipeline, Weighted Pipeline, Deal Count, ADS, Win Rate. Marketing uses Total Members, MQLs, SQLs, Conversion Rate, Cost per MQL.
- **Section B dimensions:** Driven by planner's requested breakdowns.
- **Modeling exception:** Modeling Summary tab is spec-driven (layout comes from `## Summary Layout` in the model spec), so this block does NOT apply to modeling/3-analysis.md.
