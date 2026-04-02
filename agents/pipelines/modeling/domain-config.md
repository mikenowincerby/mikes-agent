# Modeling — Domain Config

Pipeline-specific constants for the Modeling pipeline. Referenced by stage files alongside `_shared/` patterns.

## Modes

| Mode | Trigger | Spec Source |
|------|---------|-------------|
| Registry | User request matches a registered model in `business-logic/models/README.md` | `business-logic/models/<model-name>/spec.md` |
| Ad-hoc | No registry match | Built conversationally, saved to `.context/<model-name>-spec.md` |

## Data Sources

Source is model-specific, defined in the spec's `## Source` section. No fixed default.

| Field | Source |
|-------|--------|
| Plan doc path | `.context/<model-name>-plan.md` |
| Spec path | Registry path or `.context/<model-name>-spec.md` |
| Model positions | `.context/<model-name>-model-positions.json` |

## Model Spec Format

The canonical spec format (from `business-logic/models/README.md`) defines:
- Metadata, Source, Tab Structure, Lookups
- Tier 1-3 Helper Columns (formula templates with `{n}` row placeholders)
- Model Sections (Computed/Override/Effective pattern)
- Exceptions, Summary Layout, Audit Tab
- Sanity Checks (with Phase: data-quality or model-review)
- Definitions Template

## Tier Split Rules

| Tier | Depends On | Written By |
|------|-----------|------------|
| Tier 1 | Raw data + Lookups only | Agent 2 (Data Prep) |
| Tier 2 | Tier 1 columns | Agent 2 (Data Prep) |
| Tier 3 | Model & Inputs tab (Effective values) | Agent 3 (Analysis) |

Agent 2 writes Tiers 1-2. Agent 3 writes Tier 3 after building the Model & Inputs tab.

## Sanity Checks

Sanity checks are model-specific, defined in the spec's `## Sanity Checks` section with:
- Phase: `data-quality` (run by Agent 2) or `model-review` (run by Agent 4)
- Rule and threshold per check
- Severity classification per `_shared/severity-taxonomy.md`

## Intentional Deviations

| Deviation | Reason |
|-----------|--------|
| Two-phase quality checks | Data quality checks (Agent 2) and model review checks (Agent 4) are separated by phase, unlike Sales/Marketing which run all checks in Agent 4 |
| Spec-driven tab structure | Tab names and count come from model spec, not hardcoded. Other pipelines have fixed tab structures. |
| Registry vs ad-hoc branching | Planner has two distinct paths based on whether model exists in registry. Other pipelines have a single flow. |
| Model & Inputs tab | Unique to Modeling -- contains Computed/Override/Effective columns. Not present in Sales or Marketing. |

## Stages

| Order | Stage | Instruction File | Dispatch File | Skip Conditions |
|-------|-------|-----------------|---------------|-----------------|
| 1 | planner | 1-planner.md | inline | never |
| 2 | data-prep | 2-data-prep.md | modeling-data-prep | never |
| 3 | analysis | 3-analysis.md | modeling-analysis | never |
| 4 | review | 4-review.md | modeling-review | Express |

## Context Inlining

| File | Scope |
|------|-------|
| `business-logic/_shared/formula-rules.md` | all stages |
| `business-logic/_shared/anti-patterns.md` | planner, data-prep, analysis |
| `agents/pipelines/modeling/domain-config.md` | all stages |
| `codespecs/scoping-steps.md` | planner |
| `business-logic/_shared/analysis-patterns.md` | planner |
| `business-logic/models/README.md` | planner |
| Model spec (from `## Source` in spec) | all stages |

## Ingest Config

Model-specific. Defined in the model spec's `## Source` section. The planner extracts source config from the spec and passes it to data-prep via the plan doc.

---

## Reading Order

Read `business-logic/_shared/formula-rules.md` first (universal). The modeling pipeline is spec-driven: domain-specific logic comes from the model spec, not from fixed business-logic files.

### All Stages
- `business-logic/_shared/formula-rules.md` — Formula-first principles, approach validation checklist
- `business-logic/_shared/anti-patterns.md` — Known analytical gotchas

### Planner (Stage 1)
- `models/README.md` — Registry index, canonical spec format, registered models
- Model-specific spec (e.g., `models/ops-forecast/spec.md`) — loaded by planner based on request
- `business-logic/_shared/analysis-patterns.md` — Analytical lenses (if ad-hoc model needs lens selection)

### Data Prep (Stage 2)
- `business-logic/sales/data-dictionary.md` — Salesforce field lookups (for source data validation)
- Model spec § Source + companion `tiers.md` § Lookups, § Tier 1/2 Helper Columns

### Analysis (Stage 3)
- Model spec § Model Sections, § Tier 3 Helper Columns, § Exceptions, § Summary Layout, § Audit Tab

### Review (Stage 4)
- Model spec § Sanity Checks
- `definitions-template.md` in the model spec directory

### Conditional
- `business-logic/sales/metrics.md` — When model references sales stages, fiscal calendar, or pipeline categories
- `business-logic/_shared/agent-overload-rubric.md` — Only when proposing pipeline extensions
