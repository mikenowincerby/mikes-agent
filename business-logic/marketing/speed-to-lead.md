# Speed to Lead

**Priority:** High — this is a key operational health metric for BizOps.

## Definition

Speed to Lead measures the minutes from MQL qualification to the first sales outreach. Faster response = higher conversion. This metric is pre-calculated in Salesforce and available in the source Marketing Campaign Data sheet.

## Why It Matters

- Response time to MQLs directly impacts conversion rates
- Analyzed by Lead/Contact Owner for individual accountability
- Tracked quarterly to identify trends and operational gaps

## Source Fields

| Source | Field | Column |
|--------|-------|--------|
| Leads tab | Speed to Lead | T |
| Leads tab | Lead Owner | U |
| Contacts tab | Speed to Lead | X |
| Contacts tab | Contact Owner | Y |

## Prepared Data Columns

| Column | Header | Logic |
|--------|--------|-------|
| CB | Unified Speed to Lead | Contact STL first (via Lookups BI:BJ), Lead STL fallback (via Lookups BE:BF) |
| CC | Unified Owner | Contact Owner first (via Lookups BI:BK), Lead Owner fallback (via Lookups BE:BG) |
| CD | MQL Quarter Label | Fiscal quarter derived from Unified MQL Start Date (not campaign Start Date) |

## Analysis Dimensions

- **By Quarter:** Avg and Median STL per fiscal quarter
- **By Owner:** Avg and Median STL per Lead/Contact Owner
- **Conversion alongside STL:** MQL→SAL and MQL→SQL rates by quarter and owner

## Notes

- Some Speed to Lead values are negative (outreach occurred before MQL date)
- Median is more representative than average due to outliers
- Zero values are excluded from STL analysis (indicate no outreach recorded)
- Median is computed in Python (no conditional MEDIAN in Google Sheets)
