# Inspection Protocol

Checklists run by the CoS after each pipeline stage dispatch.

## Extension Point

Domain-configs can add domain-specific checks via `## Inspection Overrides`:

| Stage | Check | Severity |
|-------|-------|----------|
| data-prep | Verify model spec positions JSON is present | hard-fail |

These run IN ADDITION to the universal checklists below.

---

## Plan Doc Integrity Gates

Before dispatching any stage, validate the plan doc has all required fields. **Never dispatch with an incomplete plan doc.**

**Before Data Prep (Stage 2):**
- [ ] Scope section complete (dimensions, time range, metrics)
- [ ] Data sources listed with Sheet IDs
- [ ] Tab structure defined
- [ ] Approach validation checklist PASSED

**Before Analysis (Stage 3):**
- [ ] Sheet ID present (written by data-prep)
- [ ] Column map present (letter → header for all Prepared Data columns)
- [ ] Row count recorded
- [ ] Data quality report has no hard-fails

**Before Review (Stage 4):**
- [ ] All expected tabs listed with status
- [ ] Formula count or coverage metric recorded
- [ ] Any warnings from analysis stage documented

---

## CoS Inspection Protocol

Inspection depth scales with complexity tier.

### Express Tier
**After Data Prep:** Spot-check only — RESULT status is PASS, Sheet ID accessible (read 1 cell), no hard-fails.
**After Analysis:** RESULT status is PASS, read 2 cells from Summary tab for errors. Done — skip Review stage.

### Standard & Deep Shared Checklist

**After Data Prep:**
- [ ] RESULT status is PASS
- [ ] Sheet ID returned and accessible (read 1 cell)
- [ ] Row count matches expected (within 5% tolerance; >20% drift = hard-fail)
- [ ] Column map spot-check: read 3 header cells, confirm they match the map
- [ ] No hard-fail issues
- [ ] Plan doc updated with Sheet ID + column map

**After Analysis:**
- [ ] RESULT status is PASS
- [ ] All expected tabs exist
- [ ] Formula smoke test: read 3 cells from Summary tab + 3 from first analysis tab; any #REF!, #VALUE!, #N/A, blank, or hardcoded value where a formula is expected = re-dispatch with specific errors
- [ ] No hard-fail issues

### Standard — After Review (light)
- [ ] RESULT status is PASS or PASS with warnings
- [ ] All sanity checks ran (none skipped)
- [ ] Hard-fail count = 0

### Deep — After Review (full)
- [ ] RESULT status is PASS or PASS with warnings
- [ ] Definitions completeness: methodology >3 rows, metric defs >= Summary metrics, source section has Sheet ID + date + row count, >= 1 assumption
- [ ] All sanity checks ran (none skipped)
- [ ] Hard-fail count = 0
- [ ] Warning list reviewed — none contradict plan

---

## Stall Detection

Data Prep (3-8 min, stall >15 min), Analysis (5-12 min, stall >20 min), Review (2-5 min, stall >10 min). On stall: check output sheet for partial progress.

---

## Re-Dispatch

On FAIL/PARTIAL: read issues, classify per `codespecs/error-handling.md` (input/API → fix and re-dispatch once; logic/data → escalate). Two failures on same stage = escalate to user with diagnosis.

---

## Formula Verification Checklist

Run by all review agents (Stage 4) before sanity checks or Definitions tab work.

### Step 1: Read Back All Tabs

Read ALL tabs using `gws sheets spreadsheets values get` with `FORMATTED_VALUE`. Check for:
- `#REF!` -- column reference is wrong
- `#N/A` -- lookup failed
- `#DIV/0!` -- division by zero (should be caught by IFERROR)
- `#VALUE!` -- type mismatch
- `#NAME?` -- function name error
- Blank cells where values are expected
- **Orphan rows** -- rows beyond Prepared Data's last data row that contain stale formulas or values. Delete them with `batchUpdate` -> `deleteDimension`.

Fix any errors before proceeding.

### Step 2: Cross-Tab Consistency

- Row count: Raw Data = Prepared Data (or Raw Source tabs = Prepared Data for multi-source pipelines)
- Every Tier 3 column has at least one non-blank value
- Summary tab formulas produce reasonable numbers (non-zero where expected)
- Analysis tab totals are consistent with Summary headline KPIs

### Pass Criteria

Zero formula errors across all tabs. All cross-tab consistency checks pass.
