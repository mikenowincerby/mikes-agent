# Marketing Workbench — Source Sheets

Two source sheets provide live data via IMPORTRANGE:

## Marketing Campaign Data (`$MARKETING_DATA`)

| Tab | Rows | Key Fields | IMPORTRANGE Range |
|-----|------|------------|-------------------|
| Campaign Members | 9,381 | Campaign ID (A), Contact ID (G), Lead ID (Q), Account ID (H), Status (E/T), Lifecycle Stage (J/U), MQL dates (K-L/W-X), Touch Stage (M/V), Sort Score (N/Y), Level (O/Z), Department (P/AA), Converted Opp ID (AB), Converted from Lead (AD/AG) | `Campaign Members!A2:AG` |
| Leads | 12,705 | Lead ID (E), Department (F), Level (G), Lifecycle Stage (H), Sort Score (I), MQL Start/End (K/L), SAL Start/End (M/N), SQL Start/End (O/P), Touch Stage 1 Date (Q), Create Date (R), Lead Source (S), Speed to Lead (T), Lead Owner (U) | `Leads!A2:U` |
| Contacts | 30,431 | Contact ID (F), Acct ID (G), Department (H), Level (I), Lifecycle Stage (J), SAL Start/End (K/L), SQL Start/End (M/N), Sort Score (O), MQL Start/End (Q/R), Touch Stage 1 Date (S), Converted from Lead (T), C Lead Start (U), C Opportunity Start (V), Lead Source (W), Speed to Lead (X), Contact Owner (Y) | `Contacts!A2:Y` |
| Campaign | 91 | Campaign 18-Digit ID (A), Campaign ID (B), Parent Campaign ID (C), Name (D), Type (E), Start Date (F), End Date (G), Actual Cost (H), Description (I) | `Campaign!A2:I` |
| Master Campaign Frontend Data | ~91 | Campaign-level aggregates — validation reference for Model #1 only | `Master Campaign Frontend Data!A2:Z` |

All tabs have Row 1 = metadata/timestamp, Row 2 = headers, data from Row 3. IMPORTRANGE starts at A2 to skip metadata.

## Daily Data (`$DAILY_DATA`) — READ-ONLY

| Tab | Key Fields | IMPORTRANGE Range |
|-----|------------|-------------------|
| Opportunity | Opp ID, Account ID, Account Name, Stage, Amount, Close Date, Opp Type, Lead Source Attribution, Company Segment | `Opportunity!A1:AC` |

Row 1 = headers (no metadata row). IMPORTRANGE starts at A1.

## IMPORTRANGE Setup

Each raw tab uses a single IMPORTRANGE formula in cell A1:

```
=IMPORTRANGE("sheet_id", "Tab Name!A2:XX")
```

- Starts at row 2 to skip the metadata row — row 1 of IMPORTRANGE output = headers
- Data stays live and current as source sheets refresh daily
- **Authorization:** First use requires one-time manual approval per source-destination sheet pair. Verify each IMPORTRANGE resolves before proceeding to Lookups.
- For Daily Data (no metadata row), start at A1: `=IMPORTRANGE("sheet_id", "Opportunity!A1:AC")`
