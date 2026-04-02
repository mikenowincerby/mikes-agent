# Agent Authoring

How to write agent instruction files, dispatch files, and domain configs. These templates reflect the patterns established across all 3 pipelines (Sales, Marketing, Modeling).

---

## Dispatch File Template

Location: `.claude/agents/{pipeline}-{stage}.md`

The dispatch file name for each stage is specified in the pipeline's `domain-config.md` under `## Stages` → `Dispatch File` column. The CoS reads this at dispatch time.

```yaml
---
name: {pipeline}-{stage}
description: "{Pipeline} {Stage}: {one-line purpose}"
tools: [Read, Edit, Write, Bash, Glob, Grep, Agent]
---
```

### Required Sections

| Section | Content |
|---------|---------|
| **Setup** | `Read agents/pipelines/{pipeline}/domain-config.md`, then read stage instruction file |
| **State** | (Optional) State directory path. If present, agent reads its own state on startup before processing dispatch inputs. See `codespecs/agent-context.md` |
| **Context** | Inputs the CoS dispatch prompt provides: Stage, Pipeline, Plan Doc (full current state), Stage-Specific Inputs (Data Prep: source Sheet ID, tab, row offset, column range; Analysis: output Sheet ID, column map, tab list; Review: output Sheet ID, column map, tab list, sanity check definitions), Success Criteria (explicit checklist) |
| **Output Contract** | RESULT template with Status, Outputs, Verification, Issues, Plan Doc Updates |
| **Rules** | 4-6 rules: return to CoS, use gws CLI, no silent recovery, verify via read-back |

### Tools by Stage

| Stage | Tools | Why |
|-------|-------|-----|
| Data Prep | Read, Edit, Write, Bash, Glob, Grep | Sheet creation, data ingest, formula writes |
| Analysis | Read, Edit, Write, Bash, Glob, Grep | Formula construction, deal lists, formatting |
| Review | Read, Edit, Write, Bash, Glob, Grep, Agent | Needs Grep/Glob for cross-file verification |

### Output Contract Template

See `codespecs/output-contract.md` for the standard RESULT format with 3 variants (data-prep, analysis, review).

---

## Instruction File Template

Location: `agents/pipelines/{pipeline}/{N}-{stage}.md` (or `agents/operations/` / `agents/meta/` for non-pipeline agents)

### Required Sections

| Section | Order | Content |
|---------|-------|---------|
| **Header** | 1 | Role, trigger condition, position in pipeline |
| **Context Management** | 1.5 | (Optional) State directory path, what to persist, when to read/write. See `codespecs/agent-context.md` |
| **References** | 2 | Business logic files and skills to read before executing. Include manifest reference. |
| **Pipeline** | 3 | Numbered steps with clear actions. Use 1-line references to `codespecs/` files for shared patterns. |
| **Anti-Patterns** | 4 | 3-5 "DON'T" rules for safety-critical behaviors |
| **Verification** | 5 | Checklist of success criteria as `- [ ]` items |

### Step Writing Guidelines

- Each step should be a single logical action
- Reference skills inline: "Follow `skills/create-analysis-sheet.md`"
- Reference business-logic files for domain rules: "From `metrics.md`, run every check"
- Include code examples for non-obvious operations (e.g., gws CLI calls)
- Reference shared patterns via 1-line pointers to `codespecs/` files (see § Shared Pattern References)

### Anti-Pattern Guidelines

Use "DON'T" rules for:
- Actions that cause data loss or corruption
- Silent failures that are hard to detect
- Ordering violations that produce cascading errors
- Actions that bypass user approval

Keep anti-patterns to **<5 per file**. If you need more, the step instructions aren't clear enough.

---

## Domain Config Template

Location: `agents/pipelines/{pipeline}/domain-config.md` (or `agents/operations/{agent}/` / `agents/meta/{agent}/`)

### Required Sections

| Section | Content |
|---------|---------|
| **Data Sources** | Source Sheet IDs, tab names, notes (e.g., skip metadata rows) |
| **Metric Catalog** | Categories and metric names |
| **Dimensions** | Available slicing dimensions |
| **Lookups Sections** | Numbered sections with column ranges, types, and sources |
| **Sanity Checks** | Check name, rule, severity |
| **Intentional Deviations** | Pipeline-specific choices that differ from shared patterns, with rationale |
| **Stages** | Ordered stage sequence: Order, Stage, Instruction File, Dispatch File, Skip Conditions |
| **Context Inlining** | Files to include in dispatch prompts, with Scope (all stages / specific stage) |
| **Ingest Config** | Data source adapters: Source Name, Adapter, Params |
| **Inspection Overrides** | (Optional) Domain-specific inspection checks added to universal checklists |

### Intentional Deviations

Every domain-config must document where its pipeline deviates from `_shared/` patterns. Format:

```markdown
## Intentional Deviations

| Deviation | Reason |
|-----------|--------|
| Multi-source ingest (3 tabs) | Marketing requires campaign + member + opportunity data joined |
```

If a pipeline has no deviations, state: `None — follows all shared patterns.`

---

## Shared Pattern References

Cross-pipeline patterns live in `codespecs/` files. To use them in instruction files, add a 1-line reference instead of inlining the content:

```markdown
> Follow the standard scoping process in `codespecs/scoping-steps.md` (Steps 0-4).
> Use the plan doc template from `codespecs/plan-doc-format.md`.
```

1. The canonical content lives only in the `codespecs/` file -- never duplicated inline
2. Document deviations in `domain-config.md`, not in the shared pattern file
3. When updating a shared pattern, update the `codespecs/` file -- all references pick it up automatically

See `agents/README.md` for the full composition model.

---

## Plan Doc Format

See `codespecs/plan-doc-format.md` for the standard plan doc template and conventions.

---

## Related

- `agents/README.md` — composition pattern docs, sync check process
- `codespecs/` — shared reference blocks
- `agents/meta/domain-builder/naming-conventions.md` — file and directory naming
- `codespecs/error-handling.md` — severity taxonomy and escalation
- `business-logic/_shared/agent-overload-rubric.md` — when to split vs extend a pipeline
