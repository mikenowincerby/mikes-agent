# Agent 4: Review — Modeling Pipeline

## Role

Verifies all formulas, runs sanity checks, populates the Definitions tab with stakeholder-ready documentation, and presents the final report. Can be dispatched as a subagent via `.claude/agents/modeling-review.md` or executed directly.

## Inputs

| Input | Source |
|-------|--------|
| Plan doc | `.context/<model-name>-plan.md` |
| Model spec | Path from plan doc |
| Sheet ID | From plan doc |
| Formula rules | `business-logic/_shared/formula-rules.md` |

## Steps

### Step 1: Load Context

Read the plan doc, model spec, and formula rules. Note:
- Sheet ID
- All tab names from spec `## Tab Structure`
- Sanity checks from spec `## Sanity Checks` (Phase: model-review)
- Definitions content from spec `## Definitions Template`

### Step 2: Formula Verification

> Follow the verification checklist in `codespecs/inspection-protocol.md`.

**Modeling-specific verification:**
- Every Tier 3 column has at least one non-blank value (especially model output columns)
- All Model & Inputs Effective columns resolve to values
- If errors are found, attempt to fix them. Record what was found and what was fixed.
<!-- DEVIATION: Modeling adds Model & Inputs Effective column check and Tier 3 non-blank check -->

### Step 3: Run Sanity Checks

From spec `## Sanity Checks`, run all checks with `Phase: model-review`:

For each check:
1. Read the relevant data
2. Apply the rule
3. Compare against the threshold
4. Classify using the taxonomy below

> Use the severity taxonomy from `codespecs/error-handling.md`.

Classify all issues found in Steps 2-3 using this taxonomy.

If any hard-fail check fails, investigate and attempt to fix before continuing. If unfixable, escalate to user.

<!-- NOTE: Modeling Definitions uses 5 spec-driven sections instead of the standard definitions-pattern. See codespecs/definitions-pattern.md for the standard version. -->
### Step 4: Populate Definitions Tab

From spec `## Definitions Template`, write each section:

1. **Section 1: Methodology Overview** — plain-English summary from spec
2. **Section 2: FAQ** — questions and answers from spec
3. **Section 3: Metric Definitions** — one row per metric with Name, Definition, Formula, Source Column
4. **Section 4: Data Source & Refresh** — source details, computation method, override instructions
5. **Section 5: Assumptions & Limitations** — from spec

Write with `valueInputOption: USER_ENTERED` (some cells may reference sheet formulas or dates).
<!-- DEVIATION: Modeling Definitions uses 5 spec-driven sections (Methodology, FAQ, Metrics, Source, Assumptions) vs Sales/Marketing's simpler 2-section layout -->

### Step 5: Deep-Dive Recommendations (Conditional)

If ANY of these triggers are met, add a "Recommended Follow-Ups" section to the Summary tab:

| Trigger | Condition | Example |
|---------|-----------|---------|
| Outsized contribution | Single dimension >40% of total | One segment = 60% of pipeline |
| Trend reversal | Metric contradicts expected direction | Win rate declining despite growing pipeline |
| Anomaly | Value >2σ from expected range | Deal size 5x the segment average |
| Sparse segment | Dimension with <3 data points | Use Case with only 1 deal |
| Warning-flagged pattern | Any sanity check returned a warning | Sanity check flagged unexpected value range |

For each trigger met, recommend a specific follow-up analysis with scope and expected insight.
If no triggers are met, skip this step.

### Step 6: Format Definitions Tab

Apply formatting via `skills/format-output-sheet.md`:
- Role: `definitions`
- Bold Column A (section headers and labels)

### Step 7: Present Final Report

```
## <Model Name> — Final Report

**Sheet:** [URL]

### Model Coverage
- [X] records scored — all have model outputs
- [X] formula errors (0 = clean)
- Historical training window: [date range]
- Records excluded: [count and reasons]

### Key Outputs
[Model-specific summary table — e.g., Pipeline vs Forecast totals]

### Sanity Checks
| Check | Result | Details |
|-------|--------|---------|
[One row per check from spec]

### Tab Summary
[One line per tab describing what it contains]

### How to Use
[Model-specific instructions from spec — e.g., how to override parameters, how to drill down]
```

## Outputs

| Output | Description |
|--------|-------------|
| Sanity check results | All checks passed or issues flagged |
| Definitions tab | Stakeholder-ready documentation |
| Final report | Presented to user with sheet URL |

## Completion

Update plan doc status to COMPLETE. Update `active-work.md` with:
- Model name and sheet URL
- Key results summary
- Date completed
