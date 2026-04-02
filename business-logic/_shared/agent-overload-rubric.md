# Agent Overload Rubric

Referenced during Phase 1 (Business Logic Planning) of any request that proposes extending an existing agent pipeline. The goal: prevent growth from creating monolithic agents.

---

## Split Signals

**Rule: Any 2 of these signals = the agent should be split into a new pipeline.**

| # | Signal | Threshold | How to Check |
|---|--------|-----------|--------------|
| 1 | **Distinct data flows** | Agent pulls from 3+ unrelated data sources that don't share a prep path | List every source the agent reads. If 3+ have different schemas/prep logic, it triggers. |
| 2 | **Branching workflows** | Agent definition has more than 2 "if analysis type is X, do Y" branches | Count conditional branches in the agent's `.md` file that switch behavior by analysis type. |
| 3 | **Business logic sprawl** | Agent references more than 4 business logic docs | Count the `business-logic/*.md` files the agent's instructions tell it to read. |
| 4 | **Skill count** | Agent invokes more than 5 distinct skills in a single run | Count the skills listed in the agent's execution steps. |
| 5 | **Cognitive load** | You can't describe what the agent does in one sentence without using "and" | Write a one-sentence description. If it requires "and" to cover the agent's responsibilities, it triggers. |

---

## How to Use This Rubric

### During Planning (Phase 1)

When a request proposes extending an existing agent:

1. List the current signal state for the agent (which signals are already at threshold)
2. Project what the extension would change (new data sources, new branches, new business logic docs, new skills)
3. Count how many signals would be at or over threshold after the extension
4. Document this as an **Overload Check** section in the plan doc

### Decision

- **0-1 signals triggered:** Extend the existing agent. Proceed normally.
- **2+ signals triggered:** Propose a new pipeline instead. Explain which signals triggered and why a split is the better path.

### Example Overload Check

```markdown
## Overload Check: Extending Sales Analytics with Forecast Accuracy

| Signal | Current | After Extension | Triggered? |
|--------|---------|-----------------|------------|
| Distinct data flows | 1 (Opportunity tab) | 2 (+ Forecast Accuracy tab) | No |
| Branching workflows | 0 | 1 (forecast vs standard analysis) | No |
| Business logic sprawl | 4 (metrics, data-dict, prep-rules, formula-rules) | 6 (+ forecast-metrics, forecast-prep-rules) | Yes |
| Skill count | 4 | 5 | No |
| Cognitive load | "Analyzes sales pipeline data" | "Analyzes sales pipeline data and forecast accuracy" | Yes |

**Result:** 2 signals triggered (business logic sprawl, cognitive load). Consider splitting into a new pipeline.

**Decision:** [Accept/Split] — [reasoning]
```

Note: The rubric is a guideline, not a hard rule. If 2 signals trigger but the extension is genuinely minimal, the team can choose to proceed with extension and document why. The point is to force the conversation.
