# Sales Metrics — Definitions, Formulas & Dimensions

Single source of truth for how Cerby defines and calculates sales metrics. Referenced by `agents/pipelines/sales-analytics/` and multiple skills.

## Table of Contents
- [Fiscal Calendar](#fiscal-calendar)
- [Sales Stages & Pipeline Categories](#sales-stages--pipeline-categories)
- [Opportunity Types & Value Fields](#opportunity-types--value-fields)
- [Pipeline Creation Metrics](#pipeline-creation-metrics)
- [Booking Metrics](#booking-metrics)
- [Conversion & Velocity Metrics](#conversion--velocity-metrics)
- [Dimensions](#dimensions)
- [Sanity Check Rules](#sanity-check-rules)

---

## Fiscal Calendar

| Rule | Definition |
|------|-----------|
| Fiscal Year | Calendar year + 1. Feb 2025 = FY2026. |
| FY Start | February 1 |
| FY End | January 31 |
| Q1 | February – April |
| Q2 | May – July |
| Q3 | August – October |
| Q4 | November – January |

**January edge case:** January belongs to the *prior* fiscal year's Q4. Jan 2026 = FY2026 Q4 (not FY2027).

**Deriving fiscal period from a date:**
- If month >= 2: FY = calendar year + 1
- If month == 1: FY = calendar year (Jan 2026 → FY2026)
- Quarter mapping: Feb-Apr → Q1, May-Jul → Q2, Aug-Oct → Q3, Nov-Jan → Q4
- FY Add: January = 0, all other months = 1 (i.e., FY = calendar year + FY Add)

**Quarter Label format:** `FY2026 Q1` (always include FY prefix)

---

## Sales Stages & Pipeline Categories

### Stage Progression

| Stage | Avg Days | 33% Buffer | Cumulative Days | Category | Detail Category |
|-------|----------|-----------|-----------------|----------|-----------------|
| 1. Lead Verification | 16 | 22 | 16 | PrePipeline | PrePipeline |
| 2. Discovery | 24 | 32 | 40 | Pipeline | Early Pipeline |
| 3. Scoping | 25 | 34 | 65 | Pipeline | Early Pipeline |
| 4. Solution Validation \| Trial | 23 | 31 | 88 | Pipeline | Mid Pipeline |
| 5. Solutions Proposal | 32 | 43 | 120 | Pipeline | Mid Pipeline |
| 6. Negotiate and Close | 43 | 58 | 163 | Pipeline | Late Pipeline |
| 9. Closed-Won | — | — | — | Won | Won |
| 10. Closed-Lost | — | — | — | Lost | Lost |
| 11. Qualified-Out | — | — | — | QualifiedOut | QualifiedOut |

### Pipeline Threshold

**Stage 2 Entry Date** is when an opportunity becomes pipeline. Before Stage 2, it is a Lead (PrePipeline). Use `Stage 2 Entry Date` or `Stage 2. Discovery Start Date` as the pipeline creation date anchor.

### Cohort Scoping Defaults

When building a pipeline analysis cohort, apply these defaults unless the user explicitly requests otherwise:

| Analysis Type | Include Stages | Rationale |
|--------------|---------------|-----------|
| Pipeline analysis | 2-6 (Early/Mid/Late Pipeline) + 9 (Won) + 10 (Lost) | Active + resolved pipeline. QualifiedOut (11) are excluded — they never became real pipeline. |
| Win/loss analysis | 9 (Won) + 10 (Lost) | Only closed deals with outcomes. |
| Full funnel / stage distribution | 2-6, 9, 10, 11 | All stages including QO — shows where deals exit. |
| Pipeline creation (PipeCreate) | 2-6, 9, 10, 11 | Everything that entered Stage 2+ in the period, regardless of current state. |

**Default for "pipeline analysis" requests:** Exclude QualifiedOut. QO deals inflate Total Pipeline (they carry Amount but will never close) and contaminate deal lists with dead deals. If QO deals are included, the analysis type is "full funnel" — label it as such and add a note that QO deals are included.

**Deal list scoping:** Deal lists (Top 10, deal detail) should exclude terminal states (QualifiedOut, Closed-Lost) unless the analysis explicitly covers those states (e.g., "show me lost deals"). A "Top 10 deals" list should show deals that can still be acted on or that closed successfully.

**Average Deal Size:** Exclude QualifiedOut from ADS calculations. QO deals distort the average because they never went through pricing/negotiation — their Amount reflects an estimate, not a validated deal size.

---

## Opportunity Types & Value Fields

### New Business
- New customer deals
- **Value field:** `Amount`
- Use `Amount` for bookings, ADS, pipeline value

### Existing Business
- Includes renewals, expansions, and contractions — all under one Opportunity Type
- **Value fields:**
  - `Amount` — total deal value (contract amount)
  - `Subskribe Order Delta ARR` — net ARR change from subscription system:
    - **$0** = Flat Renewal (no ARR change)
    - **Positive** = Expansion (ARR increase)
    - **Negative** = Contraction (ARR decrease)
  - `Expansion ARR` — only positive values from Subskribe Order Delta ARR (expansion-only view)

**Which value field to use:**
| Analysis | New Business | Existing Business |
|----------|-------------|-------------------|
| Deal/booking value | Amount | Amount |
| Net ARR impact | Amount | Subskribe Order Delta ARR |
| Expansion-only ARR | N/A | Expansion ARR |

---

## Pipeline Creation Metrics

Measured by **Stage 2 Entry Date** (when opp entered pipeline). **Always use Stage 2. Discovery Start Date as the pipeline creation date anchor — not Created Date.** Created Date reflects when the opp was entered into Salesforce, which may precede actual pipeline entry. This was confirmed as the canonical rule on 2026-03-11.

### PipeCreate Count
- **Definition:** Count of opportunities entering Stage 2+ in a period
- **Formula:** `COUNTIFS(Stage 2 Entry Date, [date range], Stage, "<>"&"1. Lead Verification")`
- Slice by: Opportunity Type, Lead Source Attribution, Use Case

### PipeCreate ADS (Average Deal Size)
- **Definition:** Average Amount of opportunities created in period
- **Formula:** `AVERAGEIFS(Amount, [date anchor], [date range], Amount, ">"&0)`

### PipeCreate Total$
- **Definition:** Sum of Amount for opportunities created in period
- **Formula:** `SUMIFS(Amount, [date anchor], [date range])`

---

## Booking Metrics

Measured by **Close Date** (when deal closed).

### New Business Bookings Total$
- **Definition:** Sum of Amount for Closed-Won where Opportunity Type = "New Business"
- **Formula:** `SUMIFS(Amount, Stage, "9. Closed-Won", Opportunity Type, "New Business", Close Date, [date range])`

### New Business Bookings Count
- **Definition:** Count of Closed-Won New Business deals
- **Formula:** `COUNTIFS(Stage, "9. Closed-Won", Opportunity Type, "New Business", Close Date, [date range])`

### New Business ADS
- **Definition:** Average Amount of Closed-Won New Business (excluding $0)
- **Formula:** `AVERAGEIFS(Amount, Stage, "9. Closed-Won", Opportunity Type, "New Business", Amount, ">"&0, Close Date, [date range])`

### Existing Business Bookings Total$
- **Definition:** Sum of Amount for Closed-Won Existing Business
- **Formula:** `SUMIFS(Amount, Stage, "9. Closed-Won", Opportunity Type, "Existing Business", Close Date, [date range])`

### Expansion ARR
- **Definition:** Sum of positive Subskribe Order Delta ARR for Closed-Won Existing Business
- **Formula:** `SUMIFS(Expansion ARR, Stage, "9. Closed-Won", Opportunity Type, "Existing Business", Close Date, [date range])`
- **Note:** `Expansion ARR` field contains only positive delta values; $0 and negatives are excluded

### Net ARR (Existing)
- **Definition:** Sum of Subskribe Order Delta ARR for Closed-Won Existing Business
- **Formula:** `SUMIFS(Subskribe Order Delta ARR, Stage, "9. Closed-Won", Opportunity Type, "Existing Business", Close Date, [date range])`
- **Note:** Includes flat renewals ($0), expansions (positive), and contractions (negative)

### Lost Total$
- **Definition:** Sum of Amount for Closed-Lost deals
- **Formula:** `SUMIFS(Amount, Stage, "10. Closed-Lost", Close Date, [date range])`
- Slice by Opportunity Type for New Business Lost vs Existing Business Lost

### New Logo Count
- **Definition:** Count of Closed-Won New Business deals that are the account's first win
- **Formula:** `COUNTIFS(Stage, "9. Closed-Won", Opportunity Type, "New Business", New Biz Won Before This Deal, 0, Close Date, [date range])`
- **Note:** `New Biz Won Before This Deal` is a helper field (see `data-dictionary.md`)

---

## Conversion & Velocity Metrics

### Win Rate
- **Definition:** Closed-Won / (Closed-Won + Closed-Lost). Universal — applies to any filtered set.
- **Formula:** `IFERROR(COUNTIFS(Stage, "9. Closed-Won", [filters]) / (COUNTIFS(Stage, "9. Closed-Won", [filters]) + COUNTIFS(Stage, "10. Closed-Lost", [filters])), 0)`
- **Unit:** Percentage
- Slice by: Opportunity Type, Lead Source Attribution, Use Case

### Average Sales Cycle
- **Definition:** Average days from Stage 2 entry to close, for Closed-Won deals
- **Formula:** `AVERAGEIFS(Sales Cycle Days, Stage, "9. Closed-Won", [filters])`
- **Unit:** Days
- **Basis:** Stage 2. Discovery Start Date → Close Date (time as active pipeline opportunity)
- **Note:** Sales Cycle Days = Pipeline Velocity Days (same metric). For total deal lifetime, use Age (Created Date → Close Date).
- Slice by: Opportunity Type, Lead Source Attribution, Use Case

### Stage-to-Stage Conversion
- **Definition:** Percentage of opportunities that reached one stage and also reached the next
- **"Reached" = stage entry date is populated.** Do NOT infer from current stage — a deal at Stage 10 (Closed-Lost) may have been lost from Stage 3 without ever reaching Stages 4-6. See `../_shared/anti-patterns.md` § AP-1 for the full explanation.
- **Formula:** Count reached Stage N+1 / Count reached Stage N (use `Reached SX` helper fields from `data-dictionary.md`)
- **Cumulative:** Count reached Stage N / Count reached Stage 2 (for funnel-from-pipeline-entry view)

---

## Dimensions

### Time Dimensions
| Dimension | Description |
|-----------|------------|
| Date anchor | Close Date (bookings), Created Date (pipeline), Stage 2 Entry Date (pipeline threshold) |
| Week | ISO week derived from date anchor |
| Month | Calendar month (YYYYMM code in raw data) |
| Fiscal Quarter | Q1-Q4 per fiscal calendar |
| Fiscal Year | FY per fiscal calendar (e.g., FY2026) |

### Segment Dimensions
| Dimension | Values | Source |
|-----------|--------|--------|
| Opportunity Type | New Business, Existing Business | Opportunity field |
| Lead Source Attribution | Marketing, Sales, Partner, Other | Opportunity field |
| Use Case | Social Media Access, Access Management (EPM, SSO, MFA), Identity Lifecycle Management (JML), Other | Mapped from Primary Use Case |
| Sales Play | Mapped from Use Case | Map tab lookup |
| Company Segment | From data | Opportunity field |
| Pipeline Category | PrePipeline, Early Pipeline, Mid Pipeline, Late Pipeline, Won, Lost, QualifiedOut | Derived from Stage |
| CSM Sourced | Yes/No | Opportunity field |

---

## Sanity Check Rules

| Check | Rule | Action if Failed |
|-------|------|-----------------|
| Opp Type coverage | Every opportunity is either "New Business" or "Existing Business" | Flag unknown types |
| No negative NB Amount | New Business Amount >= 0 | Flag specific deals |
| New Logos ≤ NB Won count | New Logo count ≤ New Business Closed-Won count | Investigate duplicate counting |
| ADS approximation | NB ADS × NB Won Count ≈ NB Bookings Total$ (within 5%) | Flag — outlier deals may skew average |
| Sales cycle range | 30-365 days typical | Values outside may indicate data issues |
| Row count preserved | Prepared Data rows = Raw Data rows | Rows dropped or duplicated during prep |
| Stage values valid | All Stage values match known stages (1-6, 9, 10, 11) | Flag unknown stages |
| Expansion ARR ≤ Amount | For Existing Business, Expansion ARR should not exceed Amount | Investigate data mismatch |
| Funnel monotonicity | Stage hit counts non-increasing: S2 ≥ S3 ≥ S4 ≥ S5 ≥ S6 ≥ S9 | Investigate — likely inferring "hit" from current stage instead of stage entry dates |
