# Ops Forecast — Lookups & Tier 1-2 Helper Columns

## Lookups

All Lookup sections use `valueInputOption: RAW` unless stated otherwise.

### Section 1: Stage Mapping (A1:C10)

| Stage | Pipeline Category | Detail Category |
|-------|------------------|-----------------|
| 1. Lead Verification | PrePipeline | PrePipeline |
| 2. Discovery | Pipeline | Early Pipeline |
| 3. Scoping | Pipeline | Early Pipeline |
| 4. Solution Validation \| Trial | Pipeline | Mid Pipeline |
| 5. Solutions Proposal | Pipeline | Mid Pipeline |
| 6. Negotiate and Close | Pipeline | Late Pipeline |
| 9. Closed-Won | Won | Won |
| 10. Closed-Lost | Lost | Lost |
| 11. Qualified-Out | QualifiedOut | QualifiedOut |


### Section 2: Use Case Mapping (E1:F12)

Map raw Primary Use Case to consolidated categories. **Must match actual raw data values exactly** — verify against source before writing.

| Raw Value | Consolidated |
|-----------|-------------|
| Social Media Access | Social Media Access |
| Access Management (EPM, SSO, MFA) | Access Management (EPM, SSO, MFA) |
| Identity Lifecycle Management (JML) | Identity Lifecycle Management (JML) |
| Identity Governance (UAR, remediation) | Identity Lifecycle Management (JML) |

All other values → "Other" via IFERROR wrapper in formulas. Blank handled in formula (blank → "Other").


### Section 3: Fiscal Period (H1:J13)

| Month Num | Fiscal Quarter | FY Add |
|-----------|---------------|--------|
| 1 | Q4 | 0 |
| 2 | Q1 | 1 |
| 3 | Q1 | 1 |
| 4 | Q1 | 1 |
| 5 | Q2 | 1 |
| 6 | Q2 | 1 |
| 7 | Q2 | 1 |
| 8 | Q3 | 1 |
| 9 | Q3 | 1 |
| 10 | Q3 | 1 |
| 11 | Q4 | 1 |
| 12 | Q4 | 1 |


### Section 4: Lead Source List (L1:L6)

Header: "Lead Source Attribution"
Values: Marketing, Sales, Partner, Customer Success, Other


### Section 5: Sparse Threshold (N1:N2)

- N1: "Min Sample Size"
- N2: 5

Tier 3 formulas reference `Lookups!$N$2` for sparse fallback decisions.


### Section 6: Stage Number Mapping (P1:Q10)

Map stage strings to numeric values (2-6 for pipeline stages). Used by INDEX-MATCH in Tier 3 formulas.

| Stage | Number |
|-------|--------|
| Header row | Stage Number |
| 2. Discovery | 2 |
| 3. Scoping | 3 |
| 4. Solution Validation \| Trial | 4 |
| 5. Solutions Proposal | 5 |
| 6. Negotiate and Close | 6 |


---

## Tier 1 Helper Columns

Raw + Lookups only. Column letters assume 29 original columns (A-AC). **Always discover dynamically** — read Raw Data headers to confirm the starting column for helpers.

| Col | Header | Formula (row n) | Notes |
|-----|--------|-----------------|-------|
| AD | Pipeline Category | `=IFERROR(VLOOKUP(G{n},Lookups!$A:$B,2,FALSE),"")` | G = Stage |
| AE | Use Case | `=IF(Q{n}="","Other",IFERROR(VLOOKUP(Q{n},Lookups!$E:$F,2,FALSE),"Other"))` | Q = Primary Use Case |
| AF | Is Historical | `=IF(AND(OR(AD{n}="Won",AD{n}="Lost",AD{n}="QualifiedOut"),J{n}<>"",DATEVALUE(LEFT(J{n},10))>=DATE(2025,1,1)),1,0)` | J = Close Date |
| AG | Current Stage Number | `=IFERROR(VLOOKUP(G{n},Lookups!$P:$Q,2,FALSE),0)` | 0 for non-pipeline stages |
| AH | Close Month | `=IF(J{n}="","",TEXT(DATEVALUE(LEFT(J{n},10)),"YYYY-MM"))` | |
| AI | Opp Value | `=IF(F{n}="Existing Business",IF(T{n}<>"",T{n},0),IF(S{n}<>"",S{n},0))` | F=Opp Type, T=Order Delta ARR, S=Amount |
| AJ | Is LOI | `=IF(ISNUMBER(SEARCH("LOI",F{n})),1,0)` | |
| AK | Is Renewal | `=IF(F{n}="Existing Business",1,0)` | |
| AL | Is Open | `=IF(AND(AD{n}<>"Won",AD{n}<>"Lost",AD{n}<>"QualifiedOut",AD{n}<>""),1,0)` | |
| AM | Reached S2 | `=IF(V{n}<>"",1,0)` | V = Stage 2 Start Date |
| AN | Reached S3 | `=IF(W{n}<>"",1,0)` | W = Stage 3 Start Date |
| AO | Reached S4 | `=IF(X{n}<>"",1,0)` | X = Stage 4 Start Date |
| AP | Reached S5 | `=IF(Y{n}<>"",1,0)` | Y = Stage 5 Start Date |
| AQ | Reached S6 | `=IF(Z{n}<>"",1,0)` | Z = Stage 6 Start Date |
| AR | Is NB | `=IF(F{n}="New Business",1,0)` | |
| AS | Is Service Swap | `=IF(ISNUMBER(SEARCH("Service Swap",F{n})),1,0)` | |
| AT | Is Excluded | `=IF(OR(AJ{n}=1,AS{n}=1),1,0)` | LOI or Service Swap → excluded from model |

Write with `valueInputOption: USER_ENTERED` in 200-row batches.

---

## Tier 2 Helper Columns

References Tier 1 outputs.

| Col | Header | Formula (row n) | Notes |
|-----|--------|-----------------|-------|
| AU | Is Closed Won | `=IF(AD{n}="Won",1,0)` | |
| AV | Is Closed Lost | `=IF(OR(AD{n}="Lost",AD{n}="QualifiedOut"),1,0)` | |
| AW | Days S2 to Close | `=IF(AND(AU{n}=1,AF{n}=1,V{n}<>""),DATEVALUE(LEFT(J{n},10))-DATEVALUE(LEFT(V{n},10)),"")` | Won + historical only |
| AX | Days S3 to Close | `=IF(AND(AU{n}=1,AF{n}=1,W{n}<>""),DATEVALUE(LEFT(J{n},10))-DATEVALUE(LEFT(W{n},10)),"")` | |
| AY | Days S4 to Close | `=IF(AND(AU{n}=1,AF{n}=1,X{n}<>""),DATEVALUE(LEFT(J{n},10))-DATEVALUE(LEFT(X{n},10)),"")` | |
| AZ | Days S5 to Close | `=IF(AND(AU{n}=1,AF{n}=1,Y{n}<>""),DATEVALUE(LEFT(J{n},10))-DATEVALUE(LEFT(Y{n},10)),"")` | |
| BA | Days S6 to Close | `=IF(AND(AU{n}=1,AF{n}=1,Z{n}<>""),DATEVALUE(LEFT(J{n},10))-DATEVALUE(LEFT(Z{n},10)),"")` | |

Write with `USER_ENTERED` in 200-row batches.
