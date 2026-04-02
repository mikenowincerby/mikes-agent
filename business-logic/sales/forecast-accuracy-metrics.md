# Forecast Accuracy Metrics

Definitions, formulas, and sanity checks for forecast accuracy analysis. Referenced by `agents/pipelines/sales-analytics/1-planner.md`, `agents/pipelines/sales-analytics/3-analysis.md`, and `agents/pipelines/sales-analytics/4-review.md`.

---

## Forecast Category Values

Six values used in the Forecast Category field:

| Value | Meaning |
|-------|---------|
| Pipeline | In pipeline, not yet forecasted |
| Best Case | Possible but not highly confident |
| Most Likely | High probability of closing |
| Commit | Rep committed to deliver |
| Closed | Deal has closed |
| Omitted | Excluded from forecast |

---

## Forecast Levels

Cumulative levels define what counts as "the forecast" at different confidence bands:

| Forecast Level | Included Categories | Interpretation |
|----------------|-------------------|----------------|
| Commit | Commit | Tightest — what the rep committed to deliver |
| Commit + Most Likely | Commit, Most Likely | High-confidence deals |
| Commit + Most Likely + Best Case | Commit, Most Likely, Best Case | Everything the rep thinks has a real shot |

---

## Three Accuracy Dimensions

Calculated per forecast level, per time period, per cut (rep, use case, lead source):

| Metric | Formula | What It Tells You |
|--------|---------|-------------------|
| **Dollar Accuracy** (primary) | `Actual Closed Won $ / Forecasted $` | Revenue calibration — called $1M, closed $800K = 80% |
| **Count Accuracy** | `Actual Closed Won count / Forecasted deal count` | Volume calibration — called 10 deals, closed 11 = 110% |
| **Deal Accuracy** | `Forecasted deals that actually closed / Total deals forecasted` | Precision — called 10 deals, 7 of those closed = 70% |

### Definitions

- **"Forecasted"** means: as of the forecast snapshot date, the opp had a Forecast Category included in the forecast level AND a Close Date falling within the target period.

- **"Actual Closed Won"** means: as of the actuals snapshot date, the opp's `Is Closed Won (at actuals)` helper column is TRUE (derived from Stage snapshot → Pipeline Category → "Won") AND `Close Date In Period (at actuals)` is TRUE (using the Close Date from the actuals snapshot, not the current/live Close Date). **This includes ALL closed-won deals in the period, not just those that were in the forecast.** Dollar and Count Accuracy measure total actual performance vs total forecast.

- **"Forecasted deals that actually closed"** means: opps that meet the "Forecasted" definition AND also meet the "Actual Closed Won" definition. **This is a subset** — only deals that were both forecasted AND won.

### Google Sheets Formulas

All division formulas wrapped in `IFERROR(..., "N/A")` to handle zero-denominator cases.

**Dollar Accuracy (per forecast level):**
```
=IFERROR(
  SUMIFS(Amount at actuals, Is Closed Won at actuals, TRUE, Close Date In Period at actuals, TRUE)
  / SUMIFS(Amount at forecast, In Forecast: <level>, TRUE),
  "N/A"
)
```

**Count Accuracy (per forecast level):**
```
=IFERROR(
  COUNTIFS(Is Closed Won at actuals, TRUE, Close Date In Period at actuals, TRUE)
  / COUNTIFS(In Forecast: <level>, TRUE),
  "N/A"
)
```

**Deal Accuracy (per forecast level):**
```
=IFERROR(
  COUNTIFS(Forecasted & Won: <level>, TRUE)
  / COUNTIFS(In Forecast: <level>, TRUE),
  "N/A"
)
```

Where `<level>` is one of: `Commit`, `Commit + Most Likely`, `Commit + Most Likely + Best Case`.

**Breakdown by cut:** Same formulas with additional SUMIFS/COUNTIFS criteria for rep, use case, or lead source columns.

---

## Time Definitions

| Grain | Forecast Snapshot | Actuals Snapshot | Example |
|-------|------------------|-----------------|---------|
| **Quarterly** (primary) | Start of quarter | Start of next quarter | FQ1 2027 (Feb 1 – Apr 30): Forecast = Feb 1 snapshot, Actuals = May 1 snapshot |
| **Monthly** | Start of month | Start of next month | March 2027: Forecast = Mar 1 snapshot, Actuals = Apr 1 snapshot |

**Fiscal calendar:** Follows existing rules from `metrics.md` — FY starts Feb 1, FY = calendar year + 1, Jan belongs to prior FY's Q4.

---

## Category Movement

Track how each opp's Forecast Category changed between snapshots within a quarter:

- **Output:** Deal list with Opp ID, opp name, rep, amount, category at each monthly snapshot, final outcome (Stage at actuals snapshot)
- **Use case:** "Show me deals that dropped from Commit to Pipeline during Q1"
- **Implementation:** FILTER/SORT formulas on category movement helper columns in Prepared Data

---

## Sanity Checks

Run by Agent 4 (Review) after analysis is complete.

| Check | Threshold | Action if Failed |
|-------|-----------|-----------------|
| Dollar Accuracy | 0% – 200% is reasonable | Flag anything outside range |
| Deal Accuracy | Must be <= 100% | Cannot close more deals than forecasted from the same set — investigate |
| Count Accuracy | Can exceed 100% (unforecasted deals can close) | Flag > 300% |
| Forecasted $ | Must be > 0 for any period analyzed | If 0, the forecast level had no deals in forecast — report, do not compute accuracy |
| Snapshot availability | Both forecast and actuals snapshots must exist | If missing, analysis cannot run — report which snapshot is missing |
