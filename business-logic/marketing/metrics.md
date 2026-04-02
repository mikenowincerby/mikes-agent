# Marketing Metrics

Metric definitions for marketing campaign analysis. Referenced by `agents/pipelines/marketing-analytics/` pipeline agents.

---

## Lifecycle Stage Hierarchy

| Rank | Stage | Category | Is MQL+ | Is SQL+ | Is SAL+ |
|------|-------|----------|---------|---------|---------|
| 1 | Customer | Post-Sale | Yes | Yes | Yes |
| 2 | Opportunity | Post-Sale | Yes | Yes | Yes |
| 3 | SQL | Sales Qualified | Yes | Yes | Yes |
| 4 | SAL | Sales Accepted | Yes | Yes | Yes |
| 5 | MQL | Marketing Qualified | Yes | No | No |
| 6 | Lead | Pre-Qualified | No | No | No |
| 7 | Disqualified | Out | No | No | No |
| 8 | Closed Lost | Out | No | No | No |
| 9 | Partner | Other | No | No | No |

**Threshold rules:**
- "MQL and above" = Rank <= 5
- "SQL and above" = Rank <= 4
- "SAL and above" = Rank <= 4 (SAL is the entry point for sales acceptance)

This hierarchy drives the Lookups tab mapping for `Is MQL+`, `Is SQL+`, and `Is SAL+` helper columns.

---

## Metrics

| Metric | Formula | Type | Notes |
|--------|---------|------|-------|
| Total Campaign Members | `SUMPRODUCT` by campaign ID | Count | All members regardless of lifecycle stage. **Use SUMPRODUCT, not COUNTIFS** (COUNTIFS is unreliable on large formula-heavy sheets). |
| Net New Leads | `SUMPRODUCT` where Origin Type = "Lead" | Count | Members who were originally leads |
| MQLs in Campaign (ever) | `SUMPRODUCT` where LEN(Unified MQL Start Date) > 0 | Count | Members who have **ever** MQL'd (have an MQL Start Date). This matches the Salesforce Campaign frontend, which counts MQL by date presence, not current lifecycle stage. |
| MQLs in Campaign (current) | `SUMPRODUCT` where Is MQL+ = "Yes" | Count | Members whose **current** lifecycle stage is MQL or above. Point-in-time snapshot — does NOT match frontend counts. Use only for current-state analysis. |
| MQLs in Period | `SUMPRODUCT` where Unified MQL Start Date <= period_end AND (Unified MQL End Date = "" OR Unified MQL End Date >= period_start) | Count | Members who were MQL at any point during the analysis period. **Preferred for time-bounded analysis.** |
| SQLs in Campaign (ever) | `SUMPRODUCT` where LEN(Unified SQL Start Date) > 0 | Count | Members who have ever reached SQL (have a SQL Start Date). Matches frontend counting methodology. |
| SQLs in Campaign (current) | `SUMPRODUCT` where Is SQL+ = "Yes" | Count | Members at SQL lifecycle stage or above. Point-in-time snapshot. |
| Opportunities from Campaign | `COUNTIFS` where Has Opportunity = 1 | Count | Members with a Converted Opportunity ID |
| Opportunity Value | `SUMIFS` on Opp Amount where Has Opportunity = 1 | Currency | Total value of attributed opportunities |
| Won Opportunities | `COUNTIFS` where Is Closed Won Opp = 1 | Count | Members whose attributed opp is Closed-Won |
| Won Value | `SUMIFS` on Opp Amount where Is Closed Won Opp = 1 | Currency | Total value of won attributed opps |
| MQL Conversion Rate | MQLs / Total Members | Percentage | Wrap in `IFERROR` |
| SQL Conversion Rate | SQLs / Total Members | Percentage | Wrap in `IFERROR` |
| Opp Conversion Rate | Opps / Total Members | Percentage | Wrap in `IFERROR` |
| Cost per Acquisition (CPA) | Campaign Cost / Total Members | Currency | From Lookups campaign join |
| Cost per MQL | Campaign Cost / MQLs | Currency | Wrap in `IFERROR` |
| Cost per SQL | Campaign Cost / SQLs | Currency | Wrap in `IFERROR` |
| Campaign ROI | (Won Value - Campaign Cost) / Campaign Cost | Percentage | Wrap in `IFERROR` |

**Cost scoping rule:** When analyzing a specific time period (e.g., "Q2 FY26 campaign performance"), cost metrics must use **period-scoped costs** — campaign costs for campaigns that had members in the analysis period. Do NOT divide total lifetime campaign costs across all campaign types by period-specific MQLs/SQLs. This inflates cost-per-X by including spend from campaigns that had zero activity in the period.

Two acceptable approaches:
1. **Campaign-level scoping (preferred):** Sum costs only for campaigns that had at least one member with Start Date in the analysis period. This is what the Lookups tab campaign join provides when filtered by the period cohort.
2. **Pro-rated costs:** If a campaign spans multiple quarters, divide its cost by the number of active quarters and use only the period's share. This is more accurate but harder to implement in sheet formulas — use only if the user requests it.

Always document which cost scoping method was used in the Summary notes section and Definitions tab.
| SALs in Campaign (current) | `COUNTIFS` where Is SAL+ = "Yes" | Count | Members whose current lifecycle stage is SAL or above. Point-in-time snapshot. Uses Is SAL+ helper column. |
| SAL Conversion Rate | SALs / Total Members (or SALs / MQLs) | Percentage | Wrap in `IFERROR`. Denominator depends on analysis context — use Total Members for overall funnel, MQLs for stage-to-stage conversion. |
| SALs in Period | `COUNTIFS` where Unified SAL Start Date <= period_end AND (Unified SAL End Date = "" OR >= period_start) | Count | Members who were SAL at any point during the analysis period. Requires SAL date enrichment from Leads/Contacts tabs. |
| SQLs in Period | `COUNTIFS` where Unified SQL Start Date <= period_end AND (Unified SQL End Date = "" OR >= period_start) | Count | Members who were SQL at any point during the analysis period. Requires SQL date enrichment from Leads/Contacts tabs. |
| Cost per SAL | Campaign Cost / SALs in Period | Currency | Wrap in `IFERROR` |
| Speed to Lead (Avg) | `IFERROR(SUMPRODUCT((criteria)*(LEN(stl_col)>0)*(stl_col))/SUMPRODUCT((criteria)*(LEN(stl_col)>0)),"")` | Minutes | Average minutes from MQL to first sales outreach. Filter: LEN(Unified MQL Start Date)>0 AND LEN(Unified Speed to Lead)>0. Use SUMPRODUCT-based average, not AVERAGEIFS (phantom blanks). **High-priority metric.** |
| Speed to Lead (Median) | Computed (Python) | Minutes | Median minutes from MQL to first outreach. Requires `compute-and-push` — Google Sheets has no conditional MEDIAN function. |
| MQL to SAL Conversion Rate | SALs (ever) / MQLs (ever) | Percentage | `IFERROR(SUMPRODUCT((criteria)*(LEN(sal_start)>0))/SUMPRODUCT((criteria)*(LEN(mql_start)>0)),"")`. "Ever" methodology: SAL = LEN(Unified SAL Start Date)>0, MQL = LEN(Unified MQL Start Date)>0. |
| MQL to SQL Conversion Rate | SQLs (ever) / MQLs (ever) | Percentage | `IFERROR(SUMPRODUCT((criteria)*(LEN(sql_start)>0))/SUMPRODUCT((criteria)*(LEN(mql_start)>0)),"")`. "Ever" methodology: SQL = LEN(Unified SQL Start Date)>0, MQL = LEN(Unified MQL Start Date)>0. |
| Average Sort Score | `AVERAGEIFS` on Sort Score Numeric | Number | Numeric conversion of Sort Score |
| Days Lead to MQL | `AVERAGEIFS` on Days Lead to MQL helper column (excluding blanks) | Days | Average velocity from lead creation to MQL. |
| Days MQL to SAL | `AVERAGEIFS` on Days MQL to SAL helper column (excluding blanks) | Days | Average velocity from MQL to SAL. |
| Days SAL to SQL | `AVERAGEIFS` on Days SAL to SQL helper column (excluding blanks) | Days | Average velocity from SAL to SQL. |
| Days SQL to Opp | `AVERAGEIFS` on Days SQL to Opp helper column (excluding blanks) | Days | Average velocity from SQL to Opportunity. Contacts only (leads lack Opportunity datetime). |
| Days Lead to Opp | `AVERAGEIFS` on Days Lead to Opp helper column (excluding blanks) | Days | Average end-to-end velocity from lead creation to Opportunity. Contacts only. |

**Formula reference rule:** All formula references use Prepared Data helper columns (`Is MQL+`, `Is SQL+`, `Has Opportunity`, `Is Closed Won Opp`, `Opp Amount`, etc.), NOT raw lifecycle stage strings. This keeps formulas consistent and editable via the Lookups tab.

**SUMPRODUCT rule:** Always use SUMPRODUCT instead of COUNTIFS for counting in Google Sheets analysis tabs. COUNTIFS gives incorrect results on large formula-heavy sheets (known Google Sheets bug). Use `LEN(cell)>0` instead of `<>""` for non-blank checks (phantom blank cells from API writes).

**MQL counting rule — "ever" vs "current":**
- **Frontend replication / campaign attribution:** Use `MQLs in Campaign (ever)` — count by `LEN(Unified MQL Start Date) > 0`. This matches the Salesforce Campaign frontend which counts anyone who has ever had an MQL date.
- **Current-state snapshot:** Use `MQLs in Campaign (current)` — count by `Is MQL+ = "Yes"`. Only for "how many people are currently at MQL or above" questions.
- **Time-bounded analysis:** Use `MQLs in Period` with `Unified MQL Start Date` / `Unified MQL End Date`.

**SAL/SQL counting rule:** Same "ever" vs "current" distinction applies. SAL/SQL dates come from the Leads/Contacts tabs (via Lifecycle Mappings or pre-computed enrichment), not from Campaign Members directly.

**Campaign-scoped vs full-funnel analysis:**
- **Campaign-scoped:** Uses Campaign Members tab. Answers questions like "how many MQLs did campaign X generate?" Metrics are scoped to people who are members of at least one campaign.
- **Full-funnel:** Uses the Leads and Contacts tabs directly. Answers questions like "how many leads MQL'd this week?" across the entire lead/contact universe, regardless of campaign membership. These tabs contain ALL leads (~12.7K) and contacts (~30.4K), not just campaign members.

---

## Dimensions

| Dimension | Source | Notes |
|-----------|--------|-------|
| Campaign Name | Lookups (VLOOKUP from Campaign ID) | Primary grouping |
| Campaign Type | Lookups (VLOOKUP from Campaign ID) | Category grouping |
| Time (Start Date) | Start Mo, Start Qtr, Start Fiscal | Fiscal calendar — see below |
| Origin Type | Helper column (Lead vs Contact) | From "Converted from Lead" column |
| Lifecycle Stage | Unified Lifecycle Stage | Contact-first precedence |
| Department | Unified Department | Contact-first precedence |
| Level | Unified Level | Contact-first precedence |
| Account | Account Name (from Lookups join) | Via Unified Account ID |
| Lead Source | Unified Lead Source (helper column) | Contact Lead Source first, Lead Lead Source fallback. Values: Marketing, Sales, Partner, etc. |
| New vs Previously Engaged | Helper column | Requires Lead Created Date (pending) |
| Owner | Unified Owner (helper column) | Contact Owner first, Lead Owner fallback. For rep-level Speed to Lead and conversion analysis. |
| MQL Quarter | MQL Quarter Label (helper column) | Fiscal quarter derived from Unified MQL Start Date. Distinct from Quarter Label (campaign Start Date). For time-based MQL cohort analysis. |

---

## Lifecycle Timestamp Mapping

Maps each lifecycle stage to its source timestamp field for leads vs contacts. Used for velocity calculations and stage-entry date unification.

| Stage | Lead Field | Lead Col | Contact Field | Contact Col |
|-------|-----------|----------|---------------|-------------|
| Lead Created | Create Date | R | C Lead Start Datetime | U |
| Touch Stage 1 | Touch Stage 1 Date | Q | Touch Stage 1 Date | S |
| MQL | MQL Start Datetime | K | C MQL Start Datetime | Q |
| SAL | SAL Start Datetime | M | C SAL Start Datetime | K |
| SQL | SQL Start Datetime | O | C SQL Start Datetime | M |
| Opportunity | — | — | C Opportunity Start Datetime | V |

> **Note:** Leads do not have an Opportunity timestamp. Velocity metrics involving Opportunity stage (Days SQL to Opp, Days Lead to Opp) are contacts-only.

---

## Fiscal Calendar

Same fiscal calendar as sales metrics (see `../sales/metrics.md`).

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

**Example:** March 2026 → FY2027 Q1.

---

## Sanity Checks

| Check | Rule | Action if Failed |
|-------|------|-----------------|
| Row count preserved | Raw Campaign Members rows = Prepared Data rows | Investigate |
| Campaign ID join coverage | 100% of rows match campaign in Lookups | Flag unmatched IDs |
| Opp join coverage | >= 90% of non-blank Converted Opp IDs resolve | Flag unresolved |
| Account join coverage | >= 80% of non-blank Unified Account IDs resolve | Flag unresolved |
| MQL count <= Total Members | Per campaign | Investigate if exceeded |
| Won Opps <= Total Opps | Per campaign | Investigate if exceeded |
| Opp Amount >= 0 | All resolved opportunity amounts | Flag negatives |
| Unified fields blank rate | < 20% for Status, Lifecycle Stage | Flag high blanks |
| Lead ID join coverage | >= 90% of non-blank Lead IDs in Campaign Members match Raw Leads | Flag unresolved — may indicate stale Leads tab |
| Contact ID join coverage | >= 90% of non-blank Contact IDs in Campaign Members match Raw Contacts | Flag unresolved — may indicate stale Contacts tab |
| SAL date coverage | % of Is SQL+ = "Yes" members with non-blank Unified SAL Start Date | Report %. If sparse, SAL period metrics will undercount. |
| SQL date coverage | % of Is SQL+ = "Yes" members with non-blank Unified SQL Start Date | Report %. If sparse, SQL period metrics will undercount. |
| Velocity reasonableness | All velocity helper columns (Days Lead to MQL, etc.) must be positive and < 365 days | Severity: **warning**. Flag negative values (date ordering issue) and values > 365 (likely data quality issue). Do not fail — report for investigation. |
