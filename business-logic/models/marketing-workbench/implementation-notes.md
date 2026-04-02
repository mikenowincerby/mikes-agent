# Marketing Workbench — Implementation Notes

Lessons learned from building the Frontend Replica (Model #1). These rules apply to all workbench models.

## COUNTIFS Bug — Use SUMPRODUCT Instead

**COUNTIFS gives incorrect results on large formula-heavy sheets.** This is a known Google Sheets issue. COUNTIFS with `"<>"` or equality criteria returns inflated counts when the sheet has many formula columns.

**Rule:** Always use SUMPRODUCT for counting in analysis tabs:

```
# Instead of COUNTIFS:
=COUNTIFS('Prepared Data'!A:A, "value", 'Prepared Data'!G:G, "<>")     <- UNRELIABLE

# Use SUMPRODUCT:
=SUMPRODUCT(('Prepared Data'!$A$2:$A${N}="value")*(LEN('Prepared Data'!$G$2:$G${N})>0))  <- CORRECT
```

SUMPRODUCT patterns for each metric type:
- **Count matching rows:** `=SUMPRODUCT(('PD'!$A$2:$A${N}=A{row})*1)`
- **Count non-blank field:** `=SUMPRODUCT(('PD'!$A$2:$A${N}=A{row})*(LEN('PD'!$col$2:$col${N})>0))`
- **Count by flag value:** `=SUMPRODUCT(('PD'!$A$2:$A${N}=A{row})*('PD'!$col$2:$col${N}=1))`
- **Average with filter:** `=IFERROR(SUMPRODUCT(('PD'!$A$2:$A${N}=A{row})*('PD'!$col$2:$col${N})*(ISNUMBER('PD'!$col$2:$col${N})))/SUMPRODUCT(('PD'!$A$2:$A${N}=A{row})*(ISNUMBER('PD'!$col$2:$col${N}))),"")`

## Phantom Blank Cells — Use LEN>0 Instead of `<>""`

Cells written via the Google Sheets API with empty string values (`""`) appear blank but are not truly blank. `ISBLANK()` returns FALSE, `COUNTA()` counts them, and `<>""` returns TRUE. Only `LEN()>0` and `SUMPRODUCT` with `LEN>0` give correct results.

**Rule:** Never use `<>""` or `ISBLANK()` to check for non-blank cells in API-written data. Always use `LEN(cell)>0`.

## Enriched Lifecycle Columns — Pre-Compute in Python

For columns that require INDEX/MATCH lookups across large raw data tabs (30K+ rows), Google Sheets formulas hit resource limits when applied to 9K+ rows. Pre-compute these values in Python and write as static values instead.

**Affected columns:** Unified MQL Start Date (AR), Unified SAL Start Date (AT), Unified SQL Start Date (AV).

**Enrichment cascade (contact-first precedence):**
1. Campaign Member contact field (e.g., C MQL Start Datetime, col K)
2. Campaign Member lead field (e.g., MQL Start Datetime, col W)
3. Raw Contacts lookup (by Contact ID -> C MQL Start Datetime)
4. Raw Leads lookup (by Lead ID -> MQL Start Datetime)

**Rule:** Write enriched values with `valueInputOption: RAW`. Document in Definitions tab that these columns are pre-computed, not live formulas.

## MQL Counting Methodology

The Salesforce Campaign frontend counts MQLs as members who **have ever MQL'd** (have a non-blank MQL Start Date), not members whose current lifecycle stage is MQL+ (Is MQL+ = "Yes").

**Rule:** For Frontend Replica validation, count MQLs using `LEN(Unified MQL Start Date) > 0`, not `Is MQL+ = "Yes"`. The Is MQL+ flag reflects current lifecycle stage which may have advanced past MQL.
