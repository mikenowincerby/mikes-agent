# Marketing Data Dictionary

Field reference for marketing campaign data. Separates original Salesforce fields from calculated helper fields.

## Table of Contents
- [Data Sources](#data-sources)
- [Original Fields (Campaign Members Tab)](#original-fields-salesforce--marketing-campaign-data-campaign-members-tab)
- [Original Fields (Leads Tab)](#original-fields-salesforce--marketing-campaign-data-leads-tab)
- [Original Fields (Contacts Tab)](#original-fields-salesforce--marketing-campaign-data-contacts-tab)
- [Original Fields (Campaign Tab)](#original-fields-salesforce--marketing-campaign-data-campaign-tab)
- [Original Fields (Master Campaign Frontend Data Tab)](#original-fields-salesforce--marketing-campaign-data-master-campaign-frontend-data-tab)
- [Original Fields (Daily Data: Opportunity Tab)](#original-fields-daily-data-opportunity-tab--key-fields-for-marketing-joins)
- [Helper Fields](#helper-fields-calculated--prepared-data-only)
- [Lookup Mappings](#lookup-mappings)

---

## Data Sources

| Source | Sheet ID | Tabs | Refresh |
|--------|----------|------|---------|
| Marketing Campaign Data | `$MARKETING_DATA` | Master Campaign Frontend Data, Campaign Members, Leads, Contacts, Campaign | Auto (Salesforce) |
| Daily Data | `$DAILY_DATA` | Opportunity, Account | Daily |

**Marketing Campaign Data** is the primary source for all marketing analyses. Contains campaign metadata and member-level detail.
**Daily Data** is the secondary source — used for opportunity amounts and account names when enriching campaign members via joins.

> **Both sources are READ-ONLY — never write to either.**
>
> **IMPORTRANGE alternative:** For persistent workbench sheets that need live data, IMPORTRANGE can be used as an alternative ingestion method instead of copying raw data. This keeps the workbench sheet connected to the source and avoids stale snapshots.

---

## Original Fields (Salesforce → Marketing Campaign Data: Campaign Members Tab)

Row 1 is metadata, row 2 is headers, data starts row 3. 9,381 rows (including metadata + header).

> **Important — Duplicate Column Names:** Columns I/T (Status), M/V (Touch Stage), N/Y (Sort Score), O/Z (Level), P/AA (Department) have identical names for contact vs lead fields. During data prep, these are disambiguated in Prepared Data via "Unified" helper columns that apply contact-first precedence.
>
> **MQL Date Fields:** Contact MQL dates (K/L) and Lead MQL dates (W/X) track when a member entered/exited MQL status. Used for time-range MQL counting — see `metrics.md`.

| Col | Header | Type | Notes |
|-----|--------|------|-------|
| A | ADMIN Campaign 18 Digit ID | Text | Salesforce Campaign ID (join key) |
| B | Campaign Member ID | Text | Unique key |
| C | Name | Text | Member name |
| D | Title | Text | Job title |
| E | Status | Text | Campaign member status (Completed, Sent, etc.) |
| F | Start Date | Date | When member was added to campaign (YYYY-MM-DD) |
| G | ADMIN Contact ID 18 Digit | Text | **Contact field** — Salesforce Contact ID |
| H | Account ID | Text | **Contact field** — Account ID (preferred for account join) |
| I | Contact Status | Text | **Contact field** — duplicate name "Status" in source |
| J | Contact Lifecycle Stage | Text | **Contact field** — MQL, SQL, SAL, Lead, etc. |
| K | C MQL Start Date | Date | **Contact field** — When contact entered MQL status |
| L | C MQL End Date | Date | **Contact field** — When contact left MQL status (blank = still MQL) |
| M | Touch Stage | Text | **Contact field** — Untouched, etc. (duplicate name) |
| N | Sort Score | Text/Number | **Contact field** — Lead quality score (duplicate name) |
| O | Level | Text | **Contact field** — CXO, VP, Practitioner, etc. (duplicate name) |
| P | Department | Text | **Contact field** — Security, IT, etc. (duplicate name) |
| Q | ADMIN Lead ID 18 Digit | Text | **Lead field** — Salesforce Lead ID |
| R | Created Date | Datetime | **Lead field** — Lead creation timestamp |
| S | Account | Text | **Lead field** — Lead account name |
| T | Status | Text | **Lead field** — Return to Marketing, etc. (duplicate name) |
| U | Lead Lifecycle Stage | Text | **Lead field** — MQL, SQL, etc. |
| V | Touch Stage | Text | **Lead field** — (duplicate name) |
| W | MQL Start Date | Date | **Lead field** — When lead entered MQL status |
| X | MQL End Date | Date | **Lead field** — When lead left MQL status (blank = still MQL) |
| Y | Sort Score | Text/Number | **Lead field** — (duplicate name) |
| Z | Level | Text | **Lead field** — (duplicate name) |
| AA | Department | Text | **Lead field** — (duplicate name) |
| AB | Converted Opportunity ID | Text | Salesforce Opp ID (join key to Daily Data) |
| AC | Opportunities in Campaign | Number | Count of opps |
| AD | Converted from Lead | Boolean | TRUE if member was originally a lead |
| AE | Converted Contact ID | Text | Contact ID after lead conversion |
| AF | Converted Account ID | Text | Account ID after lead conversion (fallback for account join) |
| AG | Converted from Lead | Boolean | Duplicate of col AD — same field exported twice in source. Use col AD. |

---

## Original Fields (Salesforce → Marketing Campaign Data: Leads Tab)

All leads with lifecycle stage dates. Row 1 is metadata ("Salesforce Import"), row 2 is headers, data starts row 3. 12,705 rows (including metadata + header).

> **Key difference from Campaign Members:** Contains ALL leads (not just campaign members) and includes SAL/SQL start/end datetimes that Campaign Members does not have. Join to Campaign Members via ADMIN Lead ID 18 Digit (col E here → col Q in Campaign Members).

| Col | Header | Type | Notes |
|-----|--------|------|-------|
| A | First Name | Text | |
| B | Last Name | Text | |
| C | Title | Text | Job title |
| D | Account | Text | Lead account name |
| E | ADMIN Lead ID 18 Digit | Text | Join key to Campaign Members col Q |
| F | Department | Text | |
| G | Level | Text | CXO, VP, Director, etc. |
| H | Lead Lifecycle Stage | Text | Lead, MQL, SAL, SQL, Opportunity |
| I | Sort Score | Text/Number | Lead quality score |
| J | Lead ID | Text | 15-char Salesforce Lead ID |
| K | MQL Start Datetime | Datetime | When lead entered MQL |
| L | MQL End Datetime | Datetime | When lead left MQL (blank = still MQL) |
| M | SAL Start Datetime | Datetime | When lead entered SAL — **not available in Campaign Members** |
| N | SAL End Datetime | Datetime | When lead left SAL |
| O | SQL Start Datetime | Datetime | When lead entered SQL — **not available in Campaign Members** |
| P | SQL End Datetime | Datetime | When lead left SQL |
| Q | Touch Stage 1 Date | Date | Date of first touch stage |
| R | Create Date | Date | When lead was created in Salesforce |
| S | Lead Source | Text | Lead source attribution (e.g., Marketing, Sales, Partner) |
| T | Speed to Lead | Number (minutes) | Pre-calculated minutes from MQL qualification to first sales outreach. Null if no outreach recorded. |
| U | Lead Owner | Text | Salesforce Lead Owner — assigned rep name. Used for Speed to Lead analysis by owner. |

---

## Original Fields (Salesforce → Marketing Campaign Data: Contacts Tab)

All contacts with lifecycle stage dates. Row 1 is metadata ("Salesforce Import"), row 2 is headers, data starts row 3. 30,431 rows (including metadata + header).

> **Key difference from Campaign Members:** Contains ALL contacts (not just campaign members) and includes SAL/SQL start/end datetimes that Campaign Members does not have. Join to Campaign Members via ADMIN Contact ID 18 Digit (col F here → col G in Campaign Members).

| Col | Header | Type | Notes |
|-----|--------|------|-------|
| A | First Name | Text | |
| B | Last Name | Text | |
| C | Title | Text | Job title |
| D | Account Name | Text | |
| E | Account Owner | Text | |
| F | ADMIN Contact ID 18 Digit | Text | Join key to Campaign Members col G |
| G | ADMIN Acct ID 18 Digit | Text | Account ID (join key) |
| H | Department | Text | |
| I | Level | Text | CXO, VP, Director, etc. |
| J | Contact Lifecycle Stage | Text | Lead, MQL, SAL, SQL, Opportunity, Customer |
| K | C SAL Start Datetime | Datetime | When contact entered SAL — **not available in Campaign Members** |
| L | C SAL End Datetime | Datetime | When contact left SAL |
| M | C SQL Start Datetime | Datetime | When contact entered SQL — **not available in Campaign Members** |
| N | C SQL End Datetime | Datetime | When contact left SQL |
| O | Sort Score | Text/Number | Contact quality score |
| P | Contact ID | Text | 15-char Salesforce Contact ID |
| Q | C MQL Start Datetime | Datetime | When contact entered MQL |
| R | C MQL End Datetime | Datetime | When contact left MQL (blank = still MQL) |
| S | Touch Stage 1 Date | Date | Date of first touch stage |
| T | Converted from Lead | Boolean | TRUE if contact was converted from a lead |
| U | C Lead Start Datetime | Datetime | When contact entered Lead stage |
| V | C Opportunity Start Datetime | Datetime | When contact entered Opportunity stage |
| W | Lead Source | Text | Lead source attribution (e.g., Marketing, Sales, Partner) |
| X | Speed to Lead | Number (minutes) | Pre-calculated minutes from MQL qualification to first sales outreach. Null if no outreach recorded. |
| Y | Contact Owner | Text | Salesforce Contact Owner — assigned rep name. Used for Speed to Lead analysis by owner. |

---

## Original Fields (Salesforce → Marketing Campaign Data: Campaign Tab)

Campaign master data with cost and date information. Row 1 is metadata, row 2 is headers, data starts row 3. 91 rows (including metadata + header).

> **New tab — replaces Master Campaign Frontend Data for campaign enrichment.** Contains campaign-level attributes (type, dates, cost) in a compact 9-column layout. Use this tab for Campaign Mapping in Lookups instead of Master Campaign Frontend Data when Start Date, End Date, or Description are needed.

| Col | Header | Type | Notes |
|-----|--------|------|-------|
| A | ADMIN Campaign 18 Digit ID | Text | Salesforce Campaign ID (join key to Campaign Members col A) |
| B | Campaign ID | Text | 15-char Salesforce Campaign ID |
| C | Parent Campaign ID | Text | Parent campaign for hierarchy grouping |
| D | Name | Text | Campaign name |
| E | Type | Text | Campaign type (Webinar, Event, Content, etc.) |
| F | Start Date | Date | Campaign start date |
| G | End Date | Date | Campaign end date |
| H | Actual Cost in Campaign | Currency | Total campaign cost |
| I | Description | Text | Campaign description |

---

## Original Fields (Salesforce → Marketing Campaign Data: Master Campaign Frontend Data Tab)

| Col | Header | Type |
|-----|--------|------|
| A | Campaign Name | Text |
| B | Campaign Type | Text |
| C | Start Date | Date |
| D | End Date | Date |
| E | Actual Cost in Campaign | Currency |
| F | Total Campaign Members | Number |
| G | Cost Per Campaign Member | Currency |
| H | Net New Leads in Campaign | Number |
| I | Percent of Net New Leads | Percentage |
| J | Cost Per Acquisition | Currency |
| K | MQLs in Campaign | Number |
| L | Percent of MQLs | Percentage |
| M | Cost per MQL | Currency |
| N | Average Demographic Score | Number |
| O | SQLs in Campaign | Number |
| P | Percent of SQLs | Percentage |
| Q | Cost per SQL | Currency |
| R | Opportunities in Campaign | Number |
| S | Value Opportunities in Campaign | Currency |
| T | Won Opportunities in Campaign | Number |
| U | Value Won Opportunities in Campaign | Currency |
| V | Campaign ID | Text |
| W | Campaign Description | Text |
| X | ADMIN Campaign 18 Digit ID | Text |
| Y | Leads in Campaign | Number |
| Z | Contacts in Campaign | Number |

---

## Original Fields (Daily Data: Opportunity Tab — Key Fields for Marketing Joins)

See `../sales/data-dictionary.md` for the full Opportunity field list. Only the fields needed for marketing joins are documented here.

| Field | Type | Purpose |
|-------|------|---------|
| ADMIN Opp ID 18 Digit | Text | Join key (matches Converted Opportunity ID) |
| ADMIN Acct ID 18 Digit | Text | Account join key |
| Account Name | Text | Account name for display |
| Name | Text | Opportunity name |
| Stage | Text | Current stage (9. Closed-Won, etc.) |
| Amount | Currency | Deal value |
| Close Date | Date | Close date |
| Opportunity Type | Text | New Business / Existing Business |
| Lead Source Attribution | Text | Marketing, Sales, Partner, etc. |
| Company Segment | Text | Commercial, Enterprise, Mid-Market, SMB, Strategic |

---

## Helper Fields (Calculated — Prepared Data Only)

These fields are derived during data prep and exist only in the analysis sheet's Prepared Data tab.

| Header | Type | Derivation | Tier |
|--------|------|-----------|------|
| Campaign Name | Text | VLOOKUP(campaign_id, Lookups campaign section, 2, FALSE) | T1 |
| Campaign Type | Text | VLOOKUP(campaign_id, Lookups campaign section, 3, FALSE) | T1 |
| Campaign Cost | Currency | VLOOKUP(campaign_id, Lookups campaign section, 4, FALSE) | T1 |
| Unified Status | Text | IF(contact_status<>"", contact_status, lead_status) | T1 |
| Unified Lifecycle Stage | Text | IF(contact_lifecycle<>"", contact_lifecycle, lead_lifecycle) | T1 |
| Unified Touch Stage | Text | IF(contact_touch<>"", contact_touch, lead_touch) | T1 |
| Unified Sort Score | Text/Number | IF(contact_sort<>"", contact_sort, lead_sort) | T1 |
| Unified Level | Text | IF(contact_level<>"", contact_level, lead_level) | T1 |
| Unified Department | Text | IF(contact_dept<>"", contact_dept, lead_dept) | T1 |
| Unified Account ID | Text | IF(account_id<>"", account_id, converted_account_id) | T1 |
| Unified MQL Start Date | Date | IF(c_mql_start<>"", c_mql_start, mql_start) | T1 |
| Unified MQL End Date | Date | IF(c_mql_end<>"", c_mql_end, mql_end) | T1 |
| Unified SAL Start Date | Date | IF(contact_sal_start<>"", contact_sal_start, lead_sal_start) — via Lifecycle Mappings. Wrap in DATEVALUE. | T1 |
| Unified SAL End Date | Date | IF(contact_sal_end<>"", contact_sal_end, lead_sal_end) — via Lifecycle Mappings. Wrap in DATEVALUE. | T1 |
| Unified SQL Start Date | Date | IF(contact_sql_start<>"", contact_sql_start, lead_sql_start) — via Lifecycle Mappings. Wrap in DATEVALUE. | T1 |
| Unified SQL End Date | Date | IF(contact_sql_end<>"", contact_sql_end, lead_sql_end) — via Lifecycle Mappings. Wrap in DATEVALUE. | T1 |
| Campaign Start Date | Date | VLOOKUP(campaign_id, Lookups campaign section, start_date_col, FALSE) | T1 |
| Campaign End Date | Date | VLOOKUP(campaign_id, Lookups campaign section, end_date_col, FALSE) | T1 |
| Unified Lead Source | Text | IF(contact_lead_source<>"", contact_lead_source, lead_lead_source) — Contact Lead Source (col W) first, Lead Lead Source (col S) fallback, via Lifecycle Mappings | T1 |
| Unified Touch Stage 1 Date | Date | IF(contact_touch_stage_1<>"", contact_touch_stage_1, lead_touch_stage_1) — Contact col S first, Lead col Q fallback, via Lifecycle Mappings | T1 |
| Unified Create Date | Date | IF(contact_lead_start<>"", contact_lead_start, lead_create_date) — Contact C Lead Start Datetime (col U) first, Lead Create Date (col R) fallback, via Lifecycle Mappings. Represents when person first entered system. | T1 |
| Unified Opportunity Datetime | Datetime | Contact C Opportunity Start Datetime (col V) via Contact Lifecycle Mapping. Contacts only — leads do not have this field. | T1 |
| Origin Type | Text | IF(converted_from_lead="TRUE", "Lead", "Contact") | T1 |
| Start Mo | Text | TEXT(DATEVALUE(LEFT(start_date,10)), "YYYYMM") | T1 |
| Start Qtr | Text | VLOOKUP(MONTH(...), Lookups fiscal, 2, FALSE) | T1 |
| Start Fiscal | Number | YEAR(...) + VLOOKUP(MONTH(...), Lookups fiscal, 3, FALSE) | T1 |
| Lifecycle Rank | Number | VLOOKUP(unified_lifecycle, Lookups lifecycle, 3, FALSE) | T2 |
| Is MQL+ | Text | VLOOKUP(unified_lifecycle, Lookups lifecycle, 4, FALSE) | T2 |
| Is SQL+ | Text | VLOOKUP(unified_lifecycle, Lookups lifecycle, 5, FALSE) | T2 |
| Is SAL+ | Text | VLOOKUP(unified_lifecycle, Lookups lifecycle, 6, FALSE) | T2 |
| Is Marketing Source | Text | IF(Unified Lead Source = "Marketing", "Yes", "No") | T2 |
| Has Opportunity | Number | IF(converted_opp_id<>"", 1, 0) | T2 |
| Days Lead to MQL | Number | IF(AND(Unified MQL Start Date<>"", Unified Create Date<>""), Unified MQL Start Date - Unified Create Date, "") | T2 |
| Days MQL to SAL | Number | IF(AND(Unified SAL Start Date<>"", Unified MQL Start Date<>""), Unified SAL Start Date - Unified MQL Start Date, "") | T2 |
| Days SAL to SQL | Number | IF(AND(Unified SQL Start Date<>"", Unified SAL Start Date<>""), Unified SQL Start Date - Unified SAL Start Date, "") | T2 |
| Days SQL to Opp | Number | IF(AND(Unified Opportunity Datetime<>"", Unified SQL Start Date<>""), Unified Opportunity Datetime - Unified SQL Start Date, "") | T2 |
| Days Lead to Opp | Number | IF(AND(Unified Opportunity Datetime<>"", Unified Create Date<>""), Unified Opportunity Datetime - Unified Create Date, "") | T2 |
| Opp Stage | Text | IF(opp_id="","", VLOOKUP(opp_id, Lookups opp, 3, FALSE)) | T2 |
| Opp Amount | Currency | IF(opp_id="","", VLOOKUP(opp_id, Lookups opp, 4, FALSE)) | T2 |
| Opp Close Date | Date | IF(opp_id="","", VLOOKUP(opp_id, Lookups opp, 5, FALSE)) | T2 |
| Opp Type | Text | IF(opp_id="","", VLOOKUP(opp_id, Lookups opp, 6, FALSE)) | T2 |
| Account Name | Text | IF(unified_acct_id="","", VLOOKUP(unified_acct_id, Lookups acct, 2, FALSE)) | T2 |
| Quarter Label | Text | "FY"&start_fiscal&" "&start_qtr | T2 |
| Is Closed Won Opp | Number | IF(opp_stage="9. Closed-Won", 1, 0) | T3 |
| Sort Score Numeric | Number | IF(ISNUMBER(unified_sort), unified_sort, VALUE(unified_sort)) | T3 |
| New vs Previously Engaged | Text | IF(start_date <= unified_create_date, "Previously Engaged", "New") — uses Unified Create Date from Tier 1 | T3 |
| Unified Speed to Lead | Number (minutes) | IF(contact_id<>"", VLOOKUP(contact_id, Lookups Contact STL+Owner section, 2, FALSE), IF(lead_id<>"", VLOOKUP(lead_id, Lookups Lead STL+Owner section, 2, FALSE), "")) — Contact-first precedence | T1 |
| Unified Owner | Text | IF(contact_id<>"", VLOOKUP(contact_id, Lookups Contact STL+Owner section, 3, FALSE), IF(lead_id<>"", VLOOKUP(lead_id, Lookups Lead STL+Owner section, 3, FALSE), "")) — Contact Owner first, Lead Owner fallback | T1 |
| MQL Quarter Label | Text | "FY"&(YEAR(Unified MQL Start Date)+VLOOKUP(MONTH(...),fiscal,3,FALSE))&" "&VLOOKUP(MONTH(...),fiscal,2,FALSE) — Fiscal quarter derived from MQL Start Date, not campaign Start Date | T2 |

---

## Lookup Mappings

These sections are built in the Lookups tab of each analysis sheet.

| Section | Columns | Headers | Source | Purpose |
|---------|---------|---------|--------|---------|
| Campaign Mapping | A-G | Campaign 18 Digit ID, Campaign ID, Name, Type, Start Date, End Date, Actual Cost | Raw Campaign Data (Campaign tab) | VLOOKUP join for campaign attributes incl. dates |
| Opportunity Mapping | I-O | Opp ID 18 Digit, Account Name, Stage, Amount, Close Date, Opp Type, Company Segment | Raw Opportunities | VLOOKUP join for opp enrichment |
| Account Mapping | Q-S | Account ID, Account Name, Company Segment | Raw Opportunities (deduplicated by Account ID) | VLOOKUP join for account enrichment |
| Lifecycle Stage Mapping | U-Z | Lifecycle Stage, Category, Rank, Is MQL+, Is SQL+, Is SAL+ | Hardcoded from metrics.md | Drives lifecycle helper columns |
| Fiscal Period Mapping | AB-AD | Month Number, Fiscal Quarter, FY Add | Hardcoded (same as sales) | Fiscal period derivation |
| Campaign Type Mapping | AF-AG | Campaign Type, Campaign Type Category | Distinct values from Raw Campaign Data | Optional grouping (placeholder for user) |
| Lead Lifecycle Mapping | AI-AQ | ADMIN Lead ID 18 Digit, SAL Start Datetime, SAL End Datetime, SQL Start Datetime, SQL End Datetime, Lead Lifecycle Stage, Lead Source, Create Date, Touch Stage 1 Date | Raw Leads | VLOOKUP join for SAL/SQL date enrichment + lead source/dates on Campaign Members rows |
| Contact Lifecycle Mapping | AS-BC | ADMIN Contact ID 18 Digit, C SAL Start Datetime, C SAL End Datetime, C SQL Start Datetime, C SQL End Datetime, Contact Lifecycle Stage, Lead Source, Touch Stage 1 Date, C Lead Start Datetime, C Opportunity Start Datetime, Converted from Lead | Raw Contacts | VLOOKUP join for SAL/SQL date enrichment + lead source/dates/opp datetime on Campaign Members rows |
| Lead STL + Owner Mapping | BE-BG | ADMIN Lead ID 18 Digit, Speed to Lead, Lead Owner | Raw Leads | VLOOKUP join for Speed to Lead and Lead Owner enrichment |
| Contact STL + Owner Mapping | BI-BK | ADMIN Contact ID 18 Digit, Speed to Lead, Contact Owner | Raw Contacts | VLOOKUP join for Speed to Lead and Contact Owner enrichment |
