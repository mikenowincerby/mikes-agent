# {{display_name}} — Domain Config

Pipeline-specific constants for the {{display_name}} pipeline. Referenced by stage files alongside `codespecs/` patterns.

## Data Sources

{{data_sources_table}}
| Plan doc path | `.context/{{pipeline_name}}-plan.md` | | |

## Metric Catalog

{{metric_catalog_table}}

Full definitions: `business-logic/{{domain}}/metrics.md`

## Dimensions

{{dimensions_text}}

## Lookups Sections

{{lookups_table}}

## Sanity Checks

{{sanity_checks_table}}

Full rules: `business-logic/{{domain}}/metrics.md` sanity checks section

## Intentional Deviations

{{deviations}}

## Inspection Overrides

{{inspection_overrides}}

## Stages

| Order | Stage | Instruction File | Dispatch File | Skip Conditions |
|-------|-------|-----------------|---------------|-----------------|
| 1 | planner | 1-planner.md | inline | never |
| 2 | data-prep | 2-data-prep.md | {{pipeline_name}}-data-prep | never |
| 3 | analysis | 3-analysis.md | {{pipeline_name}}-analysis | never |
| 4 | review | 4-review.md | {{pipeline_name}}-review | Express |

## Context Inlining

{{context_inlining_table}}

## Ingest Config

{{ingest_config_table}}
