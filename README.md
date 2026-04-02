# Monterrey

**An AI-powered Chief of Staff for revenue operations.** Monterrey takes natural-language questions from ops leaders and autonomously produces fully auditable Google Sheets analyses — complete with formulas, lookups, definitions, and sanity checks.

It's not a chatbot that spits out numbers. It's an autonomous analyst that builds deliverables — the same spreadsheets a senior RevOps analyst would build, with the same rigor, in minutes instead of days.

## What it does

Ask a question like *"How did pipeline creation look last quarter by segment?"* and Monterrey builds a Google Sheet with:

- **Raw Data** pulled from Salesforce (via daily snapshot sheets)
- **Prepared Data** with helper columns (stage progression flags, sales cycle days, fiscal periods)
- **Lookups** with editable mappings (segments, stages, fiscal calendar)
- **Summary** with KPI headlines and dimensional breakdowns
- **Deal Lists** with FILTER/SORT formulas (not static data dumps)
- **Definitions** documenting every metric, data source, and assumption

Every cell has a formula. Click any number and see exactly how it was derived.

## Use cases

| Domain | Example questions | Pipeline |
|--------|------------------|----------|
| **Sales Analytics** | Win rate by segment? Rep performance for Q1? Pipeline creation last quarter? | 4-stage |
| **Marketing Analytics** | Campaign performance? MQL to SQL conversion? Cost per lead by campaign? | 4-stage |
| **Customer Success** | What's our GDR/NDR? Churn analysis? CSQL pipeline? Renewal cohorts? | 4-stage |
| **Modeling** | Build a forecast model. Conversion model. Pipeline scoring. | 4-stage |
| **Ad-Hoc** | What was our average deal size last month? | 2-stage (analyst + review) |
| **Briefings** | Process this transcript. What did we decide about X? | Delegated |
| **Domain Builder** | Create a new pipeline for [domain]. | Interactive Q&A |

## What makes it different

1. **Institutional knowledge as code.** 30+ anti-patterns, metric definitions, stage progression semantics, and fiscal calendar rules — encoded as markdown files that agents reference at runtime. This is the knowledge that lives in a senior analyst's head.

2. **Formula-first architecture.** Every output cell has a Google Sheets formula traceable to source data. No static values. Full auditability.

3. **Self-validating.** Every pipeline has a review stage that checks for formula errors, cross-tab consistency, and domain-specific sanity checks before delivering.

4. **Self-extending.** The domain builder scaffolds new analytics domains via interactive Q&A in ~30 minutes. Adding Finance or Product analytics doesn't require rearchitecting.

## Architecture

Monterrey is 97 markdown files (no application code). The AI agent (Claude Code) reads these files as instructions and executes them.

```
CLAUDE.md (thin orchestrator — classify, delegate, inspect, report)
  ├── agents/
  │   ├── pipelines/            — multi-stage analytics workflows
  │   ├── operations/           — operational agents (briefings)
  │   └── meta/                 — system agents (domain-builder, agent-improvement)
  ├── codespecs/                — shared patterns (12 files)
  ├── business-logic/{domain}/  — metrics, data dictionaries, anti-patterns
  ├── skills/                   — reusable capabilities (ingest, formulas, formatting)
  └── Google Sheets             — output medium
```

**Orchestration:** The CoS classifies every request against a task taxonomy, then delegates to the appropriate agent. It almost never executes work itself — only TODO.md CRUD is inline. CLASSIFY → DELEGATE → INSPECT → REPORT.

See [docs/architecture.md](docs/architecture.md) for the full framework overview.

## Getting started

### Prerequisites

- [Claude Code](https://claude.ai/claude-code) installed
- Google Workspace account with Sheets and Drive access
- `gws` CLI authenticated (`gws auth login -s sheets,drive`)
- Data source accessible as Google Sheets or CSV

### Quick start

1. Clone this repo
2. Copy `config/resources.example.yaml` to `config/resources.yaml` and fill in your Google resource IDs
3. Run `./bootstrap.sh` to install tools and authenticate
4. Ask a question: *"How did pipeline creation look last quarter?"*

### Building a new domain

See [docs/how-to-build-a-domain.md](docs/how-to-build-a-domain.md) for a step-by-step guide.

### Browsing metrics

See [docs/metrics-explorer.md](docs/metrics-explorer.md) for a complete catalog of all defined metrics across Sales, Marketing, and Customer Success.

## Current state

- **6 active pipelines** (Sales, Marketing, CS, Modeling, Ad-Hoc, Briefings) + 2 meta-agents (Domain Builder, Agent Improvement)
- **30+ encoded anti-patterns** across domains
- **12 codespecs** (shared patterns) and **7 skills** (reusable capabilities)
- **Claude Code** is the only tested runtime — the dispatch interface is designed for portability but unvalidated on other runtimes
- **Google Sheets** is the output medium — formula-first auditability requires Sheets cell references

## Known limitations

- **Claude Code only.** The dispatch mechanism (`.claude/agents/*.md`) is Claude Code-specific. See [docs/architecture.md](docs/architecture.md) for the dispatch interface contract.
- **Google Workspace required.** Output is Google Sheets. Input data must be accessible as Sheets or CSV.
- **Salesforce-centric reference pipelines.** The 5 built-in pipelines use Salesforce data via daily snapshot sheets. Other data sources work through ingest adapters (sheets, csv).
- **No automated tests.** Pipeline behavior is validated by the review stage at runtime, not by a test suite.
- **Configuration not centralized.** Google resource IDs are currently hardcoded across multiple files. See `config/resources.example.yaml` for the complete inventory.

## License

TBD — see [design doc](docs/architecture.md#open-questions) for licensing considerations.
