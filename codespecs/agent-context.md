# Agent Context Pattern

Defines how agents persist and recall their own cross-session context. The CoS orchestrates; agents remember.

---

## Principle

Agents own their context. Each agent is responsible for persisting what it learns and recalling it when dispatched. The CoS reads indexes and summaries — never full agent state.

## State Directory

`.state/{category}/{agent-name}/`

```
.state/
├── operations/
│   └── briefings/
│       └── state.md
├── pipelines/
│   ├── sales-analytics/
│   │   ├── planner.md
│   │   ├── data-prep.md
│   │   ├── analysis.md
│   │   └── review.md
│   ├── marketing-analytics/
│   ├── customer-success-analytics/
│   ├── modeling/
│   └── adhoc-analysis/
│       ├── analyst.md
│       └── review.md
└── meta/
    ├── agent-improvement/
    │   └── state.md
    └── domain-builder/
        └── state.md
```

State directories are gitignored (operational, not source).

## Agent Cold Start

When dispatched, an agent with a state directory:

1. **Read** its own state file FIRST (before plan doc or dispatch inputs)
2. **Reconcile** with dispatch inputs — state may be stale; dispatch inputs are authoritative for the current session
3. **Proceed** with execution

If the state file doesn't exist yet, skip step 1 — the agent is running for the first time.

## Context Persistence

After completing work, agents write a state update:

- What they learned that's reusable across sessions
- Operational state (timestamps, offsets, pending items)
- Correction history (user corrections to agent output)

State updates are appended or merged — never overwritten wholesale. Each update adds a dated section so context accumulates.

## State File Format

```yaml
---
agent: {agent-name}
updated: YYYY-MM-DD
---
## {Section relevant to agent's domain}
- {Bullet points of cross-session context}

## Last Session ({YYYY-MM-DD})
- {What happened, what was learned}
```

Keep state files concise. Target: **<100 lines**. When approaching the limit, consolidate older entries — keep patterns, drop individual instances.

## What Goes in Agent State

- Domain learnings not derivable from code (data quality issues, calibration)
- Operational state (scan timestamps, pagination offsets, ingested file lists)
- Correction history (user corrections to agent output)
- Recurring patterns (formula failures, sanity check false positives)

## What Does NOT Go in Agent State

- Plan docs (shared artifact in `.context/`)
- Business logic (lives in `business-logic/`)
- Agent instructions (lives in `agents/`)
- Ephemeral session data (lives in `briefings/active-work.md`)
- Anything already in `knowledge.md`

## CoS Contract

- CoS dispatches agents with: stage, pipeline, plan doc, stage inputs, success criteria
- CoS does NOT include agent state in dispatch — agents read their own
- CoS reads agent state indexes/summaries only when needed for planning or review
- Agents return RESULT to CoS as normal — the RESULT is the CoS's view of what happened
