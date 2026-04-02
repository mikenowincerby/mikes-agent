# Briefings & Knowledge

## Overview

Two systems managed by the **briefings agent** (dispatched by the CoS, not executed inline). **Briefings** capture structured extracts from meetings and other events — decisions, action items, key numbers, strategy shifts. They are ephemeral (4-week retention). **Knowledge** (`knowledge.md` at the project root) stores validated permanent institutional knowledge. The system is source-agnostic: the `source_type` frontmatter field supports meetings, Slack, email, and manual entries.

**Agent:** `agents/operations/briefings/` · **Dispatch file:** `.claude/agents/briefings.md`

Topic-based compaction (grouping briefings by topic instead of by meeting) is deferred until file volume demonstrates the need.

## Definitions

| System | Location | Retention | Update Cadence | Git Tracked | Approval Required |
|--------|----------|-----------|----------------|-------------|-------------------|
| Briefings | `briefings/recent/` | 4 weeks, then archived | Per event (user-triggered) | No (gitignored — sensitive content) | No |
| Knowledge | `knowledge.md` (project root) | Permanent | During ingestion or on request | Yes | Yes — explicit user approval |

## Source

**Primary:** Meeting transcripts from Otter/Fireflies stored in Google Drive:
`https://drive.google.com/drive/folders/1ZQ5iCAglMjcQrCJmP5OcejQ0qY2B5GYb`

The architecture supports any source via the `source_type` frontmatter field. No active adapters exist yet for Slack or email — but the file format and ingestion protocol are source-agnostic.

## Ingestion

### Trigger Phrases

- `process meeting` / `process transcript` / `process context`
- User provides a transcript link or filename from the Drive folder

### Steps

1. User provides transcript link or filename
2. CoS dispatches briefings agent with operation type `ingest` and the transcript source
3. Briefings agent reads transcript via `gws drive` commands
4. Agent extracts structured summary into `briefings/recent/YYYY-MM-DD-{slug}.md`
5. Agent updates `briefings/briefings.md` index with one-line description
6. Agent surfaces KB candidates in RESULT
7. CoS presents KB candidates to user for approval

### Extraction Categories

- **Decisions** — what was decided and by whom
- **Action Items** — owner, deadline, description
- **Key Numbers** — with context (what they measure, direction, comparison)
- **Strategy/Priority Shifts** — what changed and why

### File Naming

`YYYY-MM-DD-{slug}.md` where slug is a lowercase-hyphenated meeting identifier.

### Frontmatter Schema

```yaml
date: 2026-03-24
meeting: Pipeline Review
attendees: [Nish, Sarah, Mike]
source_type: meeting  # meeting | slack | email | manual | session
expires: 2026-04-21   # date + 4 weeks
```

### Example

```markdown
---
date: 2026-03-24
meeting: Pipeline Review
attendees: [Nish, Sarah, Mike]
source_type: meeting
expires: 2026-04-21
---
## Decisions
- Pushing healthcare deals to Q3; not ready for Q2 close

## Action Items
- [ ] Sarah: Update forecast model by Friday 2026-03-27
- [ ] Mike: Pull churn data for QBR prep

## Key Numbers
- Q2 pipeline at $2.1M (down from $2.4M last week)
- 3 deals slipped from March to April

## Strategy/Priority Shifts
- Focus shifting from new logo to expansion for rest of Q2
```

## Session Briefing Format

Session briefings capture outcomes from CoS-orchestrated work sessions or context from `.context/attachments/`. Written by the briefings agent during its autonomous context scan.

### Frontmatter

```yaml
date: 2026-03-28
session: "Renamed TODO.md to BACKLOG.md"
source_type: session
expires: 2026-04-25
```

Note: `session` field replaces `meeting` + `attendees` fields.

### Extraction Categories

- **Outcomes** — what was produced, changed, or delivered (session-specific, replaces Action Items / Key Numbers)
- **Decisions** — choices made during the session
- **User Corrections** — corrections to agent output (feeds retrospective and future context)
- **KB Candidates** — facts worth promoting to `knowledge.md`

### Naming Convention

`YYYY-MM-DD-session-{slug}.md` — the `session-` prefix distinguishes from meeting briefings in the filesystem.

## Compaction — DEFERRED

Weekly compaction would group recent briefings by topic (not by meeting) into summary files. This will be activated when:

- Briefing file count exceeds 20, OR
- User reports that searching briefings is slow or noisy

Until then, recent briefings serve as the primary context source.

## Knowledge Promotion

### What Belongs in Knowledge

- Business rules ("we don't discount below 20%")
- Org structure / ownership ("Sarah owns the forecast model")
- Strategic decisions ("entering healthcare vertical in Q3")
- Process definitions ("QBRs happen first week of quarter")
- Data model facts ("ARR includes expansion but not services")

### What Does NOT Belong

- Ephemeral numbers (this week's pipeline total)
- In-progress action items
- Anything that changes week to week

### Approval

Every addition to `knowledge.md` requires explicit user approval. CoS surfaces candidates during ingestion: "I'd like to add these to the knowledgebase: [list]. Approve/reject each?"

User can also manually promote anytime: "add X to the knowledgebase" / "promote to KB".

### Growth Cap

Target: **300 lines** for `knowledge.md`. When approaching the cap, CoS suggests pruning: consolidating related entries, removing stale items, or archiving superseded knowledge.

## Briefing Index Protocol

`briefings/briefings.md` is the lightweight index. Updated on every ingestion.

**One-line descriptions are the primary search index.** They must be high quality — include the key topics, decisions, or numbers so CoS can match against request keywords without reading every file.

Format:
```markdown
## Last 14 Days
- [2026-03-24-pipeline-review](recent/2026-03-24-pipeline-review.md) — Q2 pipeline drop, expansion pivot, healthcare deferred
```

## Usage Patterns

### Cold Start (every conversation)

1. CoS reads `briefings/briefings.md` — see what briefings are available
2. CoS reads `knowledge.md` — permanent KB
3. CoS scans briefing descriptions — only reads full content if topic matches current request
4. CoS dispatches briefings agent in background — the agent manages its own context sources (Drive, `.context/attachments/`, etc.) per `codespecs/agent-context.md`

### Proactive Surfacing During Planning

When CoS plans a pipeline or analysis:
1. Match request keywords against briefings.md one-line descriptions
2. Read matching files for relevant detail
3. Include relevant context in the planner's dispatch prompt as a "Relevant Meeting Context" section

### On-Demand Recall

When user asks "what did we decide about X?":
1. Search KB first (most authoritative)
2. Then search recent briefings (index + local files)
3. If index matches exist but local files are missing, fall back to Drive transcripts (search by date + keywords from index entry)
4. Return answer with source attribution

### Auto-Detection (background briefings agent on every request)

At cold start, CoS dispatches the briefings agent in background (via Agent tool with `run_in_background: true`) to check the Drive transcript folder for **new** transcripts and auto-ingest them:
1. Agent reads `last_ingestion` timestamp from `briefings/active-work.md` (operational state, gitignored)
2. Agent runs `gws drive files list` against the transcript folder, filtered to files created **after** `last_ingestion`
3. If new files found, agent processes each transcript per § Ingestion steps
4. After successful ingestion, agent updates `last_ingestion` in `active-work.md` to the current timestamp
5. Agent returns RESULT with summary (e.g., "Processed 2 new transcripts: pipeline-review, qbr-prep")

Delta-based: one timestamp comparison instead of matching every file. The user can also trigger manually: "check for new transcripts" / "any new meetings?"

**TODO:** Move to scheduled/cron-based detection so new transcripts are discovered even without a conversation.
**TODO:** Onboarding flow for new users should ask which features they want enabled (e.g., auto-detection, KB prompts, proactive surfacing).

## Expiry Rules

- **Recent briefings:** Archive after 4 weeks (move to `briefings/archive/`, remove from briefings.md index)
- **Archive:** Gitignored, kept locally for reference only
- **Knowledge:** Permanent until explicitly updated or removed

## Duplicate Prevention

Before ingesting a new transcript:
1. Check briefings.md for existing entry with same date + slug
2. If found, skip silently (existing extract is already indexed)
3. Never silently create duplicate entries for the same source

For session briefings: check for existing entry with same date + `session-` prefix + similar slug. If the same source file has already been ingested, skip it.

## Index Reconciliation

When reading briefings.md entries during cold start or recall:
1. Verify referenced files actually exist (briefing files are local-only, may be lost)
2. If local file is missing: keep the index entry (serves as Drive search key for recall fallback). Only remove entries older than 8 weeks.
3. Flag orphaned files in `briefings/recent/` that aren't in the index
