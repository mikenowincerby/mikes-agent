# Skill: Build Sheet Formulas

## What It Does

Writes Google Sheet formulas (SUMIFS, COUNTIFS, AVERAGEIFS) into Analysis tabs, referencing the Prepared Data tab. This is the **default calculation method** — prefer this over `compute-and-push`.

## When To Use

Step 4 (Analyze) of the Sales Analytics pipeline. Use this for all standard metric calculations.

## Inputs

| Input | Required | Description |
|-------|----------|-------------|
| `spreadsheetId` | Yes | The analysis sheet |
| `preparedDataRange` | Yes | Range of prepared data (e.g., "'Prepared Data'!A1:AZ1000") |
| `metrics` | Yes | List of metrics to calculate (from `business-logic/sales/metrics.md`) |
| `dimensions` | Yes | List of dimensions to slice by |
| `targetTab` | Yes | Which analysis tab to write to |
| `columnMap` | Yes | Header name → column letter mapping (from prep skill) |

## How To Invoke

### Step 1: Read Prepared Data Headers

```bash
gws sheets spreadsheets values get --params '{
  "spreadsheetId": "[spreadsheetId]",
  "range": "Prepared Data!1:1"
}'
```

Build a column map: `{"ARR": "F", "Stage": "G", "Opportunity Type": "H", ...}`. Never assume fixed column letters — always discover dynamically.

### Step 2: Build Formula Strings

Use the column map to construct formulas. All formulas reference `'Prepared Data'` tab (single-quoted because the tab name has a space).

**Formula patterns:**

#### SUMIFS (for booking metrics)
```
=SUMIFS('Prepared Data'!$F:$F, 'Prepared Data'!$G:$G, "9. Closed-Won", 'Prepared Data'!$H:$H, "New Business", 'Prepared Data'!$[quarter_label_col]:$[quarter_label_col], "[period]")
```

#### COUNTIFS (for counts like New Logos)
```
=COUNTIFS('Prepared Data'!$G:$G, "9. Closed-Won", 'Prepared Data'!$H:$H, "New Business", 'Prepared Data'!$[quarter_label_col]:$[quarter_label_col], "[period]")
```

#### AVERAGEIFS (for averages like Deal Size, Sales Cycle)
```
=AVERAGEIFS('Prepared Data'!$F:$F, 'Prepared Data'!$G:$G, "9. Closed-Won", 'Prepared Data'!$F:$F, ">"&0, 'Prepared Data'!$[quarter_label_col]:$[quarter_label_col], "[period]")
```

#### Win Rate
```
=IFERROR(COUNTIFS('Prepared Data'!$G:$G, "9. Closed-Won", [filters]) / (COUNTIFS('Prepared Data'!$G:$G, "9. Closed-Won", [filters]) + COUNTIFS('Prepared Data'!$G:$G, "10. Closed-Lost", [filters])), 0)
```

### Step 3: Write Formulas to Analysis Tab

```bash
gws sheets spreadsheets values update --params '{
  "spreadsheetId": "[spreadsheetId]",
  "range": "[targetTab]!A1",
  "valueInputOption": "USER_ENTERED"
}' --json '{"values": [[...]]}'
```

**CRITICAL: `valueInputOption` MUST be `USER_ENTERED`** — this tells Sheets to evaluate the formula. Using `RAW` would write the formula as plain text.

### Step 4: Verify Formulas

Read back the values to check for errors:

```bash
gws sheets spreadsheets values get --params '{
  "spreadsheetId": "[spreadsheetId]",
  "range": "[targetTab]!A1:Z100"
}'
```

Check for:
- `#REF!` — column reference is wrong
- `#N/A` — lookup failed
- `#DIV/0!` — division by zero (should be caught by IFERROR)
- `#VALUE!` — type mismatch
- Blank cells where values are expected

If errors found, investigate and fix the formula before proceeding.

## Analysis Tab Layout

Organize within each tab using section headers:

```
Row 1:  [SECTION HEADER — e.g., "New Business Bookings by Fiscal Quarter"]
Row 2:  [blank]
Row 3:  [Column headers — Period | Metric 1 | Metric 2 | ...]
Row 4+: [Data rows with formulas]
...
Row N:   [blank separator]
Row N+1: [NEXT SECTION HEADER]
...
```

**Max 3 analysis tabs.** Use section headers to consolidate related metrics into the same tab. Group logically:
- Performance metrics (bookings, conversion, cycle) in one section/tab
- Portfolio metrics (by segment, use case, sales play) in another

## Outputs

| Output | Description |
|--------|-------------|
| Analysis tab(s) | Populated with live formulas |
| Formula audit log | List of formulas written, printed for reference |

## Deal List Formulas

When the user asks for a list of specific deals (e.g., "show me the last 25 closed deals"), use FILTER/SORT formulas — not Python-computed static data.

**Pattern: Top N deals with two-stage sort**

Example: 25 most recent Closed-Won New Business deals, sorted by Sales Cycle Days (longest first):

```
=SORT(
  ARRAY_CONSTRAIN(
    SORT(
      FILTER(
        {cols from Prepared Data},
        'Prepared Data'!F2:F1005="New Business",
        'Prepared Data'!AF2:AF1005="Won"
      ),
      close_date_col_index, FALSE
    ),
    25, num_cols
  ),
  sales_cycle_col_index, FALSE
)
```

How it works:
1. `FILTER` selects rows matching conditions (using helper column values, not raw strings)
2. Inner `SORT` orders by Close Date descending (most recent first)
3. `ARRAY_CONSTRAIN` limits to top N rows
4. Outer `SORT` re-sorts the N rows by the desired display column

**Important notes:**
- Use explicit row ranges (e.g., `F2:F1005`) not open-ended (`F:F`) — open-ended ranges can cause #REF! when the spill area exceeds the grid
- Clear the target area before writing — spilling array formulas fail if they hit non-empty cells
- **Prefer FILTER/SORT over QUERY** — QUERY with mixed-type columns (text dates + numbers) can produce #VALUE! errors. FILTER/SORT handles mixed types reliably.
- Filter on **helper column values** (e.g., `AF="Won"`) not raw values (e.g., `G="9. Closed-Won"`)
- Write static headers in row 1, formula in A2 — the formula spills to fill the remaining rows

## Key Rules

- **Never hardcode values** — always reference Prepared Data
- **Always use `USER_ENTERED`** for formula writes
- **Reference helper columns in filter criteria** — use Pipeline Category ("Won", "Lost"), Is Closed Won, Closed?, etc. instead of parsing raw Stage strings. This keeps formulas simple and consistent with Lookups-driven mappings.
- **Lock column references with `$`** (e.g., `$F:$F`) so formulas don't shift
- **Single-quote tab names with spaces** in formula strings (e.g., `'Prepared Data'!`)
- **Max 3 analysis tabs** — consolidate with section headers
- **Verify after writing** — read back and check for formula errors
