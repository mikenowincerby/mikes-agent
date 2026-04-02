# Forecast Data Prep Rules

Rules for preparing data for forecast accuracy analysis. Referenced by `agents/pipelines/sales-analytics/2-data-prep.md`. For standard sales data prep, see `data-prep-rules.md`. For field definitions, see `data-dictionary.md`.

**Principle:** Follows the same formula-first, tier-ordered approach as standard data prep per `../_shared/formula-rules.md`.

---

## Data Sources

| Source | Sheet ID | Tab | Purpose |
|--------|----------|-----|---------|
| Daily Data | `$DAILY_DATA` | Opportunity | Deal attributes (rep, use case, lead source, etc.) and current state |
| Daily Data | `$DAILY_DATA` | Forecast Accuracy | Point-in-time snapshot data (Amount, Forecast Category, Close Date, Stage at each snapshot date) |

---

## Analysis Sheet Creation

Forecast accuracy analysis follows the standard sales-analytics flow. Agent 2 creates a new analysis sheet using the `create-analysis-sheet` skill with this tab structure:

| Tab | Purpose |
|-----|---------|
| Summary | Accuracy metrics roll-up |
| Raw Data | Snapshot data copied from the Forecast Accuracy tab |
| Prepared Data | Helper columns built via formulas |
| Analysis | Accuracy breakdowns and deal lists |
| Lookups | Fiscal Period Mapping + Stage Mapping |
| Definitions | Metric definitions with cell references |

---

## Prep Steps

### Step 1: Identify Relevant Snapshots

Based on the target time period, determine which snapshot columns to use:

| Analysis Period | Forecast Snapshot | Actuals Snapshot |
|----------------|------------------|-----------------|
| Quarterly (e.g., FQ1 2027: Feb–Apr) | Feb 1 snapshot | May 1 snapshot |
| Monthly (e.g., March 2027) | Mar 1 snapshot | Apr 1 snapshot |

**For category movement analysis:** Also enumerate all monthly snapshot dates that fall within the analysis period. For quarterly analysis, this yields up to 3 monthly snapshots mapped chronologically to `Cat (snapshot 1)`, `Cat (snapshot 2)`, `Cat (snapshot 3)`. If any monthly snapshot is missing, flag the gap in the data quality check.

### Step 2: Create Analysis Sheet

Use `create-analysis-sheet` skill with:
- `sourceSheetId`: `$DAILY_DATA`
- `sourceRange`: Forecast Accuracy tab, columns for Opp ID + relevant snapshot columns
- `analysisName`: e.g., "Forecast Accuracy FQ1 2027"

### Step 3: Copy Snapshot Data to Raw Data

Copy the relevant snapshot columns (forecast + actuals) for all opps to the Raw Data tab. Include all 4 fields per snapshot: Amount, Forecast Category, Close Date, Stage.

### Step 4: Copy Lookups

Populate the Lookups tab with:
- Stage Mapping (same as standard analysis, from `data-dictionary.md`)
- Fiscal Period Mapping (Month Number → Fiscal Quarter / FY Add)

### Step 5: Join with Opportunity Attributes

Bring in deal attributes from the Opportunity tab via Opp ID lookup:
- Full Name (rep)
- Primary Use Case → Use Case (Simplified) via Use Case Mapping
- Lead Source Attribution

### Step 6: Write Helper Columns in Prepared Data

All formulas, strict tier dependency order per `../_shared/formula-rules.md`. Row-by-row, no ARRAYFORMULA.

#### Tier 1 Helpers (base lookups — no dependencies on other helpers)

| Column | Header | Source |
|--------|--------|--------|
| — | `Forecast Cat (at forecast)` | Forecast Category from the forecast snapshot column |
| — | `Forecast Cat (at actuals)` | Forecast Category from the actuals snapshot column |
| — | `Amount (at forecast)` | Amount from the forecast snapshot column |
| — | `Amount (at actuals)` | Amount from the actuals snapshot column |
| — | `Close Date (at forecast)` | Close Date from the forecast snapshot column |
| — | `Close Date (at actuals)` | Close Date from the actuals snapshot column |
| — | `Stage (at forecast)` | Stage from the forecast snapshot column |
| — | `Stage (at actuals)` | Stage from the actuals snapshot column |
| — | `Rep` | Full Name from Opportunity tab via Opp ID lookup |
| — | `Use Case` | Use Case (Simplified) from Opportunity tab via Opp ID + Lookups |
| — | `Lead Source` | Lead Source Attribution from Opportunity tab via Opp ID lookup |

#### Tier 2 Helpers (derived from Tier 1)

| Column | Header | Formula Logic |
|--------|--------|--------------|
| — | `Pipeline Category (at actuals)` | VLOOKUP Stage (at actuals) against Lookups Stage mapping |
| — | `Close Date In Period (at forecast)` | Boolean: Close Date (at forecast) >= period start AND < period end |
| — | `Close Date In Period (at actuals)` | Boolean: same check on Close Date (at actuals) |
| — | `Is Closed Won (at actuals)` | Boolean: Pipeline Category (at actuals) = "Won" |
| — | `In Forecast: Commit` | Boolean: Forecast Cat (at forecast) = "Commit" AND Close Date In Period (at forecast) = TRUE |
| — | `In Forecast: Commit + Most Likely` | Boolean: Forecast Cat (at forecast) IN ("Commit", "Most Likely") AND Close Date In Period (at forecast) = TRUE |
| — | `In Forecast: Commit + Most Likely + Best Case` | Boolean: Forecast Cat (at forecast) IN ("Commit", "Most Likely", "Best Case") AND Close Date In Period (at forecast) = TRUE |

**Note on "IN" logic:** Google Sheets doesn't have an IN operator. Use OR: `=AND(OR(cell="Commit", cell="Most Likely"), close_date_in_period_cell=TRUE)`

#### Tier 3 Helpers (derived from Tier 2)

| Column | Header | Formula Logic |
|--------|--------|--------------|
| — | `Forecasted & Won: Commit` | Boolean: In Forecast: Commit = TRUE AND Is Closed Won (at actuals) = TRUE AND Close Date In Period (at actuals) = TRUE |
| — | `Forecasted & Won: Commit + Most Likely` | Boolean: In Forecast: Commit + Most Likely = TRUE AND Is Closed Won (at actuals) = TRUE AND Close Date In Period (at actuals) = TRUE |
| — | `Forecasted & Won: Commit + Most Likely + Best Case` | Boolean: In Forecast: Commit + Most Likely + Best Case = TRUE AND Is Closed Won (at actuals) = TRUE AND Close Date In Period (at actuals) = TRUE |

#### Category Movement Helpers (for category drift analysis)

| Column | Header | Formula Logic |
|--------|--------|--------------|
| — | `Cat (snapshot 1)` | Forecast Category at first monthly snapshot in period |
| — | `Cat (snapshot 2)` | Forecast Category at second monthly snapshot (if exists) |
| — | `Cat (snapshot 3)` | Forecast Category at third monthly snapshot (if exists) |
| — | `Category Changed?` | Boolean: Cat (snapshot 1) <> Cat (snapshot N) where N = last available snapshot |

### Step 7: Data Quality Checks

Run after all helper columns are written:

| Check | How | Threshold |
|-------|-----|-----------|
| Snapshot columns exist | Verify forecast and actuals snapshot date columns are in Raw Data | Both must exist |
| Opp ID coverage | Compare Opp IDs in Prepared Data vs Forecast Accuracy tab | No missing IDs |
| Valid Forecast Categories | Distinct values in Forecast Cat columns | Only: Pipeline, Best Case, Most Likely, Commit, Closed, Omitted |
| Valid Stage values | Distinct values in Stage (at actuals) | Must match `metrics.md` stage list (1-6, 9, 10, 11) |
| Row count match | Raw Data rows = Prepared Data rows | Must be equal |

Present data quality report to user. **Wait for acknowledgment before proceeding to analysis.**
