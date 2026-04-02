# Output Contract

Standard result format returned by all pipeline subagents to the CoS. End your response with this structured block.

## Variants

### Data-Prep Variant

```
## RESULT
### Status: {PASS | FAIL | PARTIAL}
### Outputs
- Sheet ID: {id}
- Tabs created: {list}
- Row count: {n}
- Column map: {key columns with letters, e.g. A=Opp Name, B=Amount}
```

### Analysis Variant

```
## RESULT
### Status: {PASS | FAIL | PARTIAL}
### Outputs
- Sheet ID: {id}
- Tabs created/updated: {list}
- Formula count: {n formulas written}
- Formatting applied: {YES | NO}
```

### Review Variant

```
## RESULT
### Status: {PASS | FAIL | PARTIAL | PASS with warnings}
### Outputs
- Sheet ID: {id}
- Tabs verified: {list}
- Sanity checks: {n of m PASSED}
- Definitions tab: {POPULATED | INCOMPLETE | FAILED}
- Hard-fail count: {n}
```

### Retrospective Variant

```
## RESULT
### Status: {PASS | SKIP}
### Signal Summary
| Signal | Count | Details |
|--------|-------|---------|
| Re-dispatches | {n} | {which stages, why} |
| User corrections | {n} | {summary} |
| Escalations | {n} | {summary} |
| Hard-fails caught | {n} | {which checks} |
| Warnings | {n} | {summary} |

### Proposals
| # | Type | Target File | Section | Action |
|---|------|-------------|---------|--------|
| 1 | {anti-pattern/instruction/sanity-check/knowledge/codespec/inspection-override} | {path} | {section} | {add/amend} |

### Justification
#### Proposal 1: {title}
- **Session event**: {what happened}
- **Root cause**: {why}
- **Why this prevents recurrence**: {how the change would have caught or prevented this}
- **Draft text**: {exact text to add or amend}
```

If Status=SKIP, omit Proposals and Justification sections.

## Common Sections (all variants)

Append these after the variant-specific `### Outputs`:

```
### Verification
- Formulas resolve: {YES | NO — count errors}
- Row count matches plan: {YES | NO — expected vs actual}
- Read-back confirmed: {YES | NO}

### Issues
| # | Severity | Description | Fixable |
|---|----------|-------------|---------|
| 1 | {hard-fail/warning/info} | {description} | {yes/no} |

### Plan Doc Updates
- Sections updated: {list}
- New fields added: {list}
```
