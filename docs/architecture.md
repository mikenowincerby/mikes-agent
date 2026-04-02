# Architecture

Monterrey is an AI agent framework for building trustworthy business operations analytics. This document describes how the system works, how its components connect, and how to extend it.

## System overview

```
  ┌─────────────────────────────────────────────────────────┐
  │                     CLAUDE.MD                            │
  │              (Orchestration Protocol)                     │
  │  Request Routing → Pipeline Registry → Stage Dispatch    │
  └──────────┬──────────────┬──────────────┬────────────────┘
             │              │              │
  ┌──────────▼──────┐ ┌────▼────┐ ┌───────▼──────────┐
  │ agents/         │ │codespecs│ │ business-logic/   │
  │                 │ │ (12)    │ │ {domain}/ + _shared│
  │ pipelines/      │ │ scoping │ │ metrics           │
  │   domain-config │ │ inspect │ │ data-dictionary   │
  │   1-planner     │ │ errors  │ │ data-prep-rules   │
  │   2-data-prep   │ │ lookups │ │ anti-patterns     │
  │   3-analysis    │ │ summary │ │ formula-rules     │
  │   4-review      │ │ defs    │ └──────────┬────────┘
  │                 │ │ deep-div│            │
  │ operations/     │ │ authoring│           │
  │   briefings     │ │ briefings│          │
  │                 │ │ output  │            │
  │ meta/           │ │ plan-doc│            │
  │   domain-builder│ │ session │            │
  │   agent-improve │ │ digest  │            │
  └──────────┬──────┘ └────┬────┘            │
  ┌──────────▼─────────────▼────────────────▼────────────┐
  │                    skills/                             │
  │  ingest/sheets  ingest/csv  build-formulas  format    │
  │  create-sheet   compute-push  prep-sales  prep-mktg   │
  └──────────────────────┬───────────────────────────────┘
                         │
              ┌──────────▼──────────┐
              │    Google Sheets    │
              │  (Output Medium)    │
              └─────────────────────┘
```

## Key concepts

| Term | Definition |
|------|-----------|
| **Pipeline** | A registered analytics workflow with a domain-config, ordered stages, and business-logic files. Lives in `agents/pipelines/{name}/`. |
| **Stage** | One step in a pipeline (planner, data-prep, analysis, review). Each has an instruction file and a dispatch file. |
| **Domain Config** | Per-pipeline constant store (`agents/pipelines/{name}/domain-config.md`). Defines data sources, metrics, stages, context inlining, sanity checks. |
| **Plan Doc** | Markdown document (`.context/{pipeline}-plan.md`) that accumulates scope, outputs, and issues across stages. Passed to every dispatch. |
| **Codespec** | A shared pattern file in `codespecs/` referenced by all pipelines (e.g., scoping, inspection, error handling). |
| **Dispatch** | Launching a subagent via `.claude/agents/{file}.md`. The subagent runs independently and returns a RESULT block. |
| **Inline** | A stage executed in the orchestrator's own context (no subagent). Used for planner stages. |
| **Briefing** | A structured extract from a meeting transcript or context event. Stored in `briefings/recent/`, indexed in `briefings/briefings.md`. |
| **Knowledge** | Vetted permanent rules promoted from briefings. Stored in `knowledge.md` (tracked in git). |
| **Skill** | A reusable capability file in `skills/` (e.g., sheets ingest, formula building, formatting). |
| **Complexity Tier** | Express / Standard / Deep classification that controls which stages run and inspection depth. See `codespecs/scoping-steps.md`. |
| **RESULT** | Structured output block returned by every subagent: status, outputs, verification, issues. See `codespecs/output-contract.md`. |
| **CoS** | Chief of Staff — the orchestrator agent defined in `CLAUDE.md`. Routes requests, dispatches stages, inspects results. |
| **Session Digest** | End-of-session summary assembled per `codespecs/session-digest.md`. Feeds the agent-improvement retrospective. |

## Orchestration loop

Every user request follows a classification step before entering the appropriate protocol:

```
  User request
       │
       ▼
  0. CLASSIFY ─── route by type (see Task Taxonomy below)
       │
       ├── Pipeline analysis ──────► Pipeline loop (below)
       ├── Ad-hoc analysis ────────► Ad-Hoc Protocol
       ├── Briefing / knowledge ───► Briefing Protocol
       ├── Task management ────────► Inline: TODO.md CRUD
       └── Pipeline scaffolding ───► Domain-builder dispatch
```

**Pipeline loop** (for matched pipelines):

```
  1. READ ─────── agents/pipelines/{pipeline}/domain-config.md → extract Stages
       │
       ▼
  2. TIER ─────── Express / Standard / Deep (see Complexity Tiers below)
       │
       ▼
  3. FOR EACH stage in order:
       │
       ├── CHECK skip conditions against complexity tier
       ├── DISPATCH subagent via .claude/agents/{dispatch-file}.md
       │     with: plan doc, context-inlined files, success criteria
       ├── INSPECT output against codespecs/inspection-protocol.md
       ├── DECIDE: proceed │ re-dispatch once │ escalate to user
       └── UPDATE plan doc before next stage
       │
       ▼
  Delivered Google Sheet
```

### Request routing

1. Match the request against `business-logic/pipeline-registry.md` trigger keywords
2. If matched → execute the pipeline
3. If no match → offer to scaffold a new pipeline (domain builder) or handle as ad-hoc
4. If ambiguous → present top 2 candidate pipelines and ask the user to confirm

### Task taxonomy

| Type | Handling | Examples |
|------|----------|----------|
| **Pipeline Analysis** | Delegate: full orchestration protocol | "Build a sales report for Q2", "Analyze marketing pipeline" |
| **Ad-Hoc Analysis** | Delegate: 2-stage (analyst → review) | "What's our win rate this quarter?", "How many deals closed last month?" |
| **Briefing Operation** | Delegate: briefings agent | "Process this meeting transcript", "What did we decide about X?" |
| **Knowledge Operation** | Delegate: briefings agent (promote mode) | "Add to knowledgebase", "Promote to KB" |
| **Task Management** | Inline: TODO.md CRUD | "Add to to-do", "What's on my list?", "Mark X done" |
| **Pipeline Scaffolding** | Delegate: domain-builder | "Build a new pipeline for finance data" |
| **Operational Task** | Delegate: 7-phase workflow | "Update the lookups tab", "Fix the formatting on this sheet" |

### Complexity tiers

The planner classifies every request before executing:

| Tier | Criteria | Behavior |
|------|----------|----------|
| **Express** | Metrics, dimensions, and time range all stated | Skip review stage. Minimal scoping. |
| **Standard** | 1-2 parameters need clarification | Full pipeline. Brief scoping Q&A. |
| **Deep** | Open-ended or ambiguous request | Full pipeline + strategic recommendations + follow-up suggestions. |

Classification rules: `codespecs/scoping-steps.md`

### Error handling

All errors are classified by severity:

| Severity | Definition | Action |
|----------|-----------|--------|
| **hard-fail** | Stage cannot complete (data missing, API error, formula cascade) | Stop. Attempt fix. If unfixable, escalate to user. |
| **warning** | Output complete but anomalous (unusual values, scoping concerns) | Proceed. Include in delivery. |
| **info** | Non-critical observation | Proceed. Log in plan doc. |

Escalation rules: max 1 re-dispatch per stage. Two failures on the same stage = escalate to user. Never re-dispatch with identical inputs.

Full taxonomy: `codespecs/error-handling.md`

## Ad-hoc protocol

For questions that need data but don't warrant a full pipeline:

1. **CoS dispatches ad-hoc analyst** with the user's question, relevant context (briefings, knowledge), and the domain's data sources
2. **Analyst pulls data, computes answer**, returns a RESULT block with a scope statement (what was included/excluded, time range, caveats)
3. **CoS dispatches adhoc-review** to validate the answer against known anti-patterns (`business-logic/_shared/anti-patterns.md`)
4. **CoS presents validated answer** to the user with sources and assumptions

Pipeline: `agents/pipelines/adhoc-analysis/`. Review agent config: `agents/pipelines/adhoc-analysis/domain-config.md`.

## Briefing protocol

For meeting transcript ingestion, context recall, and knowledge promotion:

1. **CoS dispatches briefings agent** with operation type (`ingest`, `recall`, or `promote`) and relevant input (transcript URL, search query, or briefing reference)
2. **Agent executes per `codespecs/briefings.md` protocol** — extracts structured data, searches briefing index, or identifies promotion candidates
3. **For promote:** CoS presents knowledge base candidates for user approval before writing to `knowledge.md`

Agent: `agents/operations/briefings/`. Protocol: `codespecs/briefings.md`. Transcript source: `https://drive.google.com/drive/folders/1ZQ5iCAglMjcQrCJmP5OcejQ0qY2B5GYb`.

## Framework boundary

What is shared (framework) vs. domain-specific (per pipeline):

| Layer | Framework (shared) | Domain-specific (per pipeline) |
|-------|-------------------|-------------------------------|
| **Orchestration** | `CLAUDE.md` orchestration protocol, request routing | `pipeline-registry.md` trigger keywords |
| **Stage execution** | `codespecs/` — scoping, inspection, error handling, definitions, lookups, summary structure, agent authoring | `agents/pipelines/{pipeline}/domain-config.md`, `1-planner.md` through `4-review.md` |
| **Business logic** | `business-logic/_shared/` — anti-patterns, analysis-patterns, formula-rules | `business-logic/{domain}/` — metrics, data-dictionary, data-prep-rules |
| **Skills** | `skills/` — ingest adapters, sheet building, formula writing, formatting, compute-and-push | Domain-specific prep skills (`prep-sales-data.md`, `prep-marketing-data.md`) |
| **Dispatch** | `.claude/agents/` dispatch file templates | `.claude/agents/{pipeline}-*.md` dispatch files |
| **Briefings** | `codespecs/briefings.md` protocol, `agents/operations/briefings/` | Transcript sources, Drive folder IDs |
| **Scaffolding** | `agents/meta/domain-builder/` — templates, schema, naming conventions | Generated output from domain builder |

## Domain-config schema

Every pipeline has a `domain-config.md` at `agents/pipelines/{pipeline}/domain-config.md`. This is the per-pipeline constant store read by the orchestrator at dispatch time.

### Required sections

| # | Section | Purpose |
|---|---------|---------|
| 1 | `## Data Sources` | Sheet IDs, tabs, read-only flags |
| 2 | `## Metric Catalog` | Metric categories + names, reference to full definitions |
| 3 | `## Dimensions` | Time + categorical dimensions for slicing |
| 4 | `## Lookups Sections` | Mapping tables (stage mapping, use case mapping, fiscal periods) |
| 5 | `## Sanity Checks` | Checks with severity levels (hard-fail/warning/info) |
| 6 | `## Intentional Deviations` | Where this pipeline differs from shared patterns |
| 7 | `## Stages` | Ordered stage sequence with dispatch files and skip conditions |
| 8 | `## Context Inlining` | Files to include in each stage's dispatch prompt |
| 9 | `## Ingest Config` | Data source adapter type and parameters |

### Optional sections

| Section | Purpose |
|---------|---------|
| `## Inspection Overrides` | Domain-specific checks run in addition to universal inspection |
| `## Reading Order` | Per-stage reading order for business logic files |

Full schema: `agents/meta/domain-builder/domain-config-schema.md`

### Example: Stages section

```markdown
| Order | Stage | Instruction File | Dispatch File | Skip Conditions |
|-------|-------|-----------------|---------------|-----------------|
| 1 | planner | 1-planner.md | inline | never |
| 2 | data-prep | 2-data-prep.md | sales-data-prep | never |
| 3 | analysis | 3-analysis.md | sales-analysis | never |
| 4 | review | 4-review.md | sales-review | Express |
```

## Dispatch interface

The dispatch interface is the abstraction boundary between the orchestration framework and the runtime.

### Contract

```
Input:
  - stage_name: string          (e.g., "data-prep")
  - pipeline_name: string       (e.g., "sales-analytics")
  - plan_doc: markdown           (full current state — scope, outputs, issues)
  - context_files: string[]      (file contents inlined per Context Inlining table)
  - success_criteria: string[]   (explicit checklist for this stage)

Output:
  - status: PASS | FAIL | PARTIAL | PASS with warnings
  - stage_output: markdown       (stage-specific results)
  - errors: Issue[]              (severity, description, fixable flag)
```

### Current implementation: Claude Code

The dispatch interface is currently implemented via Claude Code's `.claude/agents/` mechanism:

- Each stage has a dispatch file at `.claude/agents/{pipeline}-{stage}.md`
- The orchestrator (CLAUDE.md) reads the domain-config's Stages table and dispatches the appropriate file
- Context inlining is handled by reading files and including their contents in the dispatch prompt
- The subagent returns a RESULT block with status, outputs, verification, and issues

**Runtime coupling disclaimer:** Claude Code is the only tested runtime. The dispatch interface contract above is designed for portability — a LangGraph node, a raw API call, or another agent runtime could implement the same input/output contract. However, no non-Claude-Code runtime has been tested. The `.claude/agents/*.md` dispatch files use Claude Code-specific YAML frontmatter (name, description, tools list) that would need adaptation for other runtimes.

### Dispatch file structure

```yaml
---
name: {pipeline}-{stage}
description: "{Pipeline} {Stage}: {one-line purpose}"
tools: [Read, Edit, Write, Bash, Glob, Grep]
---
```

Required sections: Setup (read domain-config + instruction file), Context (inputs from dispatch prompt), Output Contract (RESULT template), Rules (4-6 rules including gws CLI, no silent recovery, verify via read-back).

Full template: `codespecs/agent-authoring.md`

## Data flow

```
  Salesforce → Daily Snapshot Sheet → gws CLI read → Raw Data tab
       │
       ▼
  Raw Data → Lookups (VLOOKUP) → Prepared Data (Tier 1 → 2 → 3)
       │
       ▼
  Prepared Data → SUMIFS/COUNTIFS → Analysis tab → Summary tab
       │
       ▼
  Summary + Analysis + Definitions → Delivered Sheet
```

### Tier-based formula dependencies

Formulas are built in tiers to prevent cascading failures:

| Tier | What it contains | Dependencies |
|------|-----------------|--------------|
| **Tier 1** | Raw data + Lookups references (VLOOKUP, helper columns) | Raw Data tab, Lookups tab |
| **Tier 2** | Derived columns using Tier 1 (e.g., fiscal quarter from date, pipeline category from stage) | Tier 1 columns only |
| **Tier 3** | Compound metrics using Tier 1 + 2 (e.g., win rate, ADS, sales cycle) | Tier 1 + Tier 2 columns |

Each tier is written and verified before the next tier begins. This ensures that if a Tier 1 formula has an error, it's caught before Tier 2 compounds it.

### Formula-first constraint

Every cell in every output sheet must have a formula pointing back to source data. This is an architectural constraint, not a preference:

- No pre-computed static values as output
- IFERROR wrappers on all division and lookup operations
- All formulas reference Prepared Data helper columns, not raw field values
- Numeric columns written with `USER_ENTERED` value input option (not `RAW`)

Rules: `business-logic/_shared/formula-rules.md`

## Shared patterns (codespecs)

Twelve shared pattern files that all pipelines reference:

| Codespec | Purpose |
|----------|---------|
| `scoping-steps.md` | Complexity classification + scoping Q&A process |
| `inspection-protocol.md` | Post-dispatch checklists, plan doc integrity gates, stall detection |
| `error-handling.md` | Severity taxonomy, escalation protocol, formula error reference |
| `lookups-pattern.md` | How to build Lookups tabs with VLOOKUP mappings |
| `summary-tab-structure.md` | KPI headline + breakdown + notes structure |
| `definitions-pattern.md` | How to build Definitions tabs (methodology, metrics, sources, assumptions) |
| `deep-dive-triggers.md` | When to suggest follow-up analyses |
| `agent-authoring.md` | How to write dispatch files, instruction files, and domain-configs |
| `briefings.md` | Briefing lifecycle: ingest, recall, promote, auto-detection protocol |
| `output-contract.md` | RESULT block format returned by all subagents |
| `plan-doc-format.md` | Plan document structure and update rules |
| `session-digest.md` | End-of-session summary format for agent-improvement retrospective |

These files use `<!-- SHARED: {block-name} -->` markers in pipeline-specific files to enable drift detection.

## Skills

Seven reusable capabilities:

| Skill | Purpose |
|-------|---------|
| `ingest/sheets-adapter.md` | Read data from Google Sheets via gws CLI |
| `ingest/csv-adapter.md` | Read data from CSV/Excel files |
| `create-analysis-sheet.md` | Create new Google Sheets with standard tab structure |
| `build-sheet-formulas.md` | Write formulas to sheets (tier-based, with verification) |
| `format-output-sheet.md` | Apply FAST framework formatting (freeze, alignment, sizing, theming) |
| `compute-and-push.md` | Python computation for things sheet formulas can't do (median, cross-row matching) |
| `prep-data-base.md` | Foundation skill for data preparation (extended by domain-specific prep skills) |

## Inspection protocol

After each stage dispatch, the orchestrator runs inspection checklists scaled by complexity tier:

| Tier | Data Prep check | Analysis check | Review check |
|------|----------------|----------------|--------------|
| **Express** | Status PASS, Sheet ID accessible | Status PASS, read 2 Summary cells | Skipped |
| **Standard** | + row count match, column map spot-check, no hard-fails | + all tabs exist, formula smoke test (3+3 cells) | Sanity checks only |
| **Deep** | Same as Standard | Same as Standard | + Definitions completeness, all checks ran, warning review |

Stall detection thresholds: Data Prep >15 min, Analysis >20 min, Review >10 min.

Full protocol: `codespecs/inspection-protocol.md`

## Session resilience

The system persists state across session interruptions:

- `briefings/active-work.md` — current task, status, progress
- `knowledge.md` — stable institutional knowledge (Sheet IDs, data model, feedback rules)
- `briefings/briefings.md` — session knowledge index
- Plan doc (`.context/{pipeline}-plan.md`) — stage-by-stage state passed between dispatches

On session resume: read `active-work.md` → find in-progress task → resume from last checkpoint.

## Open questions

1. **Licensing:** Open-source everything (MIT)? Or open-source framework, protect domain knowledge? Default: MIT. Decision deferred until external validation.

2. **Runtime portability:** How portable should the dispatch interface be across LLM runtimes? Default: Claude Code only for v1. The contract is defined; alternate implementations are future work.

3. **Data source abstraction:** Currently Salesforce-centric via daily snapshot sheets. Ingest adapters support CSV/Excel. New domains bring their own data sources via the adapter contract. No additional abstraction needed for v1.

## Reference pipelines

| Pipeline | Maturity | Stage count | Anti-patterns | Key differentiator |
|----------|----------|-------------|---------------|-------------------|
| Sales Analytics | High | 4 | 10+ | Salesforce stage progression semantics, "Reached Stage X" flags |
| Marketing Analytics | Medium-High | 4 | 8+ | SUMPRODUCT workaround, 3 MQL counting methodologies, multi-source ingest |
| Customer Success | Medium | 4 | 6+ | 2-granularity (account + order line), contract-based GDR/NDR |
| Modeling | Medium | 4 | — | Spec-driven, Python-heavy option |
| Ad-Hoc Analysis | Low-Medium | 2 | 7 checks | 2-stage flow: analyst computes answer, review validates against anti-patterns |
| Briefings | New | 1 | — | 3 operation modes (ingest, recall, promote) |
