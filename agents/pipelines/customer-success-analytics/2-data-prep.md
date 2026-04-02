# Agent: Customer Success Analytics Data Prep

- **Role:** Creates the analysis sheet, ingests raw data, builds Lookups + formula-based Prepared Data
- **Trigger:** Plan doc exists at `.context/customer-success-analytics-plan.md` with Approach Validation PASSED
- **Position:** Agent 2 of 4 in the Customer Success Analytics pipeline

## References

For complete business logic reading order, see `agents/pipelines/customer-success-analytics/domain-config.md § Reading Order`.

Read before executing:
- `.context/customer-success-analytics-plan.md` — the plan doc (read first, update before handoff)
- `agents/pipelines/customer-success-analytics/domain-config.md § Reading Order`
- `business-logic/customer-success/data-dictionary.md`
- `business-logic/customer-success/data-prep-rules.md`
- `skills/create-analysis-sheet.md` — how to create the sheet and ingest data

## Pipeline

### Step 0: Resolve Sources

Before any ingest, resolve source aliases from domain-config's `## Ingest Config` table:

1. For each source row, if the Params field contains `source: $ALIAS`, execute `skills/resolve-source.md` with that alias
2. The skill reads `sources.md` and returns: adapter type, connection params, column mappings, value mappings
3. Use the resolved connection params (e.g., `sheetId`) when calling the adapter skill in Step 1
4. If column mappings are returned, apply them after ingest (rename Raw Data headers to canonical names)

### Step 1: Create Sheet + Ingest

1. Create new Google Sheet with tab structure: Summary, Raw Opportunity, Raw Account, Raw Order Lines, Raw User, Prepared Data - Accounts, Prepared Data - Order Lines, Analysis, Lookups, Definitions
2. Read `## Ingest Config` from `domain-config.md` to determine adapter and source params
3. For each source row in Ingest Config, follow the adapter skill at `skills/ingest/{adapter}.md`:
   - Raw Opportunity ← Opportunity tab from source sheet
   - Raw Account ← Account tab from source sheet
   - Raw Order Lines ← Subskribe Order Line tab from source sheet
   - Raw User ← User tab from source sheet
   - Pass the source params + target sheet ID + target tab name
   - Verify the adapter output: row count, column headers, numeric columns rewritten
4. Confirm total row count matches expected source size per tab (Opportunity ~800, Account ~16,720, Order Lines ~1,155, User ~1,000)

### Step 2: Build Lookups Tab

> Follow the Lookups build process in `codespecs/lookups-pattern.md`.

**Customer Success Analytics lookup sections:**

For each section in `domain-config.md` → Lookups Sections, write the mapping table:

| # | Section | Key Column | Value Columns | Source |
|---|---------|------------|---------------|--------|
| 1 | Account Lookup | ADMIN Acct ID 18 Digit | Account Name, Customer Lifecycle Stage, CS Package, CSM, ARR, Renewal Date, Account Health, Use Case, Company Segment, Expansion Potential | Raw Account |
| 2 | Opportunity Lookup | ADMIN Opp ID 18 Digit | ADMIN Acct ID, Stage, Amount, Close Date, Opp Type, CSM Sourced, Company Segment, Stage 2 Start Date, Order Delta ARR | Raw Opportunity |
| 3 | Use Case Mapping | Use Case (raw) | Use Case (mapped) | Static (same as sales) |
| 4 | Fiscal Period Mapping | Month Number | Fiscal Quarter, Month in Quarter, FY Add | Static (same as sales) |
| 5 | Customer Lifecycle Mapping | Customer Lifecycle Stage | Is Active Customer, Lifecycle Rank | Static |
| 6 | Account Health Mapping | Account Health | Health Rank, Health Category | Static |
| 7 | Renewal Window Config | Parameter | Value | Static |
| 8 | User Lookup | User ID_18 | First Name, Last Name, CSM Name, Title | Raw User |

Refer to `business-logic/customer-success/data-dictionary.md` for exact key→value mappings.

### Step 3: Write Prepared Data — Accounts Tab

1. Copy original columns from Raw Account to Prepared Data - Accounts (static, `RAW`)
2. Add calculated column headers for Account helper fields
3. Write row-by-row formulas in tier order (`USER_ENTERED`):

   Refer to `business-logic/customer-success/data-prep-rules.md` for complete formulas.

   - **Tier 1** (raw + Lookups): Use Case (Mapped), Is Active Customer, Lifecycle Rank, Health Category, Health Rank, Renewal Mo, Renewal Qtr, Renewal FY Add, Renewal Fiscal, Renewal Quarter Label
   - **Tier 2** (derived from Tier 1): Has Renewal Opp, Is Churned, Has Expansion Potential
   - **Tier 3** (derived from Tier 2): Churn Risk Flag

   Full formulas in `business-logic/customer-success/data-dictionary.md` § Helper Fields — Prepared Data - Accounts.

### Step 3b: Write Prepared Data — Order Lines Tab

1. Copy original columns from Raw Order Lines to Prepared Data - Order Lines (static, `RAW`)
2. Add calculated column headers for Order Line helper fields
3. Write row-by-row formulas in tier order (`USER_ENTERED`):

   - **Tier 1** (raw + Lookups): Account Name, CSM, Company Segment, Account Use Case, Account ARR, Account Health, Line End Mo/Qtr/FY Add/Fiscal/Quarter Label, Line Start Mo
   - **Tier 2** (derived from Tier 1): Is Expansion, Is Contraction, Is Flat Renewal, Line Duration Days

   Full formulas in `business-logic/customer-success/data-dictionary.md` § Helper Fields — Prepared Data - Order Lines.

**Note:** No compute-and-push step needed. GDR/NDR are calculated at analysis time by comparing active Order Line ARR at period start vs period end per account.

### Step 4: Data Quality Checks

Run data quality checks per the domain's data-prep-rules. Present the data quality report to the user. **Wait for acknowledgment before handing off to Agent 3.**

### Step 5: Update Plan Doc

Add to `.context/customer-success-analytics-plan.md`:
- `## Sheet:` spreadsheet ID + URL
- `## Column Map:` header name → column letter for all columns
- `## Data Quality:` summary of report + user acknowledgment

## Anti-Patterns

- **DON'T** write static values to Prepared Data calculated columns — use Sheet formulas
- **DON'T** use ARRAYFORMULA — write row-by-row
- **DON'T** write Tier 2 before Tier 1 resolves
- **DON'T** proceed to analysis without user acknowledging data quality report
**AP-CS1: Mixing account-level and line-level granularity.** Don't compute GDR/NDR from account-level ARR — use Subskribe Order Line Entry/Exit ARR for contract-level precision. Account ARR is a snapshot, not a cohort-ready metric.

**AP-CS2: Including non-customers in health distribution.** Always filter to Is Active Customer = "Yes" for Account Health Distribution. Prospects and Opportunities skew the distribution.

**AP-CS3: Counting CSQLs without Stage 2 threshold.** A CSQL must have Stage 2. Discovery Start Date populated — without it, the opportunity hasn't entered real pipeline. This matches the sales pipeline threshold rule.

**AP-CS4: Ignoring LOI and Services Swap exclusions.** LOI (Letter of Intent) and Services Swap opportunities must be excluded from CSQL counts. They are not real expansion pipeline.

## Verification

- [ ] Raw Data row count matches source (per tab: Opportunity, Account, Order Lines)
- [ ] Lookups tab populated with all mapping tables
- [ ] Read back Prepared Data - Accounts with `FORMATTED_VALUE` — formulas resolve without errors
- [ ] Read back Prepared Data - Order Lines with `FORMATTED_VALUE` — formulas resolve without errors
- [ ] Row count: Raw Account = Prepared Data - Accounts
- [ ] Row count: Raw Order Lines = Prepared Data - Order Lines
- [ ] No Tier 3 Order Line columns needed (GDR/NDR computed at analysis time)
- [ ] Plan doc updated with Sheet ID, column map (both tabs), data quality summary
