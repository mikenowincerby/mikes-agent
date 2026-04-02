# Formula-First Rules

Domain-agnostic principles for building auditable Google Sheets analyses. Every output cell must be inspectable by the user.

---

## Rules

### 1. Sheet Formulas, Not Static Values
Calculated columns, summary metrics, and list outputs are all Google Sheets formulas. Python is only for computation that genuinely exceeds Sheet capability (e.g., cross-row ranking with complex tiebreakers). If Python is used, flag it in the Definitions tab.

### 2. Lookups Tab Drives All Mappings
Categorical mappings (e.g., stage → category, raw label → simplified label) live in a Lookups tab as editable tables. Formulas use VLOOKUP against these tables. No hardcoded IF chains for mappings. This gives the user control — they edit Lookups to change categorizations without touching formulas.

### 3. Row-by-Row Formulas
Each cell gets its own formula. No ARRAYFORMULAs. This makes every cell independently inspectable and avoids cascading failures from a single broken array formula.

### 4. Helper Columns Simplify Downstream Formulas
Create intermediate calculated columns (e.g., Pipeline Category, Is Closed Won, Closed?, Quarter Label) so that downstream formulas reference clean helpers instead of parsing raw data strings. This makes formulas shorter, less error-prone, and easier to audit.

### 5. Build in Dependency Order
Write formulas in tiers — each tier's dependencies must resolve before writing the next:
- **Tier 1:** References raw columns + Lookups only
- **Tier 2:** References Tier 1 helper columns
- **Tier 3:** References Tier 2 helper columns

Never write a formula that references a column that hasn't been written yet.

### 6. Deal-List Outputs Use FILTER/SORT
When the user asks "show me the top N deals," use FILTER/SORT/ARRAY_CONSTRAIN formulas — not Python data pastes. Prefer FILTER/SORT over QUERY (QUERY with mixed-type columns can produce #VALUE! errors). Filter on helper column values, not raw data strings.

---

## Approach Validation Checklist

Before any data is touched, confirm:

```
APPROACH VALIDATION
-------------------
[ ] All calculated columns will be Sheet formulas (not Python-computed static values)
[ ] Lookups tab will be populated with mapping tables before formulas are written
[ ] All mappings use VLOOKUP against Lookups — no hardcoded IF chains
[ ] Deal-list outputs (if any) use FILTER/SORT formulas — not static data
[ ] Python compute-and-push: [none required / required for: <reason>]
```

If any item cannot be checked, revise the approach before proceeding.

---

## Automated Reports (GitHub Actions, Scripts, Scheduled Tasks)

Automated reports follow the same formula-first principles. The fact that data is computed in a script does NOT exempt the output sheet from auditability. Anyone opening the sheet must be able to inspect how results were derived.

### Architecture: Data Tab + Formula Tab

Every automated report that writes to Google Sheets MUST use a two-tab structure:

1. **Data tab** — Contains the raw/filtered backing data written by the script. This is the source of truth. Column headers must match the source system (e.g., Salesforce field names). No transformations that can't be traced back to the source.

2. **Report tab** — Contains ONLY formulas that reference the Data tab. Ranking, sorting, grouping, and formatting are all done via Sheet formulas (FILTER, SORT, RANK, INDEX/MATCH, etc.). No static values except labels and headers.

### Why This Matters

| Without formulas | With formulas |
|-----------------|---------------|
| "Trust me, Deal X is #1" | `=INDEX(Data!C:C, MATCH(LARGE(Data!E:E, 1), Data!E:E, 0))` — click to verify |
| Can't re-sort or re-filter | Change a filter criteria → results update live |
| Stale the moment it's created | Backing data can be refreshed; formulas recalculate |
| No audit trail | Full audit trail — every cell shows its derivation |

### Required Pattern for Scripts

```
Script responsibility:
  1. Read source data
  2. Apply filters (e.g., New Business, Stages 2-6)
  3. Write FILTERED rows to "Data" tab (raw values, USER_ENTERED for numbers)
  4. Write FORMULAS to "Report" tab that reference Data tab
  5. Write a Definitions/Metadata section (filter criteria, source sheet, run date)

Script must NOT:
  - Pre-compute rankings, groupings, or aggregations as static values
  - Write final report values without backing formulas
  - Omit the backing data that formulas reference
```

### Formula Examples for Common Report Patterns

```
Top N by amount per group:
  =SORT(FILTER(Data!A:G, Data!A:A="Marketing"), 5, FALSE)

Rank within group:
  =RANK(E2, FILTER(Data!E:E, Data!A:A=A2), 0)

Count per group:
  =COUNTIF(Data!A:A, "Marketing")

Sum per group:
  =SUMIF(Data!A:A, "Marketing", Data!E:E)
```

---

## Visual Formatting Standards

Formatting is applied as a separate step after formulas are written — see `skills/format-output-sheet.md`. The formatting skill handles header styling, number formats, alignment, chromatic font colors (blue=source, black=formula, green=lookup), column widths, and border cleanup. It never modifies cell values or formulas.

---

## INDEX-MATCH (When VLOOKUP Won't Work)

Use INDEX-MATCH when the lookup column is not the leftmost column or you need multi-criteria matching:

```
=IFERROR(INDEX(Lookups!$C:$C, MATCH(A2, Lookups!$A:$A, 0)), "")
```

Default to VLOOKUP for Lookups tab references (always left-to-right). Use INDEX-MATCH only when structurally necessary.

## Complexity Threshold

When a formula exceeds ~150 characters or nests >3 functions deep:

| Signal | Action |
|--------|--------|
| >150 chars or >3 nesting levels | Split into helper column + simpler formula |
| Cross-row logic (running totals, ranking with tiebreakers) | Use `skills/compute-and-push.md` |
| Multi-sheet aggregation (3+ tabs) | Use `skills/compute-and-push.md` |

First choice: simplify with helper columns. Second choice: compute-and-push. Always flag Python usage in the Definitions tab.

## Common Anti-Patterns

| Don't | Do Instead |
|-------|-----------|
| Write static values from Python/jq to calculated columns | Write Sheet formulas with `valueInputOption: USER_ENTERED` |
| Pre-compute rankings in a script and paste results | Write RANK/SORT formulas that reference backing data |
| Use ARRAYFORMULA for calculated columns | Write individual row-by-row formulas |
| Hardcode IF chains for categorical mappings | VLOOKUP against Lookups tab |
| Filter on raw data strings (e.g., Stage = "9. Closed-Won") | Filter on helper columns (e.g., Pipeline Category = "Won") |
| Use QUERY for deal lists | Use FILTER/SORT/ARRAY_CONSTRAIN |
| Write Tier 2 formulas before Tier 1 resolves | Write in strict tier order |
| Write report values without backing data in the same sheet | Always include a Data tab with the raw rows that formulas reference |
| Use raw curl/API calls when gws CLI is available | Use gws CLI — it handles auth, retries, and error formatting |
| Empty cell in SUMIFS criteria returns 0 | Use `<>""` not `<>0` for text columns |
| Numeric vs text comparison in SUMIFS | Ensure source column was written with `USER_ENTERED`, not `RAW` |
| Date serial vs text date mismatch | Compare date serials, not text. Use `DATEVALUE()` if source is text |
