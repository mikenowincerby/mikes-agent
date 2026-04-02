# Definitions Pattern

Standard process for populating the Definitions tab in any analytics pipeline. The Definitions tab provides stakeholder-ready documentation so readers can understand every metric without asking the analyst.

## Required Sections

### Section 1: Metric Definitions

For every metric in the analysis:

| Column | Content |
|--------|---------|
| Metric Name | e.g., "NB Bookings" or "MQL Count" |
| Plain-Language Formula | e.g., "Sum of Amount where Pipeline Category = Won and Opp Type = New Business" |
| Cell References | e.g., "Summary!B3, Analysis!C5:C12" |
| Computation Method | "Sheet Formula", "Sheet Formula + Lookup", or "Python compute-and-push" |

If Python was used: state why and include the code.

### Section 2: Data Source Reference

- Source sheet ID(s) and name(s)
- Tab(s) used
- Date range of data
- Date anchor (what date field defines the cohort)
- Row count
- Date of analysis
- Computation note: "All tabs use Google Sheets formulas" (or flag exceptions)

### Section 3: Assumptions & Caveats

- Any known data gaps
- Scoping decisions (what was included/excluded and why)
- Methodology choices that affect interpretation

## Writing Rules

- Write with `valueInputOption: USER_ENTERED`
- Bold Column A (section headers and labels)
- Keep language non-technical -- a business stakeholder should understand every entry
