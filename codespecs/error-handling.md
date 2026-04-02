# Error Handling

Severity levels, escalation rules, and retry policy for all pipeline agents.

---

## Severity Taxonomy

| Severity | Definition | Action |
|----------|-----------|--------|
| **hard-fail** | Stage cannot complete — data missing, API error, formula cascade | Stop. Investigate and attempt fix. If unfixable, escalate to user. |
| **warning** | Output complete but anomalous — unusual values, scoping concerns | Proceed to next stage. Include in final delivery. |
| **info** | Non-critical observation — edge cases, minor notes | Proceed. Log in plan doc. |

---

## Stage-Specific Examples

### Data Prep

| Severity | Example |
|----------|---------|
| hard-fail | Source sheet inaccessible (403/404) |
| hard-fail | Row count is 0 after ingest |
| hard-fail | Required column missing from source |
| warning | Row count differs >10% from plan doc expectation |
| warning | Blank rate >20% for key fields (Title, Department, Level) |
| info | Optional column missing (analysis can proceed without it) |

### Analysis

| Severity | Example |
|----------|---------|
| hard-fail | Formula returns `#REF!` or `#VALUE!` on >5% of rows |
| hard-fail | Summary tab empty or missing |
| warning | A dimension has 0 values (empty segment) |
| warning | A metric returns negative when it shouldn't |
| info | A segment has <3 data points |

### Review

| Severity | Example |
|----------|---------|
| hard-fail | Formula verification fails (>0 error cells) |
| hard-fail | Sanity check finds impossible values (e.g., negative Amount) |
| warning | Sanity check out of expected bounds (e.g., ADS x Won Count off by >5%) |
| warning | Cohort scoping mismatch (QO deals in pipeline analysis) |
| info | Sparse segment flagged for follow-up |

---

## Error Reporting Format

```
### Issues
| # | Severity | Description | Fixable |
|---|----------|-------------|---------|
| 1 | hard-fail | Raw Opportunities tab returned 0 rows — source sheet may be empty or permissions changed | Yes — verify Sheet ID |
| 2 | warning | Blank rate for Department is 34% (threshold: 20%) | No — source data quality |
```

Required fields: issue number, severity, description with enough context to diagnose, fixable flag.

---

## Escalation Protocol

| Error Type | Action |
|------------|--------|
| Input error (wrong Sheet ID, missing column, bad offset) | Fix input → re-dispatch once |
| API error (rate limit, auth failure, timeout) | Wait briefly → re-dispatch once |
| Logic error (formula produces wrong results) | Escalate to user |
| Data error (unexpected values, schema changed) | Escalate to user |

- Max 1 re-dispatch per stage. Never re-dispatch with identical inputs.
- 2 failures on same stage = escalate (include: what was attempted, what failed, subagent's issue report)
- Unresolvable hard-fails: escalate to CoS with which check failed, expected vs found, fix attempted, proposed resolution

---

## Formula Error Reference

| Error | Cause | Fix |
|-------|-------|-----|
| `#REF!` | Column reference points to non-existent column | Check column map, verify header positions |
| `#N/A` | VLOOKUP key not found in Lookups tab | Check Lookups data completeness, verify key format matches |
| `#DIV/0!` | Division by zero | Wrap in `IFERROR(..., 0)` |
| `#VALUE!` | Type mismatch (text vs number) | Verify source column was written with `USER_ENTERED` |
| Blank cell | Formula returned empty string or reference is empty | Check IFERROR fallback, verify source data exists |
| Orphan rows | Rows beyond last data row have stale formulas | Delete with `batchUpdate` → `deleteDimension` |

---

## Sanity Check Classification Rules

- Row count mismatch -> **hard-fail**
- Formula errors (#REF!, #VALUE!, etc.) -> **hard-fail**
- Metric exceeds plausible range (e.g., win rate > 100%) -> **hard-fail**
- Cohort scoping issue (wrong deals included/excluded) -> **warning**
- Summary tab missing headline KPI block -> **warning**
- Cost scoping method undocumented -> **warning**
- Small sample size on a breakdown dimension -> **info**
- Rounding differences < 1% -> **info**

## Related

- `codespecs/agent-authoring.md` — where to place error handling in agent files
- `business-logic/_shared/formula-rules.md` — formula-level error prevention (IFERROR, type handling, complexity thresholds)
