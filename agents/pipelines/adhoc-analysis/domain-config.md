# Ad-Hoc Analysis — Domain Config

## Purpose

Two-stage pipeline for ad-hoc analyses: an analyst answers the question, then a reviewer validates against known anti-patterns and sanity checks.

## References

| Source | Content |
|--------|---------|
| `business-logic/_shared/anti-patterns.md` | Known gotchas: AP-1 through AP-4 |
| `agents/pipelines/adhoc-analysis/domain-config.md § Reading Order` | Validation checklist |
| `business-logic/sales/metrics.md` § Sanity Check Rules | Metric-level sanity checks |

## Checks

| ID | Check | Source | Severity |
|----|-------|--------|----------|
| AP-1 | Stage progression uses entry dates, not current stage | anti-patterns.md | hard-fail |
| AP-2 | LOI/Service Swap deals excluded | anti-patterns.md | warning |
| AP-3 | Timing metrics use Closed-Won only | anti-patterns.md | warning |
| AP-4 | Date parsing handles timestamps | anti-patterns.md | warning |
| FM | Funnel counts monotonically non-increasing | metrics.md | hard-fail |
| CS | Cohort scoping matches analysis type | metrics.md | warning |
| VR | Values/magnitudes reasonable | metrics.md | warning |
| AP-5 | Data pull covers all rows (no range truncation) | anti-patterns.md | hard-fail |

## Stages

| Order | Stage | Instruction File | Dispatch File | Skip Conditions |
|-------|-------|-----------------|---------------|-----------------|
| 1 | analyst | 1-analyst.md | adhoc-analyst | never |
| 2 | review | 2-review.md | adhoc-review | never |

## Context Inlining

| File | Scope |
|------|-------|
| `business-logic/_shared/formula-rules.md` | analyst |
| `business-logic/sales/metrics.md` | analyst |
| `business-logic/sales/data-dictionary.md` | analyst |
| `business-logic/_shared/anti-patterns.md` | analyst, review |
| `agents/pipelines/adhoc-analysis/domain-config.md § Reading Order` | analyst, review |

---

## Reading Order

Read `business-logic/_shared/formula-rules.md` first (universal).

### Required Reading
1. `business-logic/_shared/formula-rules.md` — formula-first principles, approach validation checklist
2. `business-logic/sales/metrics.md` — metric definitions, stages, cohort scoping defaults, sanity checks
3. `business-logic/sales/data-dictionary.md` — all fields including stage entry dates and Reached SX helpers
4. `business-logic/_shared/anti-patterns.md` — known gotchas to avoid

### Scope Statement — Required with Every Answer

Every ad-hoc result must include a one-line **Scope** block:

```
**Scope:** FY2026 Q2 | Close Date | New Business only | All segments | Stages 2-6, 9, 10 (QO excluded) | LOI/Service Swap excluded | Source: Daily Data › Opportunity
```

### Validate Before Presenting

- [ ] Using stage entry date fields (not current stage inference) for any stage progression analysis
- [ ] Funnel counts monotonically non-increasing (S2 >= S3 >= S4 >= S5 >= S6 >= S9)
- [ ] LOI / Service Swap deals excluded (unless explicitly requested)
- [ ] Timing metrics (sales cycle, days to close) use Closed-Won only — not Lost or QO
- [ ] Date parsing handles text timestamps (use LEFT/slice, not raw parse)
- [ ] Cohort scoping matches analysis type
- [ ] Values and magnitudes are reasonable

### After Analyst Stage

CoS dispatches `adhoc-review` agent with the analyst's RESULT for post-hoc validation.
