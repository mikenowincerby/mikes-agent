# Agent: Customer Success Analytics Analysis

- **Role:** Writes Summary and Analysis tab formulas, deal-list outputs
- **Trigger:** Plan doc has Sheet ID, Column Map, and Data Quality acknowledged
- **Position:** Agent 3 of 4 in the Customer Success Analytics pipeline

## References

Read before executing:
- `.context/customer-success-analytics-plan.md` — the plan doc (read first, update before handoff)
- `agents/pipelines/customer-success-analytics/domain-config.md § Reading Order`
- `business-logic/customer-success/metrics.md`
- `business-logic/_shared/analysis-patterns.md`
- `skills/build-sheet-formulas.md` — formula patterns, analysis tab layout, deal-list formulas
- `skills/compute-and-push.md` — Python compute fallback (only if Sheet formulas can't do it)

## Pipeline

### CS-Specific: Two Prepared Data Tabs

This pipeline has TWO Prepared Data tabs with different row granularities. Use the correct tab for each metric:

| Metric Group | Source Tab | Why |
|-------------|-----------|-----|
| GDR, NDR, Contraction Rate | Prepared Data - Order Lines | Contract-level renewal matching (compute-and-push Tier 3 columns) |
| Churn Rate, Churned ARR, Churned Count | Prepared Data - Accounts | Account-level churn flag (Is Churned helper) |
| Account Health Distribution | Prepared Data - Accounts | Account Health field + Is Active Customer filter |
| CSQLs, CSQL Conversion Rate | Raw Opportunity (via Lookups) | Opp-level: CSM Sourced + Opp Type + Stage 2 filter |

**Never mix tabs.** Don't SUMIFS Account ARR from Prepared Data - Accounts to calculate GDR — use Order Line Entry/Exit ARR. See AP-CS1.

### Step 1: Build Column Map

Read Prepared Data row 1 **for both tabs** to get header → column letter mapping. Or use the column map from the plan doc if Agent 2 provided it. You need column maps for: Prepared Data - Accounts, Prepared Data - Order Lines, and Lookups (for CSQL formulas).

### Step 2: Write Analysis Tab Formulas

For each metric × dimension in the plan scope:
1. Build SUMIFS (ARR totals), COUNTIFS (counts), or IFERROR ratio (rates like GDR, NDR, conversion)
2. **Use helper column values in all filter criteria** — e.g., `Is Churned = 1`, `Is Active Customer = "Yes"`, `Health Category = "Red"` — not raw field values
3. Write to Analysis tabs with section headers (see `build-sheet-formulas.md` layout)
4. Max 3 analysis tabs — consolidate with section headers

**Example formulas (replace column references with actual letters from column map):**

**From Prepared Data - Accounts:**
```
Active Customers:     =COUNTIFS('Prepared Data - Accounts'!$[active_col]:$[active_col],"Yes")
Churned Count:        =COUNTIFS('Prepared Data - Accounts'!$[churned_col]:$[churned_col],1,'Prepared Data - Accounts'!$[renewal_qtr_col]:$[renewal_qtr_col],"[quarter]")
Churned ARR:          =SUMIFS('Prepared Data - Accounts'!$[arr_col]:$[arr_col],'Prepared Data - Accounts'!$[churned_col]:$[churned_col],1,'Prepared Data - Accounts'!$[renewal_qtr_col]:$[renewal_qtr_col],"[quarter]")
Health Green:         =COUNTIFS('Prepared Data - Accounts'!$[health_cat_col]:$[health_cat_col],"Green",'Prepared Data - Accounts'!$[active_col]:$[active_col],"Yes")
Health Yellow:        =COUNTIFS('Prepared Data - Accounts'!$[health_cat_col]:$[health_cat_col],"Yellow",'Prepared Data - Accounts'!$[active_col]:$[active_col],"Yes")
Health Red:           =COUNTIFS('Prepared Data - Accounts'!$[health_cat_col]:$[health_cat_col],"Red",'Prepared Data - Accounts'!$[active_col]:$[active_col],"Yes")
Churn Rate:           =IFERROR(Churned ARR / Total Active ARR, 0)
```

**From Prepared Data - Order Lines (requires Tier 3 compute-and-push columns):**
```
Expiring ARR:         =SUMIFS('Prepared Data - Order Lines'!$[entry_arr_col]:$[entry_arr_col],'Prepared Data - Order Lines'!$[line_end_qtr_col]:$[line_end_qtr_col],"[quarter]")
GDR:                  =IFERROR(SUMIFS('Prepared Data - Order Lines'!$[gdr_col]:$[gdr_col],'Prepared Data - Order Lines'!$[line_end_qtr_col]:$[line_end_qtr_col],"[quarter]") / Expiring ARR, "N/A")
NDR:                  =IFERROR(SUMIFS('Prepared Data - Order Lines'!$[ndr_col]:$[ndr_col],'Prepared Data - Order Lines'!$[line_end_qtr_col]:$[line_end_qtr_col],"[quarter]") / Expiring ARR, "N/A")
Contraction $:        =ABS(SUMIFS('Prepared Data - Order Lines'!$[delta_arr_col]:$[delta_arr_col],'Prepared Data - Order Lines'!$[contraction_col]:$[contraction_col],1,'Prepared Data - Order Lines'!$[renewed_col]:$[renewed_col],1,'Prepared Data - Order Lines'!$[line_end_qtr_col]:$[line_end_qtr_col],"[quarter]"))
```

**From Lookups (for CSQL metrics — sourced from Raw Opportunity):**
```
CSQL Count:           =COUNTIFS(Lookups!$[csm_sourced_col]:$[csm_sourced_col],TRUE,Lookups!$[opp_type_col]:$[opp_type_col],"Existing Business",Lookups!$[stage2_col]:$[stage2_col],"<>")
CSQL Won:             =COUNTIFS(Lookups!$[csm_sourced_col]:$[csm_sourced_col],TRUE,Lookups!$[opp_type_col]:$[opp_type_col],"Existing Business",Lookups!$[stage_col]:$[stage_col],"9. Closed-Won")
CSQL Conv Rate:       =IFERROR(CSQL Won / CSQL Count, 0)
CSQL Won Value:       =SUMIFS(Lookups!$[amount_col]:$[amount_col],Lookups!$[csm_sourced_col]:$[csm_sourced_col],TRUE,Lookups!$[opp_type_col]:$[opp_type_col],"Existing Business",Lookups!$[stage_col]:$[stage_col],"9. Closed-Won")
```

### Step 3: Write Deal-List Outputs (if requested)

Use FILTER/SORT/ARRAY_CONSTRAIN pattern from `build-sheet-formulas.md`:
- Filter on helper columns, not raw field values
- Use explicit row ranges (e.g., `F2:F1005`), not open-ended (`F:F`)
- Clear target area before writing spilling formulas
- Write static headers in row 1, formula in A2

### Step 4: Write Summary Tab

> Follow the summary tab structure in `codespecs/summary-tab-structure.md`.

**Customer Success Summary KPIs — always include in Section A:**
- GDR (%) — Gross Dollar Retention for the analysis period
- NDR (%) — Net Dollar Retention for the analysis period
- Churn Rate (%) — account-level churn rate
- Churned ARR (USD) — total ARR lost to churn
- CSQL Count — CS-qualified leads created in period
- CSQL Won Value (USD) — closed-won CSQL pipeline value
- Account Health: % Green / % Yellow / % Red — active customer distribution
- Additional KPIs as relevant (Contraction $, Expansion ARR, Renewal Match Rate)

**CS Section C notes** should include: renewal matching window used (default 90 days), whether compute-and-push was invoked, churn identification method (Renewal Date + no closed-won opp), any data quality caveats from Agent 2.

### Step 5: Handle Compute-and-Push (Renewal Matching)

**Unlike Sales/Marketing, CS requires compute-and-push as a planned step, not just a fallback.**

GDR/NDR metrics depend on Tier 3 columns (Matched Renewal Line, Is Renewed, GDR Contribution, NDR Contribution) that are computed in Python and pushed as static values. These columns should already exist from Agent 2's data prep. If they do NOT exist:

1. Check with the user — data prep may have been run without compute-and-push (simplified mode)
2. If needed, invoke `skills/compute-and-push.md` with the renewal matching algorithm from `data-prep-rules.md`
3. After pushing, verify: read back Tier 3 columns, confirm Is Renewed has values, check match rate

**For any OTHER calculation that exceeds Sheet formula capability:**
1. State why formulas can't do it
2. Use `skills/compute-and-push.md`
3. Flag computed cells for Agent 4 to document in Definitions tab

### Step 6: Update Plan Doc

Add to `.context/customer-success-analytics-plan.md`:
- `## Analysis Complete:` what was built (which tabs, which metrics, any formula errors fixed)

### Step 7: Format Output Sheet

Invoke `skills/format-output-sheet.md` with:
- `spreadsheetId` — the analysis sheet
- `tabManifest` — all tabs and their roles

## Anti-Patterns

- **DON'T** filter on raw field values — use helper columns from Prepared Data
- **DON'T** use QUERY for deal lists — use FILTER/SORT (handles mixed-type columns)
- **DON'T** use open-ended ranges in FILTER — use explicit row ranges to avoid #REF! spill errors
- **DON'T** build ranges missing column letter on both sides — `$AG$2:$AG$1199` is correct, `$AG$2:$1199` causes #VALUE!
**AP-CS1: Mixing account-level and line-level granularity.** Don't compute GDR/NDR from account-level ARR — use Subskribe Order Line Entry/Exit ARR for contract-level precision. Account ARR is a snapshot, not a cohort-ready metric.

**AP-CS2: Including non-customers in health distribution.** Always filter to Is Active Customer = "Yes" for Account Health Distribution. Prospects and Opportunities skew the distribution.

**AP-CS3: Counting CSQLs without Stage 2 threshold.** A CSQL must have Stage 2. Discovery Start Date populated — without it, the opportunity hasn't entered real pipeline. This matches the sales pipeline threshold rule.

**AP-CS4: Ignoring LOI and Services Swap exclusions.** LOI (Letter of Intent) and Services Swap opportunities must be excluded from CSQL counts. They are not real expansion pipeline.

## Verification

- [ ] **Range format check**: every COUNTIFS/SUMIFS range has column letter on both sides
- [ ] **Readback**: read every analysis tab with `FORMATTED_VALUE` — no #REF!, #N/A, #DIV/0!, #VALUE! errors
- [ ] Values are non-zero where expected
- [ ] Deal-list formulas spill correctly (correct row count, no empty rows)
- [ ] Summary tab has all metrics from plan scope
- [ ] Plan doc updated with analysis details
