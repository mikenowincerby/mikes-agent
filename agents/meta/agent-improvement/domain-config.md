# Agent Improvement — Domain Config

## Purpose

Post-execution retrospective agent. Analyzes session events (re-dispatches, user corrections, escalations, hard-fails) to identify systemic improvements to agent instructions, anti-patterns, sanity checks, and knowledge. Runs after every pipeline execution and ad-hoc analysis.

## References

| Source | Content |
|--------|---------|
| `business-logic/_shared/anti-patterns.md` | Current anti-patterns (AP-1 through AP-6) — check for duplicates before proposing |
| `codespecs/error-handling.md` | Severity taxonomy — classify what went wrong |
| `codespecs/inspection-protocol.md` | Current inspection checks — identify gaps |
| `knowledge.md` | Current KB — check for duplicates, follow "What Belongs" criteria |
| `codespecs/session-digest.md` | Input format definition |

## Proposal Quality Checks

| ID | Check | Severity |
|----|-------|----------|
| PQ-1 | Every proposal cites a specific session event | hard-fail |
| PQ-2 | Every proposal targets a specific file and section | hard-fail |
| PQ-3 | No proposal duplicates existing content in target file | hard-fail |
| PQ-4 | Anti-pattern proposals follow AP-N format (Mistake / Why / Correct / Sanity check) | hard-fail |
| PQ-5 | Knowledge proposals pass "What Belongs" filter from briefings.md | warning |
| PQ-6 | Total proposals <= 3 per session | warning |
| PQ-7 | Root cause is systemic (not a one-off user error) | warning |

## Stages

| Order | Stage | Instruction File | Dispatch File | Skip Conditions |
|-------|-------|-----------------|---------------|-----------------|
| 1 | retrospective | 1-retrospective.md | agent-improvement | Memory-only sessions; abandoned sessions (no stage completed) |

## Context Inlining

| File | Scope |
|------|-------|
| `business-logic/_shared/anti-patterns.md` | retrospective |
| `codespecs/error-handling.md` | retrospective |
| `codespecs/inspection-protocol.md` | retrospective |

## Intentional Deviations

| Deviation | Reason |
|-----------|--------|
| No data sources, metric catalog, or sanity checks | Meta-agent that analyzes session behavior, not data |
| Read-only tools only | Safety: agent that identifies improvements should not apply them |
| No Lookups or Prepared Data tabs | No spreadsheet work — purely analytical |

## Signal Strength Rubric

Used by the agent to decide whether a session has something worth learning from. Must reach Medium or above to generate proposals.

| Signal | Weight | Example |
|--------|--------|---------|
| Re-dispatch occurred | High | Stage failed and was re-sent with fixes |
| User correction | High | User explicitly corrected agent output |
| CoS escalation | High | CoS could not resolve without user |
| Hard-fail in review | Medium | Sanity check caught a real problem |
| Repeated warning pattern | Medium | Same warning type across 2+ recent sessions |
| Near-miss | Low | Check passed but value was close to threshold |
| Clean execution | None | No signal — return SKIP |

## Proposal Types

| Type | Target File(s) | Description |
|------|---------------|-------------|
| anti-pattern | `business-logic/_shared/anti-patterns.md` | New AP-N entry in standard format |
| instruction | `agents/{pipeline}/{N}-{stage}.md` | Clarification or new anti-pattern rule in a stage file |
| sanity-check | `agents/{pipeline}/domain-config.md` § Sanity Checks | New check row with severity |
| knowledge | `knowledge.md` | New institutional knowledge entry |
| codespec | `codespecs/*.md` | Amendment to a shared pattern |
| inspection-override | `agents/{pipeline}/domain-config.md` § Inspection Overrides | New domain-specific inspection check |
