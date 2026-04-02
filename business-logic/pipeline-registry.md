# Pipeline Registry

Source of truth for pipeline routing. The CoS reads this file to match user requests to pipelines.

## Registered Pipelines

| Pipeline | Directory | Trigger Keywords | Default Source | Stage Count |
|----------|-----------|-----------------|----------------|-------------|
| sales-analytics | `agents/pipelines/sales-analytics/` | sales, pipeline, bookings, forecast, win rate, deal, quota, rep performance, segment, conversion | Daily Data (Opportunity) | 4 |
| marketing-analytics | `agents/pipelines/marketing-analytics/` | campaign, lead gen, MQL, SQL, SAL, marketing funnel, cost per lead, sort score, campaign performance | Marketing Campaign Data | 4 |
| modeling | `agents/pipelines/modeling/` | forecast model, scoring, conversion model, propensity, regression, pipeline scoring, predicted close date | model-specific | 4 |
| adhoc-analysis | `agents/pipelines/adhoc-analysis/` | ad-hoc review, sanity check, pre-flight, check my work, quick question, one-off | in-chat work product | 2 |
| customer-success-analytics | `agents/pipelines/customer-success-analytics/` | retention, churn, GDR, NDR, customer success, account health, CSQL, expansion, contraction, renewal, CS analytics, customer health | CS Data (Opportunity, Account, Subskribe Order Line) | 4 |
| briefings | `agents/operations/briefings/` | process meeting, transcript, briefing, what did we decide, recall, promote to KB, check for transcripts, knowledgebase | Drive transcripts, briefings/ | 1 |
| domain-builder | `agents/meta/domain-builder/` | new pipeline, scaffold, domain builder, add pipeline, validate pipeline | N/A (meta-agent) | 1 |
| agent-improvement | `agents/meta/agent-improvement/` | retrospective, improve agents, session review, what went wrong | session context | 1 |

## How to Add a Pipeline

Use the domain builder agent (`agents/meta/domain-builder/`). It runs an interactive Q&A flow to collect domain info, then scaffolds all pipeline files and updates this registry automatically.

Manual addition: add a row to the table above, create the pipeline directory per `agents/meta/domain-builder/domain-config-schema.md`, and update `CLAUDE.md` Agents Index.
