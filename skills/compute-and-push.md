# Skill: Compute and Push

## What It Does

For calculations that exceed Google Sheets formula capability, this skill computes results in Python and pushes them to the analysis sheet via `gws` CLI. Results are static (not live-updating).

**This is the FALLBACK, not the default.** Always prefer `build-sheet-formulas` first.

## When To Use

Step 4 (Analyze) of the Sales Analytics pipeline, but ONLY when Sheet formulas cannot accomplish the calculation. You must justify why formulas are insufficient before using this skill.

**Examples where this is needed:**
- Percentile calculations (e.g., median deal size, P90 sales cycle)
- Rolling averages across variable time windows
- Cohort analysis with complex grouping logic
- Statistical tests (e.g., significance of conversion rate changes)
- Weighted averages across multiple filter dimensions
- Complex date math that exceeds Sheet formula readability

**Examples where formulas ARE sufficient (use `build-sheet-formulas` instead):**
- SUMIFS, COUNTIFS, AVERAGEIFS with any number of criteria
- Simple division / percentages
- IFERROR wrappers
- Basic date arithmetic

## Inputs

| Input | Required | Description |
|-------|----------|-------------|
| `spreadsheetId` | Yes | The analysis sheet |
| `preparedDataRange` | Yes | Range to pull from Prepared Data |
| `computation` | Yes | Description of what to compute and why formulas can't do it |
| `targetTab` | Yes | Which tab to write results to |
| `targetRange` | Yes | Specific cell range for output (e.g., "Analysis!G15:G20") |

## How To Invoke

### Step 1: Pull Data

```bash
gws sheets spreadsheets values get --params '{
  "spreadsheetId": "[spreadsheetId]",
  "range": "[preparedDataRange]"
}'
```

### Step 2: Compute in Python

```python
import pandas as pd
import numpy as np

# Parse gws response into DataFrame
df = pd.DataFrame(data_rows, columns=headers)

# Example: Median deal size by segment
result = df[df['Stage'] == '9. Closed-Won'].groupby('Company Segment')['ARR'].median()

# Example: P90 sales cycle
p90 = df[df['Stage'] == '9. Closed-Won']['Sales Cycle Days'].quantile(0.9)

# Example: Rolling 3-month average bookings
monthly = df[df['Stage'] == '9. Closed-Won'].groupby('Quarter Label')['ARR'].sum()
rolling_avg = monthly.rolling(3).mean()
```

### Step 3: Push Results

```bash
gws sheets spreadsheets values update --params '{
  "spreadsheetId": "[spreadsheetId]",
  "range": "[targetTab]![targetRange]",
  "valueInputOption": "RAW"
}' --json '{"values": [[...]]}'
```

**Use `valueInputOption: RAW`** for computed values — these are final numbers, not formulas.

### Step 4: Update Definitions Tab

Add an entry to the Definitions tab for every computed cell:

| Cell Reference | Metric | Method | Description |
|---------------|--------|--------|-------------|
| Analysis!G15 | Median Deal Size (SMB) | Computed (Python) | `df[df['Segment']=='SMB']['ARR'].median()` |
| Analysis!G16 | Median Deal Size (Mid-Market) | Computed (Python) | `df[df['Segment']=='Mid-Market']['ARR'].median()` |

This makes it clear which cells are live formulas vs static computed values.

## Outputs

| Output | Description |
|--------|-------------|
| Computed values | Written to target range |
| Definitions update | Computation method flagged for each cell |
| Python code | Logged in output for auditability |

## Key Rules

- **Justify before using.** State why Sheet formulas can't do this calculation.
- **Flag every computed cell** in the Definitions tab as "Computed (Python)"
- **Include the Python code** in the Definitions tab or conversation output for auditability
- **Results are STATIC** — they do not update when source data changes. This is the tradeoff vs formulas. Note this in the Definitions tab.
- **Use `RAW` for valueInputOption** — these are values, not formulas
- **Prefer formulas for everything else.** If in doubt, try formulas first.
