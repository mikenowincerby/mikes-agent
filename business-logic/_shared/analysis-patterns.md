# Analysis Patterns — Reasoning Scaffolding

How a RevOps lead thinks about what to prepare alongside a core analysis. Apply metrics and dimensions from `../sales/metrics.md` only.

---

## Analytical Lenses

For each lens, ask: **"Would this view change a decision or surface a risk the user hasn't considered?"** Include only if yes.

### 1. Decomposition
- **Trigger/Move:** When user asks for an aggregate, slice it by a segment dimension (Opportunity Type, Lead Source Attribution, Use Case, Company Segment).
- **Why:** Totals hide concentration risk — if 80% of pipeline is one use case, the exec needs to know.

### 2. Comparison
- **Trigger/Move:** When user asks for a metric in a specific period, add the same metric for the prior period (prior quarter, prior year, same quarter last year).
- **Why:** A number without context is meaningless. "$500K pipeline created" means nothing until you know last quarter was $800K.

### 3. Velocity
- **Trigger/Move:** When user asks about bookings or pipeline outcomes, add Average Sales Cycle or stage conversion rates for the same filters.
- **Why:** Revenue without velocity context misses process health. Fast cycles with low win rates suggest different problems than slow cycles with high win rates.

### 4. Composition
- **Trigger/Move:** When user asks for a summary metric, add a deal list showing top/bottom individual deals driving the aggregate.
- **Why:** Aggregates hide outlier dependence. If one $200K deal is 40% of bookings, the user should see that immediately.

### 5. Funnel
- **Trigger/Move:** When user asks about pipeline or conversion, add stage-to-stage conversion or PipeCreate → Won funnel for the same filters.
- **Why:** Pipeline totals without funnel shape miss where deals are getting stuck.

---

## Available Building Blocks

### Metrics (from metrics.md)

- **Volume:** NB Bookings Total$, EB Bookings Total$, PipeCreate Total$, Lost Total$, Expansion ARR, Net ARR
- **Count:** NB Bookings Count, PipeCreate Count, New Logo Count
- **Average:** NB ADS, PipeCreate ADS
- **Rate:** Win Rate, Stage-to-Stage Conversion
- **Duration:** Average Sales Cycle

### Dimensions (from metrics.md)

- **Time:** Week, Month, Fiscal Quarter, Fiscal Year
- **Date anchor:** Close Date, Created Date, Stage 2 Entry Date
- **Segment:** Opportunity Type, Lead Source Attribution, Use Case, Sales Play, Company Segment, Pipeline Category, CSM Sourced

### Marketing Metrics (from ../marketing/metrics.md)

- **Volume:** Total Members, Net New Leads, MQLs, SQLs, Opportunities, Won Opportunities
- **Value:** Opportunity Value, Won Value, Campaign Cost
- **Rate:** MQL Conversion Rate, SQL Conversion Rate, Opp Conversion Rate, Campaign ROI
- **Cost:** CPA, Cost per MQL, Cost per SQL
- **Score:** Average Sort Score

### Marketing Dimensions (from ../marketing/metrics.md)

- **Campaign:** Campaign Name, Campaign Type, Campaign Type Category
- **Time:** Start Mo, Start Qtr, Start Fiscal (by campaign start date)
- **Person:** Origin Type (Lead/Contact), Lifecycle Stage, Department, Level
- **Account:** Account Name (via Lookups join)
- **Engagement:** New vs Previously Engaged, Sort Score

---

## Reasoning Guardrails

- **Relevance over comprehensiveness.** 3 sharp recommendations beat 5 generic ones.
- **No invented metrics.** Every recommendation must map to a metric and dimension in `../sales/metrics.md`.
- **Explain the decision it informs.** "By Lead Source" is not a reason. "To see if Marketing pipeline is keeping pace" is.
- **Respect scope.** If the user's ask is narrow, keep follow-ups tightly related.
- **Avoid redundancy.** If the core ask already includes a dimension, don't recommend it again.

---

## Forecast Accuracy Lenses

Apply when the analysis involves forecast accuracy. Include only if it would change a decision or surface a risk.

### 6. Accuracy Trend
- **Trigger/Move:** When user asks about forecast accuracy for a specific period, show the same metric across multiple periods.
- **Why:** A single quarter's accuracy is a data point; the trend reveals whether the team is calibrating or drifting.

### 7. Category Drift
- **Trigger/Move:** When user asks about forecast accuracy or deal outcomes, show category movement (Commit → Pipeline, Best Case → Closed, etc.).
- **Why:** Aggregate accuracy hides deal-level churn. A team can be 100% accurate on dollars while having massive offsetting movements underneath.

### 8. Forecast Calibration
- **Trigger/Move:** When user asks about rep/team accuracy, compare accuracy by rep across multiple periods for systematic bias.
- **Why:** Consistent over-forecasting is a predictable bias you can adjust for; wild swings indicate a qualification problem.

---

## Marketing Lenses

Apply when the analysis involves marketing campaigns, lead generation, or attribution. Include only if it would change a decision.

### 9. Funnel Conversion
- **Trigger/Move:** When user asks about campaign performance, show full funnel: Members → MQLs → SQLs → Opps → Won with conversion rates at each step.
- **Why:** The funnel shows where drop-off occurs — a campaign with 1000 members and 2 MQLs has a different problem than one with 100 MQLs and 0 SQLs.

### 10. Campaign Comparison
- **Trigger/Move:** When user asks about a specific campaign, compare against others of the same type/category.
- **Why:** "$50 CPA" means nothing without the category average. Benchmarking surfaces above/below expectations.

### 11. Lead Quality
- **Trigger/Move:** When user asks about lead generation or MQLs, add Sort Score distribution and opportunity conversion rate.
- **Why:** 100 MQLs with 0 conversions is worse than 10 MQLs with 3 opportunities. Quality prevents celebrating volume that doesn't convert.

### 12. Attribution Mix
- **Trigger/Move:** When user asks about marketing's contribution to pipeline, show pipeline by campaign type and first-touch vs multi-touch.
- **Why:** If 90% of attributed pipeline comes from one campaign type, that's concentration risk.
