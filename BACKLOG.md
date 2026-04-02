# Feature Backlog

Central feature-planning file for the COO Chief of Staff agent.

---

## Planned

### Composition Protocol (deferred from Plan C Phase 6)
Cross-domain analyses that span multiple pipelines. Deferred until real multi-pipeline experience informs the design. Requires: dispatch logic, IMPORTRANGE fallback strategy, partial composition handling.

---

### Simplified Auth Setup
Create a streamlined process for setting up gws CLI authentication on a fresh machine. Reduce friction for first-time setup beyond what bootstrap.sh currently handles.

### Hallucination Blocking
Current anti-hallucination rules ("never guess", "verify before claiming done") are instructions — the agent self-polices with no structural enforcement. Add a verification protocol that review-stage agents enforce:
- **Source citation gates** — every numeric claim must cite `sheet:tab:range`; review rejects uncited values
- **Read-before-write proof** — before any `gws sheets values update`, agent must show the `gws sheets values get` it's basing the write on
- **Echo-back verification** — after writing to a sheet, immediately read back and compare; fail on mismatch
- **Definition anchoring** — subagents must quote the exact line from `business-logic/*/metrics.md` before using a metric; review checks the quote matches the file
- **Claim-evidence pairing** — every assertion in output tagged `[verified]` or `[assumed]`; review flags untagged claims
- **Stale-reference detection** — when citing a sheet URL/ID from memory, validate it exists via `gws drive files get` before using it
- Implementation: add verification protocol to `codespecs/`, wire into dispatch contract so agents structurally can't skip it.

### ~~Portability Gap: Data Layer Configuration~~ → Done (2026-03-30)
Moved to Done section.

---

### General Purpose Agent
An agent that can use authenticated credentials, search the web, and handle general operational work beyond structured pipeline analyses.

### Scheduling Automations
Rebuild scheduling infrastructure — automated tasks, triggers, and the infra supporting them.

### Test-Driven Development
Add a testing framework and a testing agent for validating pipeline behavior — e.g., sample data inputs with expected outputs, SHARED block sync checks, domain-config schema validation. The testing agent runs as part of the pipeline to catch regressions before they reach production sheets.

### Credentials Management & Auth
A centralized mechanism for managing credentials and authentication across agents — service accounts, OAuth tokens, API keys. Reduce friction for adding new integrations and eliminate ad-hoc auth handling.

### Metric Governance Model
Define who owns metric definitions and the change process as the project grows beyond one person. Without governance, metric drift becomes undetectable — someone updates `sales/metrics.md` and downstream docs (metrics explorer, analyses) silently diverge. Add a "Metric Governance" section to the architecture doc defining: canonical owner per domain, change approval process, downstream update checklist. **Depends on:** external adoption (Success Criterion 1 from design doc). Premature for solo operation but critical before accepting external domain contributions. *(Source: Eng Review — Codex finding #5)*

### Baseline KPIs for Value Measurement
Define 2-3 baseline KPIs to measure Monterrey's impact vs. the current manual process. Candidates: time-to-answer for a standard analysis request, analyst hours per quarter, error rate in delivered sheets. Without baselines, the value proposition is anecdotal ("it feels faster") not measurable ("it reduced time-to-answer from 3 days to 15 minutes"). Requires tracking manual process metrics before and after adoption. **Depends on:** having at least 1 external user to compare against. *(Source: Eng Review — Codex finding #13)*

---

## Ideas / Not Yet Scoped

### Agent vs Skill Boundary Evaluation
Evaluate which capabilities should be agents (subagent definitions in `agents/`) vs skills (tools in `skills/`). Assess whether some current agents would work better as skills or vice versa.

---

## Done

### Data Layer Portability (2026-03-30)
Centralized all data source configuration into `sources.md` at project root. Sheet IDs removed from ~18 files, replaced with `$ALIAS` references (DAILY_DATA, MARKETING_DATA, CS_DATA). Added `skills/resolve-source.md` (alias resolution), `skills/setup.md` (interactive setup wizard for external users), and schema requirements documentation. Data-prep agents now resolve aliases as Step 0 before ingest. External users can configure their own data sources by running the setup wizard. Design spec: `docs/superpowers/specs/2026-03-30-data-portability-design.md`.

### Architecture Simplification (2026-03-25)
Removed BVA webapp, GitHub Actions, scheduled skills. Moved authoring-only codespecs (domain-config-schema, naming-conventions) to domain-builder. Merged formula-patterns into formula-rules. Removed duplicated definitions from CLAUDE.md (complexity tiers, error classification tables now reference codespecs). Shared codespecs remain as neutral canonical sources with SHARED markers in agent files.

### Portability & Simplification (2026-03-24)
Moved all knowledge/memory/guides into project repo. Consolidated agents/_shared/ into codespecs/, inlined manifests into domain-configs, archived docs/. Added bootstrap.sh for fresh machine setup. 124 files → 107 files, 21K → 14K lines.

### Domain Builder (2026-03-23, PR #35)
Interactive pipeline scaffolding agent. Q&A flow collects domain info, generates all pipeline files from templates, validates existing pipelines.

### Reduce Rigidity — Plans A+B (2026-03-21, PR #33-34)
Foundation + core flexibility: config-driven dispatch, ingest adapters, shared codespecs, inspection protocol.

### Marketing Analytics Pipeline (2026-03-12)
Full 4-stage pipeline: planner → data-prep → analysis → review.

### Modeling Pipeline (2026-03-15)
Full 4-stage pipeline for ops forecast and ad-hoc models.

### Scheduling Automation (2026-03-12)
GitHub Actions for daily data freshness and monthly forecast snapshots.
