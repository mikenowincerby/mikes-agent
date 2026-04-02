# Source Registry

Central configuration for all data sources. Every pipeline reads connection details from this file — Sheet IDs, adapters, and schema requirements live here instead of being hardcoded across domain configs.

**To configure:** Edit the Sources table below directly, or use the setup wizard (`skills/setup.md`) to configure interactively. Column and value mappings let you adapt the system to data with different naming conventions without changing pipeline logic.

---

## Sources

| Alias | Adapter | Connection | Notes |
|-------|---------|------------|-------|
| DAILY_DATA | google-sheets | `13bmyVaMfh9SR2z0mi7HnQCXLAlkqQcolUeJ7q6ZYlYc` | Daily Salesforce refresh. READ-ONLY except FY2027 Targets (manual). Used by: Sales Analytics, Marketing Analytics (secondary), Ops Forecast. |
| MARKETING_DATA | google-sheets | `1rkuB6sbsKxkXv_DzlGff0oHKTFEHXMw_SDniErYiX8E` | Auto Salesforce refresh. READ-ONLY. Row 1 = metadata, Row 2 = headers, data starts Row 3 (except Master Campaign Frontend Data). Used by: Marketing Analytics (primary), Marketing Workbench. |
| CS_DATA | google-sheets | `1MlqIcr9O99-KJu7ngizl2k18FHYdq3JAQhAVMifLPsI` | Daily Salesforce refresh. READ-ONLY. Used by: Customer Success Analytics. |

### Tabs by Source

**DAILY_DATA:** Opportunity, Account, Forecast Accuracy, FY2027 Targets, Contract Details

**MARKETING_DATA:** Campaign Members, Campaign, Leads, Contacts, Master Campaign Frontend Data

**CS_DATA:** Opportunity, Account, Subskribe Order Line, User

---

## Column Mappings

<!-- Populated by the setup wizard when the user's data has different column names than the canonical names below. Maps user-specific column headers to the canonical names used by pipeline logic. -->

| Alias | Tab | User Column | Canonical Column |
|-------|-----|-------------|------------------|
| | | | |

---

## Value Mappings

<!-- Populated by the setup wizard when the user's data uses different categorical values than the canonical values expected by pipeline logic (e.g., "Won" vs "Closed Won"). -->

| Alias | Column | User Value | Canonical Value |
|-------|--------|------------|-----------------|
| | | | |

---

## Schema Requirements

Minimum required columns per source and tab. For complete field references, see the full data dictionaries:
- Sales: `business-logic/sales/data-dictionary.md`
- Marketing: `business-logic/marketing/data-dictionary.md`
- Customer Success: `business-logic/customer-success/data-dictionary.md`

### DAILY_DATA — Opportunity

| Column | Type | Required | Description |
|--------|------|----------|-------------|
| ADMIN Opp ID 18 Digit | text | yes | Unique opportunity key |
| Account Name | text | yes | Associated account |
| Opportunity Type | text | yes | "New Business" or "Existing Business" |
| Stage | text | yes | Pipeline stage |
| Created Date | date | yes | Opportunity creation date |
| Stage 2. Discovery Start Date | date | yes | Pipeline threshold date |
| Close Date | date | yes | Expected or actual close date |
| Amount | numeric | yes | Deal value |
| Lead Source Attribution | text | yes | Marketing attribution |
| Primary Use Case | text | yes | Product use case |
| Company Segment | text | yes | Account segment |
| Full Name | text | yes | Rep name |
| Subskribe Order Delta ARR | numeric | yes | Net ARR change |
| Forecast Category | text | yes | For forecast analysis |

### MARKETING_DATA — Campaign Members

| Column | Type | Required | Description |
|--------|------|----------|-------------|
| ADMIN Campaign 18 Digit ID | text | yes | Join key to Campaign tab |
| Campaign Member ID | text | yes | Unique member key |
| Name | text | yes | Contact/lead name |
| Status | text | yes | Membership status |
| Start Date | date | yes | Campaign start date |
| ADMIN Contact ID 18 Digit | text | yes | Join key to contacts |
| Account ID | text | yes | Associated account |
| ADMIN Lead ID 18 Digit | text | yes | Join key to leads |
| Converted Opportunity ID | text | yes | Join key to opportunities |

### CS_DATA — Opportunity

| Column | Type | Required | Description |
|--------|------|----------|-------------|
| ADMIN Opp ID 18 Digit | text | yes | Unique opportunity key |
| ADMIN Acct ID 18 Digit | text | yes | Join key to Account tab |
| Account Name | text | yes | Associated account |
| Stage | text | yes | Pipeline stage |
| Amount | numeric | yes | Deal value |
| Subskribe Order Delta ARR | numeric | yes | Net ARR change |
| CSM Sourced / CSM Created | boolean | yes | Whether CSM originated the deal |
| Close Date | date | yes | Expected or actual close date |
| Opportunity Type | text | yes | "New Business" or "Existing Business" |

### CS_DATA — Account

| Column | Type | Required | Description |
|--------|------|----------|-------------|
| ADMIN Acct ID 18 Digit | text | yes | Unique account key |
| Account Name | text | yes | Account name |
| Customer Lifecycle Stage | text | yes | Lifecycle stage |
| Customer Success Manager | text | yes | Assigned CSM |
| ARR | numeric | yes | Annual recurring revenue |
| Account Health | text | yes | Health score/rating |
| Company Segment | text | yes | Account segment |
