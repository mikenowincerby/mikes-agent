# Marketing Workbench — Definitions Template

Content for the Definitions tab (Tab index 15). Written by the Review agent (Stage 4).

## Section 1: Methodology Overview

Plain-English summary of the workbench:
- Persistent Google Sheet connected to live Salesforce data via IMPORTRANGE
- Campaign Members are the primary unit of analysis — each row is one person's membership in one campaign
- Lookups tab provides join paths to Campaign, Opportunity, Account, and Lifecycle data
- Prepared Data adds calculated columns in tiered formulas (Tier 1: raw + Lookups, Tier 2: references Tier 1, Tier 3: references Tier 2)
- 5 analytical models built as separate tabs, all referencing the shared Prepared Data layer
- Contact-first precedence: when a person has both Lead and Contact records, Contact values take priority
- All values are live Google Sheets formulas — workbench self-updates when source data refreshes

## Section 2: FAQ

| Question | Answer |
|----------|--------|
| How does data get into this sheet? | IMPORTRANGE formulas in each Raw tab pull live data from Marketing Campaign Data and Daily Data sheets. Data refreshes automatically. |
| What is Prepared Data? | Campaign Members data enriched with calculated columns (campaign name, lifecycle flags, velocity metrics, etc.) via tiered formulas. |
| What does "contact-first" mean? | When a person has both Contact and Lead records, the Contact value is used for all unified fields (status, lifecycle stage, sort score, etc.). |
| How are MQLs counted? | Three methods: (1) LEN(Unified MQL Start Date) > 0 for "ever MQL'd" (matches Salesforce frontend), (2) Is MQL+ = "Yes" for current lifecycle snapshot, (3) MQL Start/End date range for time-period analysis. See marketing-metrics.md. |
| Why SUMPRODUCT instead of COUNTIFS? | COUNTIFS gives incorrect results on large formula-heavy Google Sheets (known bug). All analysis tabs use SUMPRODUCT. See `implementation-notes.md`. |
| Why LEN>0 instead of `<>""`? | Cells written via the Google Sheets API with empty strings appear blank but `<>""` returns TRUE (phantom blank cells). Only `LEN()>0` reliably detects non-blank content. |
| Why are some lifecycle columns static values? | Unified MQL/SAL/SQL Start Dates are pre-computed in Python and pasted as values. INDEX/MATCH formulas across 30K+ rows hit Google Sheets resource limits when applied to 9K+ rows. The enrichment cascade (CM Contact → CM Lead → Raw Contacts → Raw Leads) is documented in the enrichment process. |
| What are the 5 models? | Frontend Replica (validation), Lead Cohort (stage entry analysis), Campaign Efficiency (aggregated performance), Account Look-Back (touch timeline), Lead Tracing (snapshot tracing). |
| Can I add campaigns to Lookups? | Campaign Mapping is auto-populated from Raw Campaigns. New campaigns appear automatically when the source refreshes. |
| Why are some velocity columns blank? | Velocity requires both start and end timestamps. Leads lack Opportunity datetime, so Days SQL to Opp and Days Lead to Opp are contacts-only. |
| What is the fiscal calendar? | FY = CY+1 for Feb-Dec, CY for Jan. Q1=Feb-Apr, Q2=May-Jul, Q3=Aug-Oct, Q4=Nov-Jan. |

## Section 3: Metric Definitions

| Metric | Definition | Formula | Source Column |
|--------|-----------|---------|---------------|
| Total Campaign Members | All members in a campaign | SUMPRODUCT on Campaign ID | Prepared Data |
| Net New Leads | Members originally leads | SUMPRODUCT where Origin Type = "Lead" | Prepared Data |
| MQLs (ever) | Members who have ever MQL'd | SUMPRODUCT where LEN(Unified MQL Start Date) > 0 | Prepared Data |
| MQLs (current) | Members at MQL+ lifecycle stage now | SUMPRODUCT where Is MQL+ = "Yes" | Prepared Data |
| SALs (current) | Members at SAL+ lifecycle stage | SUMPRODUCT where Is SAL+ = "Yes" | Prepared Data |
| SQLs (ever) | Members who have ever reached SQL | SUMPRODUCT where LEN(Unified SQL Start Date) > 0 | Prepared Data |
| SQLs (current) | Members at SQL+ lifecycle stage now | SUMPRODUCT where Is SQL+ = "Yes" | Prepared Data |
| Opportunities | Members with a converted opp | SUMPRODUCT where Has Opportunity = 1 | Prepared Data |
| Won Opportunities | Members whose opp is Closed-Won | SUMPRODUCT where Is Closed Won Opp = 1 | Prepared Data |
| Campaign Cost | Total campaign spend | VLOOKUP from Campaign Mapping Lookups | Lookups |
| Cost per MQL | Cost / MQLs | IFERROR(Cost / MQL count) | Calculated |
| Cost per SQL | Cost / SQLs | IFERROR(Cost / SQL count) | Calculated |
| Average Sort Score | Mean quality score | AVERAGEIFS on Sort Score Numeric | Prepared Data |
| Days Lead to MQL | Avg velocity from lead creation to MQL | AVERAGEIFS on Days Lead to MQL (non-blank) | Prepared Data |
| Days MQL to SAL | Avg velocity from MQL to SAL | AVERAGEIFS on Days MQL to SAL (non-blank) | Prepared Data |
| Days SAL to SQL | Avg velocity from SAL to SQL | AVERAGEIFS on Days SAL to SQL (non-blank) | Prepared Data |
| Days SQL to Opp | Avg velocity from SQL to Opp | AVERAGEIFS on Days SQL to Opp (non-blank) | Prepared Data |
| Days Lead to Opp | Avg end-to-end velocity | AVERAGEIFS on Days Lead to Opp (non-blank) | Prepared Data |
| Speed to Lead (Avg) | Avg minutes from MQL to first outreach | SUMPRODUCT-based average on Unified Speed to Lead (non-blank, non-zero) | Prepared Data |
| Speed to Lead (Median) | Median minutes from MQL to first outreach | Python compute-and-push (no conditional MEDIAN in Sheets) | Computed |
| MQL to SAL Conv % | % of MQLs that reached SAL | IFERROR(SALs/MQLs). "Ever" methodology: SAL=LEN(SAL Start)>0, MQL=LEN(MQL Start)>0 | Calculated |
| MQL to SQL Conv % | % of MQLs that reached SQL | IFERROR(SQLs/MQLs). "Ever" methodology: SQL=LEN(SQL Start)>0, MQL=LEN(MQL Start)>0 | Calculated |

## Section 4: Data Source & Refresh

- **Primary source:** Marketing Campaign Data (`$MARKETING_DATA`) — auto Salesforce refresh
- **Secondary source:** Daily Data (`$DAILY_DATA`) — daily Salesforce refresh, READ-ONLY
- **Ingestion method:** IMPORTRANGE (live connection, no manual copy needed)
- **Row counts at creation:** Campaign Members ~9.4K, Leads ~12.7K, Contacts ~30.4K, Campaigns ~91, Opportunities varies
- **Computation method:** All values are Google Sheets formulas — no Python compute

## Section 5: Assumptions & Limitations

- IMPORTRANGE requires one-time manual authorization per source-destination sheet pair
- Contact-first precedence assumes Contact records are more current than Lead records for the same person
- Velocity metrics require non-blank timestamps at both stages — sparse data produces blanks, not zeros
- Leads do not have Opportunity datetime — SQL-to-Opp and Lead-to-Opp velocity are contacts-only
- "New vs Previously Engaged" requires Unified Create Date to be populated — blank if both Lead Create Date and Contact C Lead Start are missing
- Campaign cost is total lifetime cost (not pro-rated per period) unless explicitly scoped
- Source data quality depends on Salesforce data entry — garbage in, garbage out
- Unified MQL/SAL/SQL Start Dates are pre-computed static values (not live formulas) due to Google Sheets resource limits — they do NOT auto-update when source data changes. Re-run the enrichment script when source data is refreshed.
- MQL counting for frontend replication uses MQL Start Date presence (LEN>0), not Is MQL+ lifecycle flag. The Salesforce Campaign frontend counts anyone who has ever MQL'd.
- COUNTIFS is never used in analysis tabs — SUMPRODUCT is the only reliable counting method on large formula-heavy sheets (known Google Sheets bug).
- API-written empty cells create phantom non-blank values (ISBLANK=FALSE). All non-blank checks use LEN>0.
