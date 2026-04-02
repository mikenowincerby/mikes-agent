# Plan Doc Format

Standard plan doc template structure used by all pipeline planners. The plan doc is the single source of truth passed between pipeline stages.

## Template

```markdown
# {Pipeline} Analytics Plan
## Request: [user's original ask]
## Scope
### Core Analysis: [metrics x dimensions x time range]
### Approved Follow-Ups:
1. [metric x dimension x time] -- [reason]
2. [metric x dimension x time] -- [reason]
3. ...
### Source: [data source(s)]
### Output: [expected tabs and outputs]
## Approach Validation: [PASSED -- all items checked]
## Sheet: [TBD -- Agent 2 fills this]
## Column Map: [TBD -- Agent 2 fills this]
## Data Quality: [TBD -- Agent 2 fills this]
## Analysis Complete: [TBD -- Agent 3 fills this]
## Review: [TBD -- Agent 4 fills this]
```

## Conventions

- Plan doc path: `.context/{pipeline-name}-plan.md`
- Each agent fills its own sections and leaves downstream sections as TBD
- Agent 2 adds: Sheet ID + URL, Column Map (header -> column letter), Data Quality summary
- Agent 3 adds: Analysis Complete (tabs built, metrics, formula errors fixed)
- Agent 4 adds: Review (sanity check results, issues, user responses)
