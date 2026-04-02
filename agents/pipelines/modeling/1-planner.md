# Agent 1: Planner — Modeling Pipeline

## Role

Scopes the model, validates the formula-first approach, confirms data availability, and writes a plan doc. Supports two modes: **registry** (pre-defined model spec) and **ad-hoc** (user-defined model built conversationally). This agent runs as a direct conversation with the user (not dispatched as a subagent).

## Inputs

For complete business logic reading order, see `agents/pipelines/modeling/domain-config.md § Reading Order`.

| Input | Source |
|-------|--------|
| User request | Conversation |
| Model registry | `business-logic/models/README.md` — registered models index |
| Formula rules | `business-logic/_shared/formula-rules.md` — approach validation checklist |

## Steps

### Step 1: Detect Mode

Check if the user's request matches a registered model:
1. Read `business-logic/models/README.md` — check the Registered Models table
2. If keywords match a registered model → **Registry mode** (proceed to Step 2A)
3. If no match → **Ad-hoc mode** (proceed to Step 2B)

### Step 2A: Registry Mode — Load Spec

1. Load `business-logic/models/<model-name>/spec.md`
2. Present a summary to the user:
   - Model name and description (from `## Metadata`)
   - Data source (from `## Source`)
   - Methodology overview
   - Output tabs (from `## Tab Structure`)
3. Confirm scope with user:
   - **Source sheet:** Confirm the source sheet ID and tab
   - **Historical window:** Default from spec or user-specified
   - **Exceptions:** Review exception rules — any changes?
   - **Overrides:** User can override any default parameter
   - **Breakdowns:** Review dimension breakdowns — add/remove/change?
4. Proceed to Step 3.

### Step 2B: Ad-Hoc Mode — Build Spec

Walk the user through each section of the canonical spec format (from `business-logic/models/README.md`):

1. **Source:** What data source? Which sheet/tab? Where are headers?
2. **What are you modeling?** What outcome variable? What input dimensions?
3. **Lookups:** What categorical mappings are needed?
4. **Tier 1-2 columns:** What helper columns derive from raw data + Lookups?
5. **Model sections:** What parameters to compute? What formulas?
6. **Tier 3 columns:** How do model outputs apply to individual records?
7. **Exceptions:** Any records that get special treatment?
8. **Summary:** What aggregations/breakdowns?
9. **Audit:** What drill-down view?
10. **Sanity checks:** What would indicate the model is wrong?

Save the completed spec to `.context/<model-name>-spec.md` in canonical format.

After a successful run, offer: "Want to save this model to the registry for reuse?"

### Step 3: Validate Data Availability

Read the source sheet (from spec `## Source`) to confirm:
- All required fields exist
- Sufficient data volume (check historical window)
- No obvious data quality issues (blanks in critical fields)

If any field is missing, surface it and propose alternatives.

<!-- NOTE: Modeling uses spec-driven scoping (registry detection + spec validation) instead of the standard scoping-steps pattern. See codespecs/scoping-steps.md for the standard version. -->
### Step 3.5: Classify Complexity

Assess the request against complexity tiers (defined in `CLAUDE.md` → Complexity Tiers):

**Express** — Registry model with no overrides, user just wants to re-run it. Skip approach validation printout.
**Standard** — Registry model with 1-2 overrides, or ad-hoc with clear spec. Run validation internally.
**Deep** — Ad-hoc model built from scratch, or registry model with significant changes. Full validation with user.

### Step 4: Run Approach Validation Checklist (all tiers, presentation varies)

From `business-logic/_shared/formula-rules.md`:
- Can all model parameters be expressed as COUNTIFS/AVERAGEIFS? → Answer per spec
- Can per-record calculations use INDEX-MATCH against model tables? → Answer per spec
- Are there any recursive dependencies? → Tiers should be acyclic
- Does any calculation exceed Sheets formula limits? → Check
- Is Python compute-and-push needed for anything? → If yes, document why

- **Express/Standard:** Run internally. Only surface to user if an item FAILS. Note "Approach validation: PASSED" in plan doc.
- **Deep:** Print full checklist to user with each item checked or flagged.
<!-- DEVIATION: Modeling scoping uses registry detection (Step 1-2A/2B) instead of user Q&A table, and approach validation is spec-driven -->

<!-- NOTE: Modeling plan doc uses spec-driven sections (Model, Tab Structure, Sanity Check Thresholds) instead of the standard plan-doc-format. See codespecs/agent-authoring.md § Plan Doc Format for the standard version. -->
### Step 5: Write Plan Doc

Save to `.context/<model-name>-plan.md` with:

```markdown
# <Model Name> — Plan

## Model
- **Name:** <name>
- **Spec path:** <registry path or .context path>
- **Mode:** Registry / Ad-hoc

## Scope
- Source sheet ID and tab
- Historical window
- Exception rules confirmed
- User overrides (if any)

## Tab Structure
[From spec, with any modifications]

## Column Map
[Tiers 1-3 column headers and letters — from spec, adjusted if raw data has different column count]

## Model & Inputs Layout
[Section positions from spec]

## Summary Layout
[Breakdown dimensions and values]

## Sanity Check Thresholds
[From spec]

## Approach Validation
[Checklist results]
```
<!-- DEVIATION: Modeling plan doc adds Model, Tab Structure, Model & Inputs Layout, Sanity Check Thresholds sections -->

### Step 6: Get Sign-Off

Present the plan and wait for explicit approval before proceeding to Agent 2.

## Outputs

| Output | Description |
|--------|-------------|
| `.context/<model-name>-plan.md` | Approved plan doc |
| Confirmed scope | Source, window, exceptions, dimensions |
| Data availability report | All required fields present + row count |
| Spec path | Registry path or .context path |

## Handoff to Agent 2

After approval, proceed to `2-data-prep.md`. The plan doc contains the spec path and all context needed by downstream stages.
