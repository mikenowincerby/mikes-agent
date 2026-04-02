# Ops Forecast — Definitions Template

Content for the Definitions tab (Tab index 7). Written by the Review agent (Stage 4).

## Section 1: Methodology Overview (rows 1-8)

Plain-English summary of what the model does:
- Uses historical conversion rates (won / resolved deals) by stage and use case
- Adjusts for lead source performance (multiplicative factor)
- Distributes forecasted value across quarters based on FC confidence level (FC does not cap the conversion rate)
- Produces per-deal Ops Conv Rate, Ops Close Date, and distributed forecast values
- Replaces subjective weighting with data-driven historical patterns
- All values are live Google Sheets formulas — model self-updates when data refreshes

## Section 2: FAQ — Likely CEO Questions (rows 10-30)

| Question | Answer |
|----------|--------|
| Does average sales cycle only look at won deals? | Yes — lost/QO excluded from timing, included in conversion rate denominator |
| What data feeds this model? | Daily Salesforce refresh (Daily Data sheet, Opportunity tab) |
| How is conversion rate calculated? | Won / (Won + Lost + QO) by stage and use case, for deals that reached that stage |
| What happens with little data? | If Stage x Use Case has < 5 resolved deals, falls back to Overall rate for that stage |
| Can I override the model? | Yes — yellow cells on Model & Inputs tab. Clearing reverts to computed value |
| How are Commit deals treated? | 95% conv rate, keep current close date as-is, 100% value this quarter |
| How are renewals treated? | 95% conv rate, model applies to timing, 100% value this quarter |
| How does Forecast Category affect the model? | FC controls when forecasted value lands, not the conversion rate. The full model rate applies regardless of FC. Most Likely: 20% this Q / 40% next Q / 40% Q+2. Best Case: 0/30/70. Omitted: 0/0/100. Commit and Renewal stay 100% in their quarter. All percentages are override-able in Model & Inputs Section E. |
| What does Lead Source adjustment do? | Multiplicative factor: LS win rate / overall win rate. >1 = better, <1 = worse |
| What if a deal's predicted date is in the past? | Floored at TODAY + 30 days |
| How is Pipeline different from Ops Forecast? | Pipeline = rep's close date and full value. Ops Forecast = model's close date, probability-weighted value, distributed across quarters by FC. |
| What are excluded deals? | LOI and Service Swap deals are excluded from all model calculations |
| What does the Exec Summary show? | Quarterly rollup (Last Q, This Q, Next Q, Next Next Q) of NB metrics: Ops Forecast with % of pipeline, Sales Forecast (Commit, Commit+ML), and raw SFDC pipeline by FC category. Quarters are dynamic based on today's date. |

## Section 3: Metric Definitions (rows 32-50)

One row per metric: Name | Definition | Formula | Source Column

Key metrics:
- Base Conv Rate, LS Conv Adjustment, Ops Conv Rate
- Base Days to Close, LS Time Adjustment, Ops Close Date
- Ops Forecast Value, This Q Forecast, Next Q Forecast, Q+2 Forecast
- Expected Close Date, Expected Close Month, Next Q Month, Q+2 Month
- NB Pipeline, Ops Weighted Forecast, Ops % of Pipeline
- EB/Renewal Pipeline, EB/Renewal Ops Forecast

## Section 4: Data Source & Refresh (rows 52-58)

- Source: Daily Data sheet (ID: `$DAILY_DATA`), Opportunity tab
- Historical training window: Deals closed since January 2025
- Computation method: "All values are Google Sheets formulas — no Python compute"
- Override instructions: "Edit yellow cells on Model & Inputs tab. Clear to revert to computed value."
- Sparse threshold: Configurable in Lookups!N2 (default: 5)

## Section 5: Assumptions & Limitations (rows 60-70)

- Past performance does not guarantee future results
- Stage progression patterns assumed stable over training window
- Sparse segments (few historical deals) are less precise — check sample size matrix
- LOI and Service Swap deals excluded entirely
- Commit deals bypass the model (95% rate, keep close date, 100% this Q)
- FC caps assume rep forecast category reflects deal confidence accurately
- Quarterly distribution percentages are policy inputs, not data-derived — adjust in Section E
- Pushed-out value spreads evenly across the 3 months of the target quarter
- Overdue floor (TODAY+30) is a simplification — true timing may vary
- Lead Source adjustment assumes LS performance is independent of stage/use case
