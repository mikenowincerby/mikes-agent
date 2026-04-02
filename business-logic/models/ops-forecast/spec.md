# Model: Ops Forecast

## Metadata

- **Name:** Ops Forecast
- **Version:** v3.0
- **Description:** Data-driven deal-level forecasting using historical stage x use case conversion rates, lead source adjustments, and Forecast Category quarterly value distribution. Replaces subjective pipeline weighting with formula-driven Ops Conv Rate, Ops Close Date, and FC-distributed Ops Forecast Value per deal.
- **Owner:** BizOps
- **Created:** 2026-03-15

## Source

- **Sheet ID:** `$DAILY_DATA` (Daily Data — READ-ONLY)
- **Tab:** Opportunity
- **Row Offset:** Row 1 is a title banner. Headers at Row 2, data starts at Row 3.
- **Column Range:** A2:AC (29 columns)
- **Live Link:** Raw Data tab uses `=IMPORTRANGE("$DAILY_DATA", "Opportunity!A2:AC")` in cell A1. Data refreshes automatically — no manual paste needed. (resolve $DAILY_DATA from sources.md)
- **Required Fields:**
  - Stage (G) — current pipeline stage
  - Close Date (J) — text format "YYYY-MM-DD HH:MM:SS"
  - Opportunity Type (F) — "New Business", "Existing Business", or contains "LOI"
  - Amount (S) — NB deal value
  - Order Delta ARR (T) — EB/Renewal deal value
  - Forecast Category (U) — includes "Commit"
  - Primary Use Case (Q)
  - Lead Source Attribution (P)
  - Full Name (E) — rep name
  - Sales Play (R)
  - Stage 2-6 Start Date columns (V-Z) — entry timestamps per stage
  - Account Name (B)
  - Opportunity Name (A)
  - Amount Weighted (column varies — discover dynamically)

## Tab Structure

| Tab Name | Index | Role |
|----------|-------|------|
| Exec Summary | 0 | exec-summary |
| Forecast Summary | 1 | summary |
| Audit | 2 | deal-list |
| Data Audit | 3 | deal-list |
| Model & Inputs | 4 | analysis |
| Prepared Data | 5 | prepared-data |
| Raw Data | 6 | raw-data |
| Lookups | 7 | lookups |
| Definitions | 8 | definitions |

**Title format:** `Ops Forecast Model — YYYY-MM-DD`

---

## Lookups & Tier 1-2 Helper Columns

See `tiers.md` in this directory for Lookups definitions, Tier 1, and Tier 2 helper column formulas.

---

## Model Sections

The Model & Inputs tab contains 5 sections. Sections A-D use the **Computed / Override (yellow bg) / Effective** pattern. Section E uses direct-edit yellow cells for quarterly distribution percentages:
- **Computed:** Formula-driven from historical data
- **Override:** Blank cell with yellow background (#FFF2CC / RGB 255,242,204) — user can type a value
- **Effective:** `=IF(Override<>"", Override, Computed)` — this is what Tier 3 references

Save all section positions to `.context/model-positions.json` for Tier 3 formula generation.

### Section A: Conversion Rates (Rows 1-16)

**Layout:** Stage x Use Case matrix.

- **Rows 1-2:** Section header ("CONVERSION RATES") + description
- **Row 3:** Column headers — Stage | then for each Use Case: Computed | Override | Effective | then Overall: Computed | Override | Effective
- **Rows 4-8:** Stage 2-6 data rows
- **Row 10:** "SAMPLE SIZE" header
- **Row 11:** Column headers (same structure)
- **Rows 12-16:** Stage 2-6 sample counts

**Use Cases (columns):** Social Media Access, Access Management, Identity Security, Other, Overall

Each Use Case gets 3 columns: Computed | Override | Effective.

**Computed conversion rate formula:**
```
=IFERROR(
  COUNTIFS('Prepared Data'!$AU:$AU,1, 'Prepared Data'!$AM:$AM,1, 'Prepared Data'!$AE:$AE,"<Use Case>", 'Prepared Data'!$AF:$AF,1, 'Prepared Data'!$AT:$AT,0)
  /
  COUNTIFS('Prepared Data'!$AT:$AT,0, IF({1},CHOOSE(ROW()-3,'Prepared Data'!$AM:$AM,'Prepared Data'!$AN:$AN,'Prepared Data'!$AO:$AO,'Prepared Data'!$AP:$AP,'Prepared Data'!$AQ:$AQ),0),1, 'Prepared Data'!$AE:$AE,"<Use Case>", 'Prepared Data'!$AF:$AF,1, OR('Prepared Data'!$AU:$AU=1,'Prepared Data'!$AV:$AV=1),TRUE)
, "")
```

- Numerator: Won deals that reached this stage, for this use case, historical, not excluded
- Denominator: Resolved deals (won + lost + QO) that reached this stage, for this use case, historical
- **Overall** column: same formula without Use Case filter

**Sample size formula:** Same denominator COUNTIFS as conversion rate (the count of resolved deals).

**Effective:** `=IF(Override<>"", Override, Computed)`

### Section B: Days to Close (Rows 18-25)

Same Stage x Use Case layout as Section A.

- **Rows 18-19:** Section header ("DAYS TO CLOSE") + description
- **Row 20:** Column headers
- **Rows 21-25:** Stage 2-6 data rows

**Computed formula:**
```
=IFERROR(AVERAGEIFS('Prepared Data'!$AW:$AW, 'Prepared Data'!$AE:$AE, "<Use Case>", 'Prepared Data'!$AF:$AF, 1, 'Prepared Data'!$AU:$AU, 1, 'Prepared Data'!$AT:$AT, 0), "")
```
(Column varies by stage: AW for S2, AX for S3, etc.)

**Only Closed-Won deals.** Lost and QO are excluded — they don't represent completed sales cycles.

### Section C: Lead Source Conversion Adjustment (Rows 28-36)

One row per Lead Source + Overall row.

- **Rows 28-29:** Section header ("LEAD SOURCE CONVERSION ADJUSTMENT") + description
- **Row 30:** Column headers — Lead Source | Win Rate Computed | Win Rate Override | Win Rate Effective | Adj Factor Computed | Adj Factor Override | Adj Factor Effective
- **Rows 31-35:** Marketing, Sales, Partner, Customer Success, Other
- **Row 36:** Overall

**Win Rate Computed:**
```
=IFERROR(COUNTIFS('Prepared Data'!$AU:$AU,1, 'Prepared Data'!$P:$P,"<Lead Source>", 'Prepared Data'!$AF:$AF,1, 'Prepared Data'!$AT:$AT,0) / COUNTIFS(OR('Prepared Data'!$AU:$AU=1,'Prepared Data'!$AV:$AV=1),TRUE, 'Prepared Data'!$P:$P,"<Lead Source>", 'Prepared Data'!$AF:$AF,1, 'Prepared Data'!$AT:$AT,0), "")
```

**Adj Factor Computed:**
```
=IFERROR(LS_Effective_Win_Rate / Overall_Effective_Win_Rate, "")
```
- `> 1.0` = converts better than average
- `< 1.0` = converts worse than average
- `= 1.0` = average (default fallback)

### Section D: Lead Source Time Adjustment (Rows 39-47)

Same layout as Section C.

- **Rows 39-40:** Section header ("LEAD SOURCE TIME ADJUSTMENT") + description
- **Row 41:** Column headers — Lead Source | Avg Days Computed | Avg Days Override | Avg Days Effective | Adj Factor Computed | Adj Factor Override | Adj Factor Effective
- **Rows 42-46:** Marketing, Sales, Partner, Customer Success, Other
- **Row 47:** Overall

**Avg Days Computed:**
```
=IFERROR(AVERAGEIFS('Prepared Data'!$AW:$BA, 'Prepared Data'!$P:$P, "<Lead Source>", 'Prepared Data'!$AU:$AU, 1, 'Prepared Data'!$AF:$AF, 1, 'Prepared Data'!$AT:$AT, 0), "")
```
(Uses the range across all Days S2-S6 to Close columns for an overall average cycle time)

**Adj Factor Computed:**
```
=IFERROR(LS_Effective_Avg_Days / Overall_Effective_Avg_Days, "")
```
- `> 1.0` = slower than average
- `< 1.0` = faster than average

### Section E: Forecast Category Quarterly Distribution (Rows 49-54)

Distributes forecasted value across quarters by Forecast Category. Commit and Renewal stay 100% this quarter and do not appear in this section.

- **Rows 49-50:** Section header ("FORECAST CATEGORY QUARTERLY DISTRIBUTION") + description
- **Row 51:** Column headers — Forecast Category | This Q % | Next Q % | Q+2 %
- **Rows 52-54:** Most Likely, Best Case, Omitted

| FC | This Q % | Next Q % | Q+2 % |
|----|----------|----------|-------|
| Most Likely | 20% | 40% | 40% |
| Best Case | 0% | 30% | 70% |
| Omitted | 0% | 0% | 100% |

**All percentage cells are direct-edit yellow cells** (columns B-D, rows 52-54). This Q % + Next Q % + Q+2 % must sum to 100%. Tier 3 BL-BN formulas reference these via INDEX-MATCH to split Ops Forecast Value across quarters.

**Distribution only applies to the current fiscal quarter.** Deals with Expected Close Month in this FQ get distributed per the table above. Deals closing in future FQs keep 100% of their value in their own quarter (BL=BH, BM=0, BN=0). The FQ boundary is computed from TODAY() in Section G.

**Note:** FC does NOT affect the conversion rate. The full model rate (Stage × Use Case × Lead Source) applies to all deals. FC only controls when forecasted value lands.

### Section F: Conversion Rate Overrides (Rows 56-60)

Fixed rates for Commit and Renewal deals that bypass the Stage × Use Case model.

- **Rows 56-57:** Section header + description
- **Row 58:** Column headers — Category | Conv Rate
- **Row 59:** Commit | yellow override cell (default 95%)
- **Row 60:** Renewal | yellow override cell (default 95%)

BD formula references `'Model & Inputs'!$B$59` for Commit and `$B$60` for Renewal instead of hardcoded values.

### Section G: Current Fiscal Quarter (Rows 62-64)

Computed boundary for the current fiscal quarter (FY Q1=Feb-Apr, Q2=May-Jul, Q3=Aug-Oct, Q4=Nov-Jan).

- **Row 62:** Section header
- **Row 63:** FQ Start — `=TEXT(EDATE(DATE(YEAR(EDATE(TODAY(),-1)),(CEILING(MONTH(EDATE(TODAY(),-1))/3,1)-1)*3+1,1),1),"YYYY-MM")`
- **Row 64:** FQ End — `=TEXT(EDATE(DATEVALUE(B63&"-01"),2),"YYYY-MM")`

Referenced by BL-BN formulas to limit FC distribution to current FQ deals only. Also used by BO/BP to compute fiscal (not calendar) next-quarter targets.

**Additional formatting for Model & Inputs:**
- Override columns: yellow background (#FFF2CC / RGB 255, 242, 204)
- Section headers: gray background + bold + 11pt
- Percentage cells: `0.0%` format
- Days cells: `#,##0` format

---

## Tier 3 Helper Columns

Written AFTER Model & Inputs tab is built. Exact cell references depend on model positions saved to `.context/model-positions.json`.

| Col | Header | Logic |
|-----|--------|-------|
| BB | Base Conv Rate | INDEX-MATCH against Section A Effective column, with sparse fallback |
| BC | LS Conv Adjustment | INDEX-MATCH against Section C Effective Adj Factor column |
| BD | Ops Conv Rate | Exception cascade + MIN(BB x BC, 1) |
| BE | Stage Start Date | Look up current stage's start date column |
| BF | Base Days to Close | INDEX-MATCH against Section B Effective column, with sparse fallback |
| BG | Ops Close Date | Exception cascade + MAX(BE + BF x LS Time Adj, TODAY()+30) |
| BH | Ops Forecast Value | Opp Value x Ops Conv Rate (blank for excluded and closed) |
| BI | Ops Close Month | TEXT(Ops Close Date, "YYYY-MM") |
| BJ | Expected Close Date | MAX(Rep Close Date, Ops Close Date) — conservative ops philosophy |
| BK | Expected Close Month | TEXT(Expected Close Date, "YYYY-MM") |
| BL | This Q Forecast | BH x FC This Q % from Section E (Commit/Renewal = 100%) |
| BM | Next Q Forecast | BH x FC Next Q % from Section E (Commit/Renewal = 0) |
| BN | Q+2 Forecast | BH x FC Q+2 % from Section E (Commit/Renewal = 0) |
| BO | Next Q Month | First month of the quarter after BK's quarter |
| BP | Q+2 Month | First month of two quarters after BK's quarter |

### Key Formula Patterns

**Base Conv Rate (BB) — with sparse fallback:**
```
=IF(OR(AL{n}=0,AG{n}=0),"",
  IFERROR(
    IF(INDEX('Model & Inputs'!$B$12:$N$16, MATCH("Stage "&AG{n},...), {uc_count_col}) >= Lookups!$N$2,
      INDEX('Model & Inputs'!$B$4:$P$8, MATCH("Stage "&AG{n},...), {uc_eff_col}),
      INDEX('Model & Inputs'!$P$4:$P$8, MATCH("Stage "&AG{n},...), 1)
    ), ""))
```
If sample count for Stage x Use Case < sparse threshold → fall back to Overall Effective column for that stage.

**Ops Conv Rate (BD) — exception cascade:**
```
=IF(AT{n}=1,"",IF(AL{n}=0,"",IF(U{n}="Commit",'Model & Inputs'!$B$59,IF(AK{n}=1,'Model & Inputs'!$B$60,
  IF(OR(BB{n}="",BC{n}=""),"",MIN(BB{n}*BC{n},1))))))
```
Priority: Excluded → Closed → Commit (Section F override) → Renewal (Section F override) → Model (capped at 1.0)

**Ops Close Date (BG) — exception cascade + floor:**
```
=IF(AT{n}=1,"",IF(AL{n}=0,"",IF(U{n}="Commit",IF(J{n}<>"",DATEVALUE(LEFT(J{n},10)),""),
  IF(OR(BE{n}="",BF{n}=""),"",MAX(BE{n}+BF{n}*IFERROR(INDEX('Model & Inputs'!$G$42:$G$46,MATCH(P{n},...)),1),TODAY()+30)))))
```
- Commit: keep current Close Date as-is
- Default model: Stage Start Date + (Base Days x LS Time Adj), floored at TODAY()+30

**Expected Close Date (BJ):**
```
=IF(BG{n}="","",IF(J{n}="",BG{n},MAX(DATEVALUE(LEFT(J{n},10)),BG{n})))
```
Conservative: takes the later of rep's close date and model's close date.

**This Q Forecast (BL) — quarterly distribution (current FQ only):**
```
=IF(BH{n}="","",IF(OR(U{n}="Commit",AK{n}=1),BH{n},
  IF(AND(BK{n}>='Model & Inputs'!$B$63,BK{n}<='Model & Inputs'!$B$64),
    BH{n}*IFERROR(INDEX('Model & Inputs'!$B$52:$B$54,MATCH(U{n},'Model & Inputs'!$A$52:$A$54,0)),1),
    BH{n})))
```
Commit/Renewal = 100% this Q. Deals in current FQ = This Q % from Section E. **Deals in future FQs = 100% (no distribution).** BM/BN use columns C/D respectively, returning 0 for future-FQ deals.

**Next Q Month (BO) — fiscal quarter:**
```
=IF(BM{n}=0,"",TEXT(EDATE(DATEVALUE('Model & Inputs'!$B$63&"-01"),3),"YYYY-MM"))
```
First month of the fiscal quarter after the current FQ. Since distribution only applies to current-FQ deals, BO/BP always target FQ+1 and FQ+2 from the current FQ start.

Write in 200-row batches with `USER_ENTERED`.

---

## Exceptions

| Condition | Ops Conv Rate | Ops Close Date | Q Distribution | Notes |
|-----------|--------------|----------------|----------------|-------|
| Is Excluded = 1 (LOI or Service Swap) | Excluded (blank) | — | — | Excluded from all model calculations |
| Deal is closed (Won/Lost/QO) | Blank | Blank | — | Historical deals not forecasted |
| Forecast Category = "Commit" | 95% | Current Close Date (as-is) | 100% this Q | High confidence — stays in current quarter |
| Opp Type = "Existing Business" (Renewal) | 95% | Model applies | 100% this Q | Renewals — no push-out |
| FC = "Most Likely" | Model applies | Model applies | 20/40/40 | Full model rate, distributed across 3 quarters |
| FC = "Best Case" | Model applies | Model applies | 0/30/70 | Full model rate, nothing this Q |
| FC = "Omitted" | Model applies | Model applies | 0/0/100 | Full model rate, all value pushed to Q+2 |

**Exception priority order:** Excluded → Closed → Commit → Renewal → Default model.

**Quarterly distribution percentages are override-able** in Model & Inputs Section E (yellow cells). FC does not affect conversion rate — only when value lands.

---

## Summary Layout

### Exec Summary Tab

Separate tab (index 0). Quarterly view for executives. Columns A-E: label, Last Q, This Q, Next Q, Next Next Q.

- **Row 1:** Title "EXEC SUMMARY — OPS FORECAST MODEL" (merged A1:E1, bold 12pt, gray bg)
- **Row 2:** CEO description (merged A2:E2, italic 9pt, wrap)
- **Row 3:** Blank
- **Row 4:** Dynamic quarter labels `="Q"&CEILING(MONTH(DATEVALUE(B5&"-01"))/3,1)&" "&LEFT(B5,4)`
- **Row 5:** Quarter-start months (hidden helper) — C5 = This Q start, B5/D5/E5 derived via EDATE
- **Row 6:** "OPS FORECAST" section header (bold, gray bg)
- **Row 7:** Ops Forecast — 5-term SUMIFS (3 months BL×BK + BM×BO + BN×BP per quarter)
- **Row 8:** % of Pipeline — `=IFERROR(B7/B18,0)` (Ops Forecast ÷ SFDC Everything)
- **Row 9:** Blank
- **Row 10:** "SALES FORECAST" section header
- **Row 11:** Commit — 3-SUMIFS quarterly sum of K where AH matches quarter months, U="Commit", NB filters
- **Row 12:** Commit + Most Likely — sum of Commit + Most Likely SUMIFS
- **Row 13:** Blank
- **Row 14:** "SFDC DATA" section header
- **Row 15:** Commit — `=B11` (references Sales row)
- **Row 16:** Most Likely — 3-SUMIFS quarterly sum, U="Most Likely"
- **Row 17:** Best Case — 3-SUMIFS quarterly sum, U="Best Case"
- **Row 18:** Everything — 3-SUMIFS quarterly sum, all NB pipeline by SFDC close date
- **Sheet ID:** 220432901

**Quarterly SUMIFS pattern** (for any metric using SFDC close date AH):
```
=SUMIFS(K, AH, QS, AL, 1, AT, "<>"&1, AR, 1, [FC filter])
+SUMIFS(K, AH, TEXT(EDATE(DATEVALUE(QS&"-01"),1),"YYYY-MM"), ...)
+SUMIFS(K, AH, TEXT(EDATE(DATEVALUE(QS&"-01"),2),"YYYY-MM"), ...)
```
Where QS = quarter-start month from row 5.

**Ops Forecast quarterly formula** (distributed, no ÷3 since summing full quarter):
```
=SUMIFS(BL, BK, month1, NB) + SUMIFS(BL, BK, month2, NB) + SUMIFS(BL, BK, month3, NB)
+SUMIFS(BM, BO, QS, NB)
+SUMIFS(BN, BP, QS, NB)
```

### Forecast Summary Tab (Rows 1-18)

- **Row 1:** Column headers — NB = New Business | then 7 dynamic month columns (B-H) + "Beyond 6mo" (I) + "Total" (J)
  - Month columns use `=TEXT(EDATE(TODAY(),N),"YYYY-MM")` for dynamic months (current through +6)

| Row | Metric | Formula Basis |
|-----|--------|---------------|
| 2 | Pipeline by Close Date | `=SUMIFS(K, AH=month, AL=1, AT<>1, AR=1)` |
| 3 | Commit by Close Date | `=SUMIFS(K, AH=month, AL=1, AT<>1, AR=1, U="Commit")` |
| 4 | Commit and Most Likely by Close Date | `=SUMIFS(K, AH=month, AL=1, AT<>1, AR=1, U="Commit") + SUMIFS(K, AH=month, ..., U="Most Likely")` |
| 6 | Ops Adjusted Pipeline (Expected Close) | `=SUMIFS(K, BK=month, AL=1, AT<>1, AR=1)` |
| 7 | Ops Adjusted Commit | `=SUMIFS(K, BK=month, AL=1, AT<>1, AR=1, U="Commit")` |
| 8 | Ops Adjusted Commit and Most Likely | Same pattern filtered by Commit + Most Likely |
| 10 | **Ops Weighted Forecast (Expected Close)** | **Distributed** — see below |
| 11 | Ops Forecast as % of Pipeline | `=Row10 / Row2` |
| 13 | NB Weighted Pipeline (Expected Close) | Uses weighted amount by BK |
| 14 | Ops % of Weighted | `=Row10 / Row13` |
| 17 | EB/Renewal Pipeline (Expected Close) | `=SUMIFS(K, BK=month, AL=1, AT<>1, AK=1)` |
| 18 | EB/Renewal Ops Forecast (Expected Close) | `=SUMIFS(BH, BK=month, AL=1, AT<>1, AK=1)` — no distribution (renewals = 100% this Q) |

Rows 5, 9, 12, 15-16 are spacers/headers.

**Row 10 — Distributed Ops Weighted Forecast formula:**
```
=SUMIFS(BL, BK=month, AL=1, AT<>1, AR=1)
 +SUMIFS(BM, BO=QS(month), AL=1, AT<>1, AR=1)/3
 +SUMIFS(BN, BP=QS(month), AL=1, AT<>1, AR=1)/3
```
Where `QS(month)` = quarter-start of the target month:
```
=TEXT(DATE(LEFT(month,4)*1,(CEILING(MID(month,6,2)*1/3)-1)*3+1,1),"YYYY-MM")
```
- Term 1: This Q values in their original Expected Close Month
- Term 2: Next Q values targeting this quarter, spread evenly across 3 months (÷3)
- Term 3: Q+2 values targeting this quarter, spread evenly across 3 months (÷3)

Beyond 6mo (col I) = total BH - SUM(B29:H29). Total (col J) = SUM(B29:I29).

### Sections 2-5: Breakdowns

Each breakdown section: 3 rows per dimension value (Pipeline, Ops Forecast, Ops %).

| Section | Dimension | Source Column | Notes |
|---------|-----------|--------------|-------|
| 2 | Rep | Full Name (E) | Read distinct values from open non-excluded deals |
| 3 | Use Case | Consolidated Use Case (AE) | |
| 4 | Lead Source | Lead Source Attribution (P) | |
| 5 | Sales Play | Sales Play (R) | |

Cache distinct values to `.context/ops-forecast-breakdown-values.json`.

---

## Audit Tab

- **B1:** Data validation dropdown with month values (YYYY-MM format, 7 months from current)
- **Row 3:** 16 column headers:
  Opp Name | Account | Rep | Value | NB/Renewal | Use Case | Lead Source | Stage | Close Date | FC | Base Conv Rate | LS Adj | Ops Conv Rate | Ops Close Date | Ops Forecast Value | Appears Because
- **A4:** FILTER formula — open non-excluded deals where Close Month = B1 OR Expected Close Month = B1
  - Uses CHOOSECOLS to select specific columns from Prepared Data
  - Sort by Ops Forecast Value descending
- **"Appears Because" column:** `=IF(AND(AH=B1, BL=B1), "Both", IF(AH=B1, "Pipeline Close", "Ops Close"))`

### Data Audit Tab

Stage x Use Case drill-down for investigating model inputs.

- **B1:** Data validation dropdown — Stage values ("Stage 2" through "Stage 6")
- **D1:** Data validation dropdown — Use Case values (from Lookups!E2:E12 distinct)
- **Row 3:** Column headers:
  Opp Name | Account | Rep | Opp Value | Lead Source | Stage | Close Date | Outcome (Won/Lost/QO) | Days to Close
- **A4:** FILTER formula — historical resolved deals (`AF=1`) where Reached Stage = selected stage AND Use Case = selected use case
  - Uses CHOOSECOLS to select specific columns from Prepared Data
  - Sort by Close Date descending
- **Footer rows (below FILTER output):**
  - Total Deals: `=COUNTA(A4:A)`
  - Won: `=COUNTIF(H4:H, "Won")`
  - Win Rate: `=Won / Total`
  - Avg Days to Close: `=AVERAGEIF(I4:I, "<>", I4:I)` (non-blank Days to Close values)

---

## Sanity Checks

| Check | Rule | Threshold | Severity | Phase |
|-------|------|-----------|----------|-------|
| Row count | Prepared Data rows = Raw Data rows | Exact match | hard-fail | data-quality |
| Pipeline Category coverage | No blank Pipeline Category where Stage is non-blank | 0 blanks | hard-fail | data-quality |
| Use Case distribution | All deals categorized; note "Other" count | All categorized | info | data-quality |
| Historical deal count | SUM of Is Historical column | >= 20 | hard-fail | data-quality |
| Stage start date coverage | Open deals with all Reached S2-S6 = 0 | Note count | info | data-quality |
| Formula errors (data) | No #REF!, #N/A, #VALUE!, #DIV/0! in Tiers 1-2 | 0 errors | hard-fail | data-quality |
| Opp Value sanity | No negative values or $0 on won deals | Flag any | warning | data-quality |
| LOI identification | Count excluded deals | Note count | info | data-quality |
| Ops Conv Rate range | All values 0-1 (or exactly 0.95 for exceptions) | Hard fail if > 1.0 | hard-fail | model-review |
| Ops Close Date floor | All dates >= TODAY()+30 (except Commit) | Hard fail if violated | hard-fail | model-review |
| Total Ops Forecast <= Total Pipeline | Model shouldn't inflate pipeline | Warning if > 100% | warning | model-review |
| LS Adjustment range | All adj factors 0.3-3.0 | Flag extreme values | warning | model-review |
| Model coverage | Every open non-excluded deal has Ops Conv Rate | Hard fail if missing | hard-fail | model-review |
| Sparse cell report | List Stage x UseCase cells where count < threshold | Informational | info | model-review |
| Section cross-check | Summary Section 1 totals = sum of Section 2 (by Rep) | Hard fail if mismatch | hard-fail | model-review |
| Formula errors (all) | Zero #REF!, #N/A, #VALUE! across all tabs | 0 errors | hard-fail | model-review |

---

## Definitions Template

See `definitions-template.md` in this directory. Used by Review agent (Stage 4) to populate the Definitions tab.

---

## Writing Strategy

- **Batch size:** 200 rows per write (larger batches may timeout)
- **valueInputOption:** `USER_ENTERED` for all formula columns; `RAW` for Lookups
- **Tier order:** Tier 1 complete → Tier 2 complete → Model tab built → Tier 3 complete
- **Date handling:** Raw dates are text ("2025-02-08 15:18:35"). Use `DATEVALUE(LEFT(cell,10))` in formulas.
- **Delays:** 1-2 seconds between batches to avoid rate limits
- **Raw data:** Live via IMPORTRANGE — no manual ingest needed. When rebuilding the model, skip raw data ingestion and start at Tier 1 helper columns.
