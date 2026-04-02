# Session Digest

Structured summary of a completed session, assembled by the CoS before dispatching the retrospective agent. This is the sole input to `agent-improvement`.

---

## Required Fields

| Field | Source | Example |
|-------|--------|---------|
| Original Request | User's initial prompt | "Build a Q2 pipeline analysis by segment" |
| Pipeline | pipeline-registry match (or "adhoc") | sales-analytics |
| Complexity Tier | scoping-steps.md classification (or "adhoc") | Standard |
| Plan Doc | Final state after all stages (full content) | *(inline)* |
| Final Status | Delivered / Partial / Failed | Delivered |

## Stage Dispatch Log

One row per stage that was dispatched. Dispatch Count >1 means a re-dispatch occurred.

| Stage | Dispatch Count | RESULT Status | Issues (hard-fail / warning / info) |
|-------|---------------|---------------|--------------------------------------|
| planner | 1 | PASS | 0 / 0 / 0 |
| data-prep | 2 | PASS | 0 / 1 / 0 |
| analysis | 1 | PASS | 0 / 0 / 1 |
| review | 1 | PASS with warnings | 0 / 2 / 0 |

For ad-hoc sessions, this table has a single row: `adhoc-review | {count} | {status} | {issues}`.

## Escalations

Events where the CoS could not resolve an issue without user intervention.

| Event | Stage | Description | Resolution |
|-------|-------|-------------|------------|
| *(empty if none)* | | | |

## User Corrections

Instances where the user corrected agent output or approach during the session.

| Event | Context | What User Said | What Was Changed |
|-------|---------|---------------|-----------------|
| *(empty if none)* | | | |

---

## Assembly Instructions

The CoS assembles this digest from information it already holds:

1. **Original Request** — first user message
2. **Pipeline + Tier** — from request routing classification
3. **Plan Doc** — current plan doc state (already maintained through stages)
4. **Stage Dispatch Log** — track dispatch count per stage (increment on re-dispatch), copy RESULT status and issues from each stage's output contract
5. **Escalations** — log when CoS escalates to user (stage, description, user's resolution)
6. **User Corrections** — log when user says "that's wrong", "no, use X", or otherwise corrects output
7. **Final Status** — Delivered (all stages PASS), Partial (some stages incomplete), Failed (abandoned)

---

## Session Briefing Derivation

After assembling the Session Digest, the CoS dispatches the briefings agent with operation mode `ingest-session` and the digest content. The briefings agent maps digest fields to session briefing format:

| Digest Field | Briefing Section |
|-------------|-----------------|
| Original Request + Final Status | `session:` frontmatter field |
| Plan Doc (key outcomes only) | ## Outcomes |
| Escalations | ## Decisions |
| User Corrections | ## User Corrections |
| KB-worthy facts from the session | ## KB Candidates |

### Skip Rules

Do NOT write a session briefing when:
- TODO/BACKLOG CRUD only (no delegation occurred)
- Pure recall query with no new decisions
- Session ended with Final Status = Failed and no User Corrections or Decisions
