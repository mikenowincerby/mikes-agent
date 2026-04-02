# Agents

Agent definitions that execute specific actions -- data pulls, report generation, workflows, integrations.

Each agent file should define: purpose, inputs, outputs, and required skills/tools.

## Architecture: Composition Over Inheritance

Each pipeline has stage files (1-planner, 2-data-prep, 3-analysis, 4-review) that are **self-contained** -- a subagent reads 1 instruction file and gets everything it needs.

Shared patterns are extracted to `codespecs/` as **reference blocks** (the canonical source of truth). Stage files reference these blocks rather than duplicating content. Domain-specific constants live in each pipeline's `domain-config.md`.

## Folder Structure

Agents are organized into three categories:

```
agents/
├── pipelines/                          # Multi-stage analytics workflows
│   ├── sales-analytics/
│   │   ├── domain-config.md            # Metric catalog, data sources, Lookups, sanity checks
│   │   ├── 1-planner.md               # Self-contained
│   │   ├── 2-data-prep.md             # Self-contained
│   │   ├── 3-analysis.md              # Self-contained
│   │   └── 4-review.md                # Self-contained
│   │
│   ├── marketing-analytics/            # Same 4-stage structure
│   ├── customer-success-analytics/     # Same 4-stage structure
│   ├── modeling/                       # Same 4-stage structure
│   └── adhoc-analysis/                 # 2-stage: analyst → review
│       ├── domain-config.md
│       ├── 1-analyst.md
│       └── 2-review.md
│
├── operations/                         # Non-analytics operational agents
│   └── briefings/                      # Ingest transcripts, recall decisions, promote to KB
│       ├── domain-config.md
│       └── 1-briefings.md
│
└── meta/                               # System management agents
    ├── agent-improvement/              # Post-execution retrospective
    │   ├── domain-config.md
    │   └── 1-retrospective.md
    └── domain-builder/                 # Pipeline scaffolding tool
        ├── builder.md
        ├── domain-config-schema.md
        ├── naming-conventions.md
        └── templates/
```

### Category Rationale

| Category | When to use | Naming convention |
|----------|------------|-------------------|
| **pipelines/** | Multi-stage analytics workflows that produce Google Sheets deliverables | `{domain}-analytics/` for analytics, `{domain}/` for models |
| **operations/** | Agents that manage operational processes (briefings, project management, etc.) | `{function}/` |
| **meta/** | Agents that manage the agent system itself (scaffolding, improvement, etc.) | `{function}/` |

## Agent State (Cross-Session Context)

Agents that need cross-session operational state maintain it in `.state/{category}/{agent-name}/`. Currently only the briefings agent uses this:

```
.state/
└── operations/
    └── briefings/
        └── state.md          # Scan timestamps, ingested files, pending KB candidates
```

State directories are **gitignored** — operational state, not source. Other agents may adopt the pattern per `codespecs/agent-context.md` when cross-session state is demonstrated to be needed. Pipeline agents currently rely on the retrospective (`agents/meta/agent-improvement/`) for persisting learnings into instruction improvements.

Pattern defined in: `codespecs/agent-context.md`

## Shared Blocks (in codespecs/)

| Block | Content | Used By |
|-------|---------|---------|
| `codespecs/scoping-steps.md` | Dimension selection, time range, metric selection, strategic recommendations | All planners (Stage 1) |
| `codespecs/agent-authoring.md` § Plan Doc Format | Standard plan doc sections: Scope, Sources, Column Map, Results | All planners (Stage 1) |
| `codespecs/lookups-pattern.md` | Create Lookups tab, write section-by-section, verify with read-back | All data-prep (Stage 2) |
| `codespecs/summary-tab-structure.md` | KPI block → Breakdown → Notes structure for Summary tabs | Sales + Marketing analysis (Stage 3) |
| `codespecs/inspection-protocol.md` § Formula Verification Checklist | Formula read-back, error detection, cross-tab consistency | All review (Stage 4) |
| `codespecs/error-handling.md` § Severity Taxonomy | hard-fail/warning/info table with definitions and actions | All review (Stage 4) |
| `codespecs/definitions-pattern.md` | Definitions tab: metrics, data sources, assumptions | All review (Stage 4) |
| `codespecs/deep-dive-triggers.md` | When to recommend follow-ups: outsized contribution, anomaly, etc. | All review (Stage 4) |
| `codespecs/briefings.md` | Briefing extraction, retention, KB promotion protocol | Briefings agent |
| `codespecs/output-contract.md` | Standard RESULT format returned by all subagents | All agents |
| `codespecs/plan-doc-format.md` | Plan doc template and conventions | All planners |
| `codespecs/session-digest.md` | Session summary format for retrospective input | Agent-improvement |

## Domain Configs

Each pipeline's `domain-config.md` centralizes:
- **Data Sources** -- sheet IDs, tabs, plan doc path
- **Metric Catalog** -- pipeline-specific metrics by category
- **Dimensions** -- available slicing dimensions
- **Lookups Sections** -- what mappings to build
- **Sanity Checks** -- pipeline-specific checks with severity
- **Reading Order** -- which business-logic files to read per stage
- **Intentional Deviations** -- documented differences from shared patterns

## Sync Check Process

Verify shared sections haven't drifted from canonical `codespecs/` blocks:
1. Find stage files referencing each `codespecs/*.md` block
2. Compare referenced sections against `codespecs/` source
3. Divergence is either an **intentional deviation** (documented in domain-config) or a **sync error** (fix by updating the stage file)

## Adding a New Pipeline

Use the domain builder agent at `agents/meta/domain-builder/` to scaffold all files interactively. New analytics pipelines go in `agents/pipelines/`. For the complete domain-config format, see `agents/meta/domain-builder/domain-config-schema.md`.
