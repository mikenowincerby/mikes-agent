# Model #1: Frontend Replica

## Purpose

Validates the workbench data model by reconstructing Master Campaign Frontend Data metrics from raw data. All 12 metrics are computed from Prepared Data formulas and compared against the Frontend Data actuals. A delta of 0 for each metric confirms the data pipeline is correct.

## Filter

Qualifying campaigns must meet BOTH criteria:
- Campaign Name starts with **"MKTG"**
- Campaign Start Date >= **2025-02-01**

### Campaign List Source

The campaign list is derived from Raw Campaigns using a FILTER formula:

```
=FILTER(
  Raw Campaigns A:A,
  LEFT(Raw Campaigns D:D, 4) = "MKTG",
  Raw Campaigns F:F >= DATE(2025,2,1)
)
```

This produces the list of qualifying ADMIN Campaign 18 Digit IDs in Column A of the Frontend Replica tab. Column B shows the Campaign Name (VLOOKUP from Campaign Mapping Lookups).

---

## Layout

Row 1: Headers
Row 2+: One row per qualifying campaign

| Col | Header | Description |
|-----|--------|-------------|
| A | Campaign 18 Digit ID | From FILTER on Raw Campaigns |
| B | Campaign Name | `=IFERROR(VLOOKUP(A{N},Lookups!$A:$C,3,FALSE),"")` |

Then for each of the 12 metrics, 3 columns:

| Group | Col Offset | Header Pattern | Description |
|-------|-----------|----------------|-------------|
| Calculated | +0 | `{Metric} (Calc)` | Formula from Prepared Data |
| Frontend Actual | +1 | `{Metric} (Actual)` | VLOOKUP from Raw Frontend Data |
| Delta | +2 | `{Metric} (Delta)` | `= Calculated - Actual` |

---

## Frontend VLOOKUP

Match qualifying campaigns against Raw Frontend Data using ADMIN Campaign 18 Digit ID:

```
=IFERROR(VLOOKUP(A{N}, 'Raw Frontend Data'![X_col]:[value_col], col_offset, FALSE), "")
```

Raw Frontend Data join key: Column X (ADMIN Campaign 18 Digit ID).

---

## Metrics

### 1. Total Campaign Members

| Column | Formula |
|--------|---------|
| Calculated | `=SUMPRODUCT(('Prepared Data'!$A$2:$A${N}=A{row})*1)` |
| Frontend Actual | `=IFERROR(INDEX('Raw Frontend Data'!F:F, MATCH(A{row},'Raw Frontend Data'!X:X,0)),"")` |
| Delta | `=IF(OR(Calc="",Actual=""),"",Calc-Actual)` |

Frontend col F = Total Campaign Members.

### 2. Net New Leads

| Column | Formula |
|--------|---------|
| Calculated | `=SUMPRODUCT(('Prepared Data'!$A$2:$A${N}=A{row})*('Prepared Data'!$[OriginType]$2:$[OriginType]${N}="Lead"))` |
| Frontend Actual | `=IFERROR(INDEX('Raw Frontend Data'!H:H, MATCH(A{row},'Raw Frontend Data'!X:X,0)),"")` |
| Delta | `=IF(OR(Calc="",Actual=""),"",Calc-Actual)` |

Frontend col H = Net New Leads in Campaign.

### 3. MQLs in Campaign

| Column | Formula |
|--------|---------|
| Calculated | `=SUMPRODUCT(('Prepared Data'!$A$2:$A${N}=A{row})*(LEN('Prepared Data'!$[UnifiedMQLStart]$2:$[UnifiedMQLStart]${N})>0))` |
| Frontend Actual | `=IFERROR(INDEX('Raw Frontend Data'!K:K, MATCH(A{row},'Raw Frontend Data'!X:X,0)),"")` |
| Delta | `=IF(OR(Calc="",Actual=""),"",Calc-Actual)` |

Frontend col K = MQLs in Campaign. **Uses MQL Start Date presence (LEN>0), not Is MQL+ lifecycle flag.** The frontend counts members who have ever MQL'd, not current lifecycle stage.

### 4. SQLs

| Column | Formula |
|--------|---------|
| Calculated | `=SUMPRODUCT(('Prepared Data'!$A$2:$A${N}=A{row})*(LEN('Prepared Data'!$[UnifiedSQLStart]$2:$[UnifiedSQLStart]${N})>0))` |
| Frontend Actual | `=IFERROR(INDEX('Raw Frontend Data'!O:O, MATCH(A{row},'Raw Frontend Data'!X:X,0)),"")` |
| Delta | `=IF(OR(Calc="",Actual=""),"",Calc-Actual)` |

Frontend col O = SQLs in Campaign. **Uses SQL Start Date presence (LEN>0), not Is SQL+ lifecycle flag.**

### 5. Opportunities

| Column | Formula |
|--------|---------|
| Calculated | `=SUMPRODUCT(('Prepared Data'!$A$2:$A${N}=A{row})*('Prepared Data'!$[HasOpp]$2:$[HasOpp]${N}=1))` |
| Frontend Actual | `=IFERROR(INDEX('Raw Frontend Data'!R:R, MATCH(A{row},'Raw Frontend Data'!X:X,0)),"")` |
| Delta | `=IF(OR(Calc="",Actual=""),"",Calc-Actual)` |

Frontend col R = Opportunities in Campaign.

### 6. Won Opportunities

| Column | Formula |
|--------|---------|
| Calculated | `=SUMPRODUCT(('Prepared Data'!$A$2:$A${N}=A{row})*('Prepared Data'!$[IsClosedWon]$2:$[IsClosedWon]${N}=1))` |
| Frontend Actual | `=IFERROR(INDEX('Raw Frontend Data'!T:T, MATCH(A{row},'Raw Frontend Data'!X:X,0)),"")` |
| Delta | `=IF(OR(Calc="",Actual=""),"",Calc-Actual)` |

Frontend col T = Won Opportunities in Campaign.

### 7. Actual Cost

| Column | Formula |
|--------|---------|
| Calculated | `=IFERROR(VLOOKUP(A{N},Lookups!$A:$G,7,FALSE),"")` |
| Frontend Actual | `=IFERROR(INDEX('Raw Frontend Data'!E:E, MATCH(A{N},'Raw Frontend Data'!X:X,0)),"")` |
| Delta | `= Calculated - Actual` |

Frontend col E = Actual Cost in Campaign.

### 8. Cost per MQL

| Column | Formula |
|--------|---------|
| Calculated | `=IFERROR([Cost_Calc]{N} / [MQL_Calc]{N}, "")` |
| Frontend Actual | `=IFERROR(INDEX('Raw Frontend Data'!M:M, MATCH(A{N},'Raw Frontend Data'!X:X,0)),"")` |
| Delta | `= Calculated - Actual` |

Frontend col M = Cost per MQL.

### 9. Cost per SQL

| Column | Formula |
|--------|---------|
| Calculated | `=IFERROR([Cost_Calc]{N} / [SQL_Calc]{N}, "")` |
| Frontend Actual | `=IFERROR(INDEX('Raw Frontend Data'!Q:Q, MATCH(A{N},'Raw Frontend Data'!X:X,0)),"")` |
| Delta | `= Calculated - Actual` |

Frontend col Q = Cost per SQL.

### 10. Average Demographic Score

| Column | Formula |
|--------|---------|
| Calculated | `=IFERROR(SUMPRODUCT(('PD'!$A$2:$A${N}=A{row})*('PD'!$[SortScoreNumeric]$2:$[SortScoreNumeric]${N})*(ISNUMBER('PD'!$[SortScoreNumeric]$2:$[SortScoreNumeric]${N})))/SUMPRODUCT(('PD'!$A$2:$A${N}=A{row})*(ISNUMBER('PD'!$[SortScoreNumeric]$2:$[SortScoreNumeric]${N}))),"")` |
| Frontend Actual | `=IFERROR(INDEX('Raw Frontend Data'!N:N, MATCH(A{row},'Raw Frontend Data'!X:X,0)),"")` |
| Delta | `=IF(OR(Calc="",Actual=""),"",Calc-Actual)` |

Frontend col N = Average Demographic Score. Uses SUMPRODUCT for filtered average (avoids AVERAGEIFS issues on large sheets).

### 11. Leads in Campaign

| Column | Formula |
|--------|---------|
| Calculated | `=SUMPRODUCT(('Prepared Data'!$A$2:$A${N}=A{row})*(LEN('Prepared Data'!$[LeadID]$2:$[LeadID]${N})>0))` |
| Frontend Actual | `=IFERROR(INDEX('Raw Frontend Data'!Y:Y, MATCH(A{row},'Raw Frontend Data'!X:X,0)),"")` |
| Delta | `=IF(OR(Calc="",Actual=""),"",Calc-Actual)` |

Frontend col Y = Leads in Campaign. `[LeadID]` = ADMIN Lead ID 18 Digit column in Prepared Data. **Uses `LEN>0` not `<>""` due to phantom blank cell issue.**

### 12. Contacts in Campaign

| Column | Formula |
|--------|---------|
| Calculated | `=SUMPRODUCT(('Prepared Data'!$A$2:$A${N}=A{row})*(LEN('Prepared Data'!$[ContactID]$2:$[ContactID]${N})>0))` |
| Frontend Actual | `=IFERROR(INDEX('Raw Frontend Data'!Z:Z, MATCH(A{row},'Raw Frontend Data'!X:X,0)),"")` |
| Delta | `=IF(OR(Calc="",Actual=""),"",Calc-Actual)` |

Frontend col Z = Contacts in Campaign. `[ContactID]` = ADMIN Contact ID 18 Digit column in Prepared Data. **Uses `LEN>0` not `<>""` due to phantom blank cell issue.**

---

## Column Map Summary

| Metric | Prepared Data Column(s) | Frontend Data Col | Frontend Join Key | Formula Type |
|--------|------------------------|-------------------|-------------------|-------------|
| Total Campaign Members | Campaign 18 Digit ID (A) | F | X | SUMPRODUCT count |
| Net New Leads | Campaign ID + Origin Type | H | X | SUMPRODUCT with text match |
| MQLs in Campaign | Campaign ID + Unified MQL Start Date | K | X | SUMPRODUCT with LEN>0 |
| SQLs | Campaign ID + Unified SQL Start Date | O | X | SUMPRODUCT with LEN>0 |
| Opportunities | Campaign ID + Has Opportunity | R | X | SUMPRODUCT with =1 |
| Won Opportunities | Campaign ID + Is Closed Won Opp | T | X | SUMPRODUCT with =1 |
| Actual Cost | Campaign Mapping Lookups (col G) | E | X | VLOOKUP |
| Cost per MQL | Calculated Cost / Calculated MQLs | M | X | Division |
| Cost per SQL | Calculated Cost / Calculated SQLs | Q | X | Division |
| Average Demographic Score | Sort Score Numeric | N | X | SUMPRODUCT avg |
| Leads in Campaign | ADMIN Lead ID 18 Digit (LEN>0) | Y | X | SUMPRODUCT with LEN>0 |
| Contacts in Campaign | ADMIN Contact ID 18 Digit (LEN>0) | Z | X | SUMPRODUCT with LEN>0 |

---

## Success Criteria

- All 12 delta columns = 0 for every qualifying campaign
- If deltas are non-zero, document the specific campaigns and metrics with differences
- Explainable differences (e.g., timing of daily refresh, rounding) should be noted but do not constitute failure
- Formula errors (#REF!, #N/A, #VALUE!) in any cell = hard-fail

## Validated Match Rates (v1.0)

Results from initial build with ~9,374 campaign members across 62 qualifying campaigns:

| Metric | Match Rate | Notes |
|--------|-----------|-------|
| Total Members | 100% (62/62) | |
| Won Opps | 100% (62/62) | |
| Contacts | 100% (62/62) | |
| Leads | 100% (62/62) | |
| Actual Cost | 90.3% (56/62) | 6 campaigns with no cost in source |
| Opportunities | 72.6% (45/62) | |
| SQLs | 66.1% (40/62) | Uses SQL Start Date presence |
| MQLs | 29.0% (18/62) | Undercounting — sparse MQL dates in source |
| Net New Leads | 27.4% (17/62) | Frontend definition may differ from Origin Type |
| Avg Demo Score | 0% | Field pending in source data |

## Implementation Notes

- **Use SUMPRODUCT, not COUNTIFS** — COUNTIFS is unreliable on large formula-heavy sheets (known Google Sheets bug). See spec.md "Google Sheets Implementation Notes".
- **Use LEN>0, not `<>""`** — API-written empty cells are phantom non-blank (ISBLANK=FALSE, LEN=0). See spec.md "Phantom Blank Cells".
- Use `[dynamic]` column letters — discover Prepared Data headers at build time
- FILTER formula for campaign list goes in A2 (A1 is header)
- All Frontend Actual lookups use INDEX/MATCH (not VLOOKUP) because the join key (col X) is to the right of the value columns
- Cost per MQL and Cost per SQL are derived from the Calculated columns on the same row, not from Prepared Data directly
- `IFERROR` wrappers on all lookups to handle campaigns missing from Frontend Data
- **MQLs/SQLs use date presence**, not lifecycle flags — the frontend counts members who ever reached that stage, not current stage
- **Enriched lifecycle columns (AR, AT, AV) are pre-computed static values**, not formulas — INDEX/MATCH across 30K+ rows exceeds Sheets resource limits when applied to 9K+ formula rows
