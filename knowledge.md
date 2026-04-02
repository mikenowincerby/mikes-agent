# Institutional Knowledge

Stable rules, references, and data model notes accumulated across sessions. Tracked in git.

---

## Feedback

### Daily Data Sheet is Read-Only
The Daily Data sheet ($DAILY_DATA — see sources.md) is READ-ONLY. It contains Salesforce data refreshed daily.
- Never add tabs to it
- Never write data to it
- Only read from it as a data source
- When producing output, create a new standalone Google Sheet instead.

### Formula-First for All Sheet Outputs
Every Google Sheet — interactive analysis OR automated report — must use formulas backed by source data.
- **Data tab**: Script writes filtered raw rows (backing data)
- **Report tab**: Script writes FORMULAS that reference the Data tab (SORT, RANK, FILTER, etc.)
- **No static values**: Rankings, groupings, aggregations are all formulas — never pre-computed by jq/Python
- **Why**: Auditability (click a cell, see derivation), Reusability (change filter → results update), Trust ("show me the formula" always answerable)
- See: `business-logic/_shared/formula-rules.md`

### gws CLI Is the Default
- **Interactive sessions**: ALWAYS use `gws` CLI. Never use raw curl to googleapis.com.
- **CI/CD (GitHub Actions)**: Raw API calls permitted because gws can't be installed. Use OAuth refresh token flow (not service account JWT) so operations run as the user.
- **Why OAuth over SA**: Service accounts have 0 Drive quota — they can't create new spreadsheets.

### gws CLI Keyring Stderr Line
The gws CLI outputs "Using keyring backend: keyring" as the first line to stderr (and sometimes stdout). This breaks JSON parsing when piping output to python3 or jq. Workaround: capture output and strip the first line if it starts with "Using". Do NOT pipe gws output directly to JSON parsers via shell.

### Account Owner Field
The Account tab's `Full Name` column (col index 16) is the **Account Owner** — the sales rep who owns the account. This is the authoritative field for account ownership. Do NOT infer account ownership from Opportunity.Full Name (that's the opp rep, and only covers accounts with active opps). The Account tab has ~16K+ rows — always paginate pulls.

### LOI and Service Swap Filtering
LOI and Service Swap are excluded via different fields:
- **LOI:** Filter on `Opportunity Type` (LOI appears as a distinct Opp Type value)
- **Service Swap:** Filter on `Services Swap Opp` field (dedicated boolean/flag column in Opportunity tab)
- **Why:** AP-2 in anti-patterns.md groups them together, but they live in different fields. Never filter by opp name string matching.

### Numeric Columns Must Use USER_ENTERED
When copying raw data to Prepared Data with valueInputOption=RAW, numeric columns (Amount, ARR, etc.) are stored as text strings. SUMIFS/COUNTIFS/AVERAGEIFS silently return 0 when summing text. Fix: rewrite numeric columns with valueInputOption=USER_ENTERED so Sheets treats them as numbers.

---

## References

### FY2027 Targets
- **Location:** Daily Data sheet ($DAILY_DATA — see sources.md), tab "FY2027 Targets"
- **Columns:** Quarterly snapshots — 1/1/2026, 4/1/2026, 7/1/2026, 10/1/2026, 1/1/2027
- **Contents:** Planning model targets — product ASPs & sales cycles (IdLCM, Social Media), Ending ARR ($7.3M→$14.6M), New ARR, conversion rates by channel (Marketing/Sales/Partner), cost per opp, pipeline required by channel, Marketing OpEx
- **Added:** 2026-03-26. Exception to Daily Data read-only rule — user approved.

### Marketing Pipeline by Quarter x Segment Sheet
- **Sheet ID:** `1ry6MGF5HL69M0hgg3nKoU-YG8lewgOJdJAHDut7a9ug`
- **Tabs:** Summary, Deal List, Raw Data, Prepared Data, Lookups, Definitions
- **Filters:** Lead Source Attribution = Marketing, Opportunity Type = New Business
- **Date anchor:** Stage 2. Discovery Start Date
- **Time range:** FY2026 Q1 through FY2027 Q1
- **Source:** Daily Data Sheet
- **Result:** $9.16M total pipeline, 118 deals across 5 segments

---

## Data Model

### Key Data Sources
| Source | Sheet ID | Notes |
|--------|----------|-------|
| Daily Data | `$DAILY_DATA` | Opportunity, Account, Contract Details, Forecast Accuracy, **FY2027 Targets** tabs. Daily Salesforce refresh. **READ-ONLY** (except FY2027 Targets — manually added) (see sources.md for connection details) |
| Marketing Campaign Data | `$MARKETING_DATA` | Master Campaign Frontend, Campaign Members, Leads, Contacts. Auto Salesforce refresh. **READ-ONLY** (see sources.md for connection details) |
| Average Deal Size Analysis | `1mwy-KKYcafS33ta5HzaPRPKiTczU7emZmGCs95Dqg14` | |
| Marketing Pipeline Q x Segment | `1ry6MGF5HL69M0hgg3nKoU-YG8lewgOJdJAHDut7a9ug` | |

### Business Constants
- **Fiscal Calendar:** FY = CY+1 (Feb-Dec), CY (Jan). Q1=Feb-Apr, Q2=May-Jul, Q3=Aug-Oct, Q4=Nov-Jan
- **Company Segments:** Commercial, Enterprise, Mid-Market, SMB, Strategic
- **Lead Source Attribution:** Marketing, Sales, Partner, Customer Success, Other

### Renewal vs Expansion Field (Opportunity)
- **Source:** CS Data sheet, Opportunity tab — field "Renewal vs Expansion"
- **Values:** Renewal, Expansion, New, Renewal & Expansion, blank
- **Usage:** Churn Risk Flag and Churn Rate identification are scoped to renewal-type opps only (Renewal, Renewal & Expansion). An account with only Expansion opps open is still at risk / can be classified as churned.
- **Added:** 2026-03-27

### gws CLI Notes
- batchUpdate: spreadsheetId goes in `--params`, requests in `--json`
- Sheet names with spaces work in values update/get without quoting (gws handles it)
- autoResizeDimensions via batchUpdate returns httpError — use manual column resize
