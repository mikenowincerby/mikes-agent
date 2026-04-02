# Agent: Marketing Analytics Analysis

- **Role:** Writes Summary and Analysis tab formulas, deal-list outputs
- **Trigger:** Plan doc has Sheet ID, Column Map, and Data Quality acknowledged
- **Position:** Agent 3 of 4 in the Marketing Analytics pipeline

## References

Read before executing:
- `.context/marketing-analytics-plan.md` — the plan doc (read first, update before handoff)
- `business-logic/marketing/metrics.md` — metric definitions, formulas, sanity check rules
- `business-logic/_shared/formula-rules.md` — formula-first principles
- `skills/build-sheet-formulas.md` — formula patterns, analysis tab layout, deal-list formulas
- `skills/compute-and-push.md` — Python compute fallback (only if Sheet formulas can't do it)

## Pipeline

### Step 1: Build Column Map

Read Prepared Data row 1 to get header -> column letter mapping. Or use the column map from the plan doc if Agent 2 provided it.

### Step 2: Write Analysis Tab Formulas

For each metric x dimension in the plan scope:
1. Build COUNTIFS (member counts, MQLs, SQLs, Opps, Won Opps), SUMIFS (Opp Value, Won Value), or IFERROR ratio (conversion rates, CPA, CPM, ROI)
2. **Use helper column values in all filter criteria** — e.g., `Is MQL+ = "Yes"`, not raw Lifecycle strings. Use `Has Opportunity = 1`, not raw Stage matching.
3. Write to Analysis tabs with section headers (see `build-sheet-formulas.md` layout)
4. Max 3 analysis tabs — consolidate with section headers

**MQL counting method:** Two approaches exist (see `marketing-metrics.md`):
- **`Is MQL+`** = current lifecycle snapshot. Simple COUNTIFS. Use when MQL date coverage is low or for "how many members are currently MQL+?" questions.
- **`MQLs in Period`** = time-range counting via Unified MQL Start/End Date. Use SUMPRODUCT with date range conditions. Preferred for period-bounded analysis ("MQLs in February").
- **Before writing MQL formulas**, check MQL date coverage from the data quality report. If coverage is < 50% for the campaigns in scope, fall back to `Is MQL+` and note the caveat in the Summary tab.

**Example formulas (replace column references with actual letters from column map):**

```
Total Members:    =COUNTIFS('Prepared Data'!$[campaign_col]:$[campaign_col],"[campaign]")
MQLs:             =COUNTIFS('Prepared Data'!$[campaign_col]:$[campaign_col],"[campaign]",'Prepared Data'!$[mql_col]:$[mql_col],"Yes")
SQLs:             =COUNTIFS('Prepared Data'!$[campaign_col]:$[campaign_col],"[campaign]",'Prepared Data'!$[sql_col]:$[sql_col],"Yes")
Opps:             =COUNTIFS('Prepared Data'!$[campaign_col]:$[campaign_col],"[campaign]",'Prepared Data'!$[has_opp_col]:$[has_opp_col],1)
Won Opps:         =COUNTIFS('Prepared Data'!$[campaign_col]:$[campaign_col],"[campaign]",'Prepared Data'!$[won_opp_col]:$[won_opp_col],1)
Opp Value:        =SUMIFS('Prepared Data'!$[amount_col]:$[amount_col],'Prepared Data'!$[campaign_col]:$[campaign_col],"[campaign]",'Prepared Data'!$[has_opp_col]:$[has_opp_col],1)
Won Value:        =SUMIFS('Prepared Data'!$[amount_col]:$[amount_col],'Prepared Data'!$[campaign_col]:$[campaign_col],"[campaign]",'Prepared Data'!$[won_opp_col]:$[won_opp_col],1)
MQL Conv Rate:    =IFERROR(COUNTIFS(...mql...)/COUNTIFS(...total...),0)
SQL Conv Rate:    =IFERROR(COUNTIFS(...sql...)/COUNTIFS(...mql...),0)
Cost per MQL:     =IFERROR([campaign_cost]/COUNTIFS(...mql...),"N/A")
Cost per SQL:     =IFERROR([campaign_cost]/COUNTIFS(...sql...),"N/A")
CPA:              =IFERROR([campaign_cost]/COUNTIFS(...total...),"N/A")
ROI:              =IFERROR((SUMIFS(...won_value...)-[campaign_cost])/[campaign_cost],"N/A")
```

### Step 3: Write Deal-List Outputs

Use FILTER/SORT/ARRAY_CONSTRAIN patterns from `build-sheet-formulas.md`:

**MQL list** (sorted by Sort Score descending):
```
=SORT(FILTER(
  {'Prepared Data'!$[name_col]$2:$[name_col]$[last_row], 'Prepared Data'!$[title_col]$2:$[title_col]$[last_row], 'Prepared Data'!$[account_col]$2:$[account_col]$[last_row], 'Prepared Data'!$[lifecycle_col]$2:$[lifecycle_col]$[last_row], 'Prepared Data'!$[sort_col]$2:$[sort_col]$[last_row]},
  'Prepared Data'!$[campaign_col]$2:$[campaign_col]$[last_row]="[campaign]",
  'Prepared Data'!$[mql_col]$2:$[mql_col]$[last_row]="Yes"
), 5, FALSE)
```

**Opportunity list** (sorted by Opp Amount descending):
```
=SORT(FILTER(
  {'Prepared Data'!$[name_col]$2:$[name_col]$[last_row], 'Prepared Data'!$[opp_name_col]$2:$[opp_name_col]$[last_row], 'Prepared Data'!$[amount_col]$2:$[amount_col]$[last_row], 'Prepared Data'!$[stage_col]$2:$[stage_col]$[last_row], 'Prepared Data'!$[account_col]$2:$[account_col]$[last_row]},
  'Prepared Data'!$[campaign_col]$2:$[campaign_col]$[last_row]="[campaign]",
  'Prepared Data'!$[has_opp_col]$2:$[has_opp_col]$[last_row]=1
), 3, FALSE)
```

**Rules:**
- Use explicit row ranges (e.g., `A2:A1500`), not open-ended (`A:A`)
- Clear target area before writing spilling formulas
- Write static headers in row 1, formula in A2
- **Opportunity list note:** There is no "Opp Name" helper column in Prepared Data. Use the member Name column and Opp Stage/Amount for deal identification. If needed, the Opportunity Name can be pulled from Raw Opportunities via a VLOOKUP on Converted Opportunity ID.

### Step 4: Write Summary Tab

> Follow the summary tab structure in `codespecs/summary-tab-structure.md`.

**Marketing Summary KPIs — always include in Section A:**
- Total Campaign Members
- MQL Count
- SQL Count
- MQL-to-SQL Conversion Rate (%)
- Total Campaign Cost (USD)
- Cost per MQL (USD)
- Additional KPIs as relevant (Opportunities, Won Opps, Won Value, ROI, etc.)

**Marketing Section C notes** should include: MQL counting method used, cost scoping method.

**Cost metric scoping:** See `marketing-metrics.md` cost scoping rule. For period-specific analyses, use period-scoped campaign costs — not total lifetime costs. Document which scoping method was used in Section C notes.

### Step 5: Handle Compute Fallback

If a calculation exceeds Sheet formula capability:
1. State why formulas can't do it
2. Use `skills/compute-and-push.md`
3. Flag computed cells for Agent 4 to document in Definitions tab

**Only fall back to compute-and-push after 3 failed formula attempts.** Each failure must be documented in the plan doc with:
1. The formula attempted
2. The error encountered
3. Why the formula approach cannot work

### Step 6: Update Plan Doc

Add to `.context/marketing-analytics-plan.md`:
- `## Analysis Complete:` what was built (which tabs, which metrics, any formula errors fixed)

### Step 7: Format Output Sheet

Invoke `skills/format-output-sheet.md` with:
- `spreadsheetId` — the analysis sheet
- `tabManifest` — all tabs and their roles (e.g., `{tabName: "Raw Data", tabRole: "raw-data"}`, `{tabName: "Prepared Data", tabRole: "prepared-data"}`, etc.)

This applies structural formatting (headers, alignment, number formats, chromatic font colors, column widths, borders) to all tabs before handing off to the review agent.

## Anti-Patterns

- **DON'T** filter on raw Lifecycle strings — use Is MQL+, Is SQL+, Has Opportunity, Is Closed Won Opp helper columns
- **DON'T** use QUERY for deal lists — use FILTER/SORT (handles mixed-type columns)
- **DON'T** use open-ended ranges in FILTER — use explicit row ranges to avoid #REF! spill errors
- **DON'T** build ranges missing column letter on both sides — `$AG$2:$AG$1199` is correct, `$AG$2:$1199` causes #VALUE! in multi-criteria COUNTIFS/SUMIFS

## Verification

- [ ] **Range format check**: every COUNTIFS/SUMIFS range has column letter on both sides (e.g., `$AG$2:$AG$1199`)
- [ ] **Readback**: read every analysis tab with `FORMATTED_VALUE` — no #REF!, #N/A, #DIV/0!, #VALUE! errors
- [ ] Values are non-zero where expected (member counts, conversion rates)
- [ ] Deal-list formulas spill correctly (correct row count, no empty rows)
- [ ] Summary tab has all metrics from plan scope
- [ ] Plan doc updated with analysis details
