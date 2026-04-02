# Data Dictionary

Field reference for customer success data. Separates original Salesforce fields from calculated helper fields.

---

## Data Sources

| Source | Sheet ID | Tabs | Refresh |
|--------|----------|------|---------|
| CS Data | `$CS_DATA` | Opportunity, Account, Subskribe Order Line, User | Daily (Salesforce import) |

**CS Data** is the primary source for all CS analyses. Always pull fresh from this sheet. This sheet is **READ-ONLY** — never write to it.

---

## Original Fields — Opportunity Tab (1016 rows, 25 cols)

| Field | Type | CS Usage |
|-------|------|----------|
| ADMIN Opp ID 18 Digit | Text | Unique key |
| ADMIN Acct ID 18 Digit | Text | Join to Account tab |
| Account Name | Text | Display |
| Name | Text | Opportunity name |
| Full Name | Text | Rep name |
| CSM Sourced | Boolean (TRUE/FALSE) | CSQL filter — TRUE = CSM identified this opportunity |
| CSM created | Boolean | Whether CSM created the opp record |
| Customer Success Manager | Text | CSM on the opportunity |
| Implementation Manager | Text | IM on the opportunity |
| Primary Use Case | Text | Use case (map via Lookups) |
| Lead Source | Text | Original lead source |
| Lead Source Attribution | Text | Attributed source (Marketing, Sales, Partner, Other) |
| Company Segment | Text | Segment dimension |
| Subskribe Order Delta ARR | Currency | Net ARR change from subscription system |
| Forecast Category | Text | Forecast bucket |
| Contract Start Date | Date | Contract start (for future TTV metric) |
| Contract End Date | Date | Contract end |
| Stage 2. Discovery Start Date | Date | Pipeline threshold — when opp entered Stage 2 |
| Created Date | Date | When opp was created in Salesforce |
| Close Date | Date | Actual or expected close date |
| Amount | Currency | Deal value |
| Opportunity Type | Text | "New Business", "Existing Business", or "LOI" |
| Stage | Text | Current stage (2. Discovery through 9. Closed-Won, 10. Closed-Lost) |
| Sales Play | Text | Sales motion |
| Services Swap Opp | Boolean | Services Swap flag — **exclude from CSQL counts** |
| Renewal vs Expansion | Text | Classifies opp: Renewal, Expansion, New, Renewal & Expansion, or blank. Used to scope churn/risk to renewal-type opps only. |

---

## Original Fields — Account Tab (16720 rows, 21 cols)

| Field | Type | CS Usage |
|-------|------|----------|
| ADMIN Acct ID 18 Digit | Text | Primary key, join to Opp and Order Line |
| Account Name | Text | Display |
| Account Type | Text | Customer type classification |
| Account Role | Text | Role classification |
| Customer Lifecycle Stage | Text | Active, Engaged, Expansion Opportunity, Opportunity, Prospect |
| Partner Lifecycle Stage | Text | Partner status |
| Partner Account | Text | Partner flag |
| Customer Success Manager | Text | Assigned CSM |
| Customer Success Next Steps | Text | CS action items |
| Customer Success Package | Text | Legacy, Premium, Standard |
| ARR | Currency | Current ARR |
| Workspace | Text | Cerby workspace |
| Renewal Date | Date | Next renewal date — **churn anchor** |
| Account Health | Text | Positive, Slightly Positive, Neutral, Slightly Negative |
| Customer Risk Reason | Text | Risk reason (free text) |
| Cerby Product | Text | Product |
| Use Case | Text | Account-level use case |
| Expansion Potential | Text | Cross Sell, None Today, Upsell |
| Expansion Potential Description | Text | Details on expansion potential |
| Implementation Manager | Text | Assigned IM |
| Company Segment | Text | Segment dimension |

---

## Original Fields — Subskribe Order Line Tab (1155 rows, 13 cols)

| Field | Type | CS Usage |
|-------|------|----------|
| ADMIN Acct ID 18 Digit | Text | Join to Account tab |
| Plan Name | Text | Subscription plan name |
| Product Name | Text | Product name |
| Subskribe Order Line Name | Text | Unique line identifier (e.g., ORD-000002846) |
| Line Start Date | Date | When this line starts |
| Line End Date | Date | When this line ends — **renewal cohort anchor** |
| Quantity | Number | Seats/units |
| TCV | Currency | Total contract value for this line |
| Entry ARR | Currency | ARR at line start |
| Exit ARR | Currency | ARR at line end |
| Delta ARR | Currency | ARR change — **validate that Delta = Exit - Entry** |
| Subskribe Order | Text | Parent order ID |
| Order End Date | Date | Order-level end date |

**ARR field note:** Sample data shows Entry ARR = Exit ARR = Delta ARR for all lines sampled. This is unexpected — Delta should be Exit - Entry. Must validate the semantics of these fields during data prep before building retention formulas. The actual relationship may be:
- Delta ARR = change from the **prior** contract to this one (not Exit - Entry within this line)
- Entry ARR = Exit ARR when the line has no mid-term changes

If Delta ARR represents change from prior contract, it maps directly to expansion/contraction and the GDR/NDR formulas simplify (no cross-row matching needed for the delta, only for identifying which lines renewed).

---

## Original Fields — User Tab (~1000 rows, 6 cols)

| Field | Type | CS Usage |
|-------|------|----------|
| Email | Text | User email |
| First Name | Text | CSM first name — combine with Last Name for display |
| Last Name | Text | CSM last name |
| User ID_18 | Text | 18-digit Salesforce User ID — join key to Account.Customer Success Manager and Opportunity.Customer Success Manager |
| User ID | Text | Same as User ID_18 |
| Title | Text | Job title |

**Purpose:** Maps Salesforce User IDs (e.g., `005Ps000008HCY1IAO`) to human-readable CSM names. Used via User Lookup in Lookups tab.

---

## Helper Fields — Prepared Data - Accounts

| Field | Tier | Type | Derivation |
|-------|------|------|-----------|
| CSM Name | 1 | Text | `IFERROR(VLOOKUP(Customer Success Manager, Lookups!UserLookup, 4, FALSE), "")` — resolves Salesforce User ID to "First Last" name |
| Use Case (Mapped) | 1 | Text | `IFERROR(VLOOKUP(Use Case, Lookups!UseCaseMapping, 2, FALSE), "Other")` |
| Is Active Customer | 1 | Text | `VLOOKUP(Customer Lifecycle Stage, Lookups!LifecycleMapping, 2, FALSE)` — Active/Expansion Opportunity/At-Risk → "Yes", Engaged/Opportunity/Prospect → "No". **Caveat:** Customer Lifecycle Stage may be stale in Salesforce — cross-check with ARR > 0 and Renewal Date populated if results look off. |
| Lifecycle Rank | 1 | Number | `VLOOKUP(Customer Lifecycle Stage, Lookups!LifecycleMapping, 3, FALSE)` |
| Health Category | 1 | Text | `VLOOKUP(Account Health, Lookups!HealthMapping, 3, FALSE)` — Green/Yellow/Red |
| Health Rank | 1 | Number | `VLOOKUP(Account Health, Lookups!HealthMapping, 2, FALSE)` |
| Renewal Mo | 1 | Text | `IF(Renewal Date="","",TEXT(DATEVALUE(LEFT(Renewal Date,10)),"YYYYMM"))` |
| Renewal Qtr | 1 | Text | `IFERROR(VLOOKUP(MONTH(DATEVALUE(LEFT(Renewal Date,10))),Lookups!FiscalMapping,2,FALSE),"")` |
| Renewal FY Add | 1 | Number | `IFERROR(VLOOKUP(MONTH(DATEVALUE(LEFT(Renewal Date,10))),Lookups!FiscalMapping,4,FALSE),0)` |
| Renewal Fiscal | 1 | Number | `IF(Renewal Date="","",YEAR(DATEVALUE(LEFT(Renewal Date,10)))+Renewal FY Add)` |
| Renewal Quarter Label | 1 | Text | `IF(Renewal Date="","","FY"&Renewal Fiscal&" "&Renewal Qtr)` |
| Has Open EB Opp | 2 | Number | `COUNTIFS(Lookups!OppAccountID, ADMIN Acct ID, Lookups!OppType, "Existing Business", Lookups!OppStage, "<>9. Closed-Won", Lookups!OppStage, "<>10. Closed-Lost")` — counts open (non-closed) EB opps for this account |
| Has Expansion Potential | 2 | Number | `IF(AND(Expansion Potential<>"", Expansion Potential<>"None Today"), 1, 0)` |
| Won Delta ARR | 2 | Number | `SUMPRODUCT((Lookups!OppAccountID=ADMIN Acct ID)*(Lookups!OppStage="9. Closed-Won")*(Lookups!OppType<>"LOI")*Lookups!OppDeltaARR)` — sum of Order Delta ARR from Closed-Won non-LOI opps. Used as primary churned ARR source. |
| Has Open Renewal Opp | 2 | Number | `COUNTIFS(Lookups!OppAccountID, ADMIN Acct ID, Lookups!OppType, "Existing Business", Lookups!OppStage, "<>9. Closed-Won", Lookups!OppStage, "<>10. Closed-Lost", Lookups!OppRenewalType, "Renewal") + COUNTIFS(Lookups!OppAccountID, ADMIN Acct ID, Lookups!OppType, "Existing Business", Lookups!OppStage, "<>9. Closed-Won", Lookups!OppStage, "<>10. Closed-Lost", Lookups!OppRenewalType, "Renewal & Expansion")` — counts open EB opps scoped to renewal-type only (Renewal or Renewal & Expansion). Two COUNTIFS summed because Sheets COUNTIFS doesn't support OR on a single criteria range. |
| Churn Risk Flag | 3 | Text | `IF(AND(Health Category="Red", Renewal Date<>"", DATEVALUE(LEFT(Renewal Date,10))<=TODAY()+90, DATEVALUE(LEFT(Renewal Date,10))>TODAY(), Has Open Renewal Opp=0), "At Risk", "")` |

**Note on Is Churned:** Churn is determined at analysis time, not as a Prepared Data helper. It requires cross-tab logic (Order Lines for active/future contracts + Opps for open EB). See `metrics.md` § Churn Rate for full definition.

## Helper Fields — Prepared Data - Order Lines

| Field | Tier | Type | Derivation |
|-------|------|------|-----------|
| Account Name | 1 | Text | `IFERROR(VLOOKUP(ADMIN Acct ID, Lookups!AccountLookup, 2, FALSE), "")` |
| CSM Name | 1 | Text | `IFERROR(VLOOKUP(VLOOKUP(ADMIN Acct ID, Lookups!AccountLookup, 6, FALSE), Lookups!UserLookup, 4, FALSE), "")` — nested: Account → CSM User ID → User Lookup → CSM Name |
| Company Segment | 1 | Text | `IFERROR(VLOOKUP(ADMIN Acct ID, Lookups!AccountLookup, 10, FALSE), "")` |
| Account Use Case | 1 | Text | `IFERROR(VLOOKUP(ADMIN Acct ID, Lookups!AccountLookup, 9, FALSE), "")` |
| Account ARR | 1 | Currency | `IFERROR(VLOOKUP(ADMIN Acct ID, Lookups!AccountLookup, 5, FALSE), 0)` |
| Account Health | 1 | Text | `IFERROR(VLOOKUP(ADMIN Acct ID, Lookups!AccountLookup, 8, FALSE), "")` |
| Line End Mo | 1 | Text | `IF(Line End Date="","",TEXT(DATEVALUE(LEFT(Line End Date,10)),"YYYYMM"))` |
| Line End Qtr | 1 | Text | `IFERROR(VLOOKUP(MONTH(DATEVALUE(LEFT(Line End Date,10))),Lookups!FiscalMapping,2,FALSE),"")` |
| Line End FY Add | 1 | Number | `IFERROR(VLOOKUP(MONTH(DATEVALUE(LEFT(Line End Date,10))),Lookups!FiscalMapping,4,FALSE),0)` |
| Line End Fiscal | 1 | Number | `IF(Line End Date="","",YEAR(DATEVALUE(LEFT(Line End Date,10)))+Line End FY Add)` |
| Line End Quarter Label | 1 | Text | `IF(Line End Date="","","FY"&Line End Fiscal&" "&Line End Qtr)` |
| Line Start Mo | 1 | Text | `IF(Line Start Date="","",TEXT(DATEVALUE(LEFT(Line Start Date,10)),"YYYYMM"))` |
| Is Expansion | 2 | Number | `IF(AND(Delta ARR<>"", VALUE(Delta ARR)>0), 1, 0)` |
| Is Contraction | 2 | Number | `IF(AND(Delta ARR<>"", VALUE(Delta ARR)<0), 1, 0)` |
| Is Flat Renewal | 2 | Number | `IF(AND(Delta ARR<>"", VALUE(Delta ARR)=0), 1, 0)` |
| Line Duration Days | 2 | Number | `IF(OR(Line End Date="",Line Start Date=""),"",DATEVALUE(LEFT(Line End Date,10))-DATEVALUE(LEFT(Line Start Date,10)))` |
**Note:** GDR/NDR no longer require compute-and-push renewal matching. They are calculated at analysis time by comparing active Order Line ARR at period start vs period end per account. See `metrics.md` § GDR and § NDR.

---

## Lookup Mappings

### Account Lookup (#1)

Data table from Raw Account tab. Key: ADMIN Acct ID 18 Digit.

| Col | Value Column |
|-----|-------------|
| 1 | ADMIN Acct ID 18 Digit (key) |
| 2 | Account Name |
| 3 | Customer Lifecycle Stage |
| 4 | Customer Success Package |
| 5 | ARR |
| 6 | Customer Success Manager |
| 7 | Renewal Date |
| 8 | Account Health |
| 9 | Use Case |
| 10 | Company Segment |
| 11 | Expansion Potential |

### Opportunity Lookup (#2)

Data table from Raw Opportunity tab. Key: ADMIN Opp ID 18 Digit.

| Col | Value Column |
|-----|-------------|
| 1 | ADMIN Opp ID 18 Digit (key) |
| 2 | ADMIN Acct ID 18 Digit |
| 3 | Stage |
| 4 | Amount |
| 5 | Close Date |
| 6 | Opportunity Type |
| 7 | CSM Sourced |
| 8 | Company Segment |
| 9 | Stage 2. Discovery Start Date |
| 10 | Subskribe Order Delta ARR |
| 11 | Renewal vs Expansion |

Also create flat columns of Opp Account IDs, Opp Types, Opp Stages, Opp Close Dates, Opp Delta ARR, Opp Renewal Type (Renewal vs Expansion) for COUNTIFS/SUMPRODUCT-based helper columns from Account Prepared Data (Has Open EB Opp, Has Open Renewal Opp, Won Delta ARR).

### Use Case Mapping (#3)

Same as sales. See `../sales/data-dictionary.md`.

| Primary Use Case (raw) | Use Case (mapped) |
|------------------------|-------------------|
| Social Media Access | Social Media Access |
| Access Management (EPM, SSO, MFA) | Access Management (EPM, SSO, MFA) |
| Identity Lifecycle Management (JML) | Identity Lifecycle Management (JML) |
| *(anything else)* | Other |

### Fiscal Period Mapping (#4)

Same as sales. See `../sales/data-dictionary.md`.

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

### Customer Lifecycle Mapping (#5)

| Customer Lifecycle Stage | Is Active Customer | Lifecycle Rank |
|--------------------------|-------------------|----------------|
| Active | Yes | 1 |
| Expansion Opportunity | Yes | 2 |
| At-Risk | Yes | 3 |
| Engaged | No | 4 |
| Opportunity | No | 5 |
| Prospect | No | 6 |

### Account Health Mapping (#6)

| Account Health | Health Rank | Health Category |
|---------------|-------------|-----------------|
| Positive | 1 | Green |
| Slightly Positive | 2 | Green |
| Neutral | 3 | Yellow |
| Slightly Negative | 4 | Red |
| Negative | 5 | Red |

### User Lookup (#8)

Data table from Raw User tab. Key: User ID_18.

| Col | Value Column |
|-----|-------------|
| 1 | User ID_18 (key) |
| 2 | First Name |
| 3 | Last Name |
| 4 | CSM Name (concatenated: First Name & " " & Last Name) |
| 5 | Title |

Used to resolve CSM names from Salesforce User IDs on Account.Customer Success Manager and Opportunity.Customer Success Manager fields.

### Renewal Window Config (#9)

| Parameter | Value | Notes |
|-----------|-------|-------|
| Renewal Match Window Days | 90 | Days before/after Renewal Date to look for renewal opp (churn detection) |
| Line Renewal Match Window Before | 30 | Days before Line End Date to look for renewal line start |
| Line Renewal Match Window After | 90 | Days after Line End Date to look for renewal line start |
