# Data Dictionary

Field reference for sales data. Separates original Salesforce fields from calculated helper fields.

---

## Data Sources

| Source | Sheet ID | Tabs | Refresh |
|--------|----------|------|---------|
| Daily Data | `$DAILY_DATA` | Opportunity, Account | Daily |
| Reference/Learning | `1PLoXKe69elkvHC1RbBHdfe-lQ92m7XZ64inQHHjxApo` | PipeGen, Bookings, Opportunity, Map, Lookups | Reference |

**Daily Data** is the primary source for all analyses. Always pull fresh from this sheet.
**Reference/Learning** contains the metric models (PipeGen, Bookings tabs), enriched Opportunity data (41 cols), and lookup tables (Map, Lookups).

---

## Original Fields (Salesforce → Daily Data: Opportunity Tab)

| Field | Type | Description |
|-------|------|-------------|
| ADMIN Opp ID 18 Digit | Text | Salesforce Opportunity ID (unique key) |
| ADMIN Acct ID 18 Digit | Text | Salesforce Account ID (joins to Account tab) |
| Account Name | Text | Company name |
| Name | Text | Opportunity name |
| Full Name | Text | Sales rep full name |
| Opportunity Type | Text | "New Business" or "Existing Business" |
| Stage | Text | Current stage: 1. Lead Verification, 2. Discovery, 3. Scoping, 4. Solution Validation \| Trial, 5. Solutions Proposal, 6. Negotiate and Close, 9. Closed-Won, 10. Closed-Lost, 11. Qualified-Out |
| Created Date | Date | When opportunity was created in Salesforce |
| Stage 2. Discovery Start Date | Date | When opp entered Stage 2 — **pipeline threshold** |
| Stage 3. Scoping Start Date | Date | When opp entered Stage 3 |
| Stage 4. Solution Validation Start Date | Date | When opp entered Stage 4 |
| Stage 5. Solutions Proposal Start Date | Date | When opp entered Stage 5 |
| Stage 6. Negotiate and Close Start Date | Date | When opp entered Stage 6 |
| Close Date | Date | Actual (closed deals) or expected (open deals) close date |
| Amount | Currency | Deal value. Use for New Business bookings and pipeline value. |
| Amount (Weighted) | Currency | Amount × stage probability (column position varies — discover dynamically) |
| CSM created | Boolean | Whether a CSM created the opportunity |
| CSM Sourced | Boolean | Whether a CSM sourced the opportunity |
| Lead Source | Text | Original lead source (granular) |
| Lead Source Attribution | Text | Attributed source: Marketing, Sales, Partner, Other |
| Primary Use Case | Text | Granular use case from Salesforce |
| Sales Play | Text | Sales motion/play |
| Company Segment | Text | Company size/tier classification |
| Subskribe Order Delta ARR | Currency | Net ARR change from subscription system. $0 = flat renewal, positive = expansion, negative = contraction. |
| Forecast Category | Text | Sales forecast category |

## Original Fields (Salesforce → Daily Data: Account Tab)

| Field | Type | Description |
|-------|------|-------------|
| Account Name | Text | Company name |
| ADMIN Acct ID 18 Digit | Text | Salesforce Account ID (joins to Opportunity tab) |
| Account Type | Text | Prospect, Customer, etc. |
| Account Role | Text | e.g., "Customer / Potential Customer" |
| Customer Lifecycle Stage | Text | Prospect, Expansion Opportunity, etc. |
| Partner Account | Text | Partner association |
| Workspace | Text | Cerby workspace |
| Implementation Manager | Text | Assigned IM |
| Customer Success Manager | Text | Assigned CSM |
| Unthread Customer ID | Text | Support system ID |
| JIRA Customer ID | Text | JIRA integration ID |
| Rillet ID | Text | Billing system ID |
| Amount Won Opportunities | Currency | Total won Amount for this account |
| ADMIN HubSpot Acct ID | Text | HubSpot account ID |
| Company Region | Text | Geographic region (e.g., North America, LATAM) |
| Company Segment | Text | Company size/tier classification |
| Full Name | Text | **Account Owner** — the sales rep who owns this account. This is the authoritative field for account ownership. Do NOT infer account ownership from the Opportunity tab's Full Name field (that only covers accounts with active opps). |

---

## Helper Fields (Calculated/Derived — Not in Daily Data)

These fields exist in the Reference sheet's Opportunity tab but must be derived when working from the Daily Data source.

| Field | Type | Derivation |
|-------|------|-----------|
| Sales Cycle Days | Number | Close Date - Stage 2. Discovery Start Date (only for Closed-Won where Stage 2. Discovery Start Date exists). Lost deals are excluded — they don't represent completed sales cycles. Same as Pipeline Velocity Days. |
| Pipeline Velocity Days | Number | Same as Sales Cycle Days |
| New Biz Won Before This Deal | Number | Count of prior Closed-Won New Business opps for the same ADMIN Acct ID 18 Digit, ordered by Close Date |
| Logo Count | Number | 1 if Opportunity Type = "New Business" AND Stage = "9. Closed-Won" AND New Biz Won Before This Deal = 0; else 0 |
| Age | Number | Close Date - Created Date (closed deals) OR Today - Created Date (open deals) |
| Days Since Create | Number | Same as Age |
| Use Case | Text | Mapped from Primary Use Case via Map tab (e.g., "Social Media Access" stays "Social Media Access") |
| Expansion ARR | Currency | If Opportunity Type = "Existing Business" AND Subskribe Order Delta ARR > 0: Subskribe Order Delta ARR; else 0 |
| Pipeline Category | Text | Mapped from Stage: 1 → PrePipeline, 2-6 → Pipeline, 9 → Won, 10 → Lost, 11 → QualifiedOut |
| Detail Pipeline Category | Text | Mapped from Stage: 1 → PrePipeline, 2-3 → Early Pipeline, 4-5 → Mid Pipeline, 6 → Late Pipeline, 9 → Won, 10 → Lost, 11 → QualifiedOut |
| CreateWk | Text | ISO week of Created Date |
| CreateMo | Text | YYYYMM code of Created Date (e.g., "202502") |
| CreateQtr | Text | Fiscal quarter of Created Date (e.g., "FY2026 Q1") |
| Create Fiscal | Number | Fiscal year of Created Date (e.g., 2026) |
| CloseMo | Text | YYYYMM code of Close Date |
| CloseQtr | Text | Fiscal quarter of Close Date |
| Close Fiscal | Number | Fiscal year of Close Date |
| Pacing | Text | Deal pacing — derived from Age vs stage progression benchmarks (see `metrics.md` stage table) |
| Stage 1? | Boolean | 1 if Stage = "1. Lead Verification", else 0 |
| Close Month in Quarter | Number | Which month in the fiscal quarter the deal closes (1, 2, or 3) |
| Closed? | Boolean | 1 if Stage starts with "9." or "10.", else 0 |
| Reached S2 | Boolean | 1 if Stage 2. Discovery Start Date is not blank, else 0. **Use for stage progression analysis — do not infer from current Stage.** |
| Reached S3 | Boolean | 1 if Stage 3. Scoping Start Date is not blank, else 0 |
| Reached S4 | Boolean | 1 if Stage 4. Solution Validation Start Date is not blank, else 0 |
| Reached S5 | Boolean | 1 if Stage 5. Solutions Proposal Start Date is not blank, else 0 |
| Reached S6 | Boolean | 1 if Stage 6. Negotiate and Close Start Date is not blank, else 0 |
| Is Closed Won | Boolean | 1 if Stage = "9. Closed-Won", else 0 |
| Is Closed Lost | Boolean | 1 if Stage = "10. Closed-Lost", else 0 |

---

## Lookup Mappings (from Reference Sheet: Map Tab)

### Primary Use Case → Use Case

| Primary Use Case (raw) | Use Case (mapped) |
|------------------------|-------------------|
| Social Media Access | Social Media Access |
| Access Management (EPM, SSO, MFA) | Access Management (EPM, SSO, MFA) |
| Identity Lifecycle Management (JML) | Identity Lifecycle Management (JML) |
| *(anything else)* | Other |

**Important:** Raw `Primary Use Case` values in Salesforce are already the correct canonical labels. Do not simplify or shorten them (e.g., do NOT map "Access Management (EPM, SSO, MFA)" → "Access Management"). "Identity Security" is NOT a valid use case — the correct value is "Identity Lifecycle Management (JML)". Always verify raw values from source data before writing Lookups mappings.

### Primary Use Case → Sales Play

| Primary Use Case (raw) | Sales Play |
|------------------------|-----------|
| Social Media Access | Sales Play 2 - Identity Automations |
| Access Management (EPM, SSO, MFA) | *(from Map tab)* |
| Identity Lifecycle Management (JML) | *(from Map tab)* |

*Note: Exact Sales Play mappings should be read from the Map tab at runtime, as they may be updated.*

### Month Code → Fiscal Period

| Month | Fiscal Quarter | Month in Quarter | FY Add |
|-------|---------------|-----------------|--------|
| January | Q4 | 3 | 0 |
| February | Q1 | 1 | 1 |
| March | Q1 | 2 | 1 |
| April | Q1 | 3 | 1 |
| May | Q2 | 1 | 1 |
| June | Q2 | 2 | 1 |
| July | Q2 | 3 | 1 |
| August | Q3 | 1 | 1 |
| September | Q3 | 2 | 1 |
| October | Q3 | 3 | 1 |
| November | Q4 | 1 | 1 |
| December | Q4 | 2 | 1 |

FY = Calendar Year + FY Add. E.g., March 2025 → FY Add = 1 → FY2026.
